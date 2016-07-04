
#include "msgpack_server.hpp"
#include <msgpack.hpp>
#include <spdlog/spdlog.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>
#include <signal.h>

class Reply : public ReplyInterface
{
  public:
    Reply(int sock, uint32_t id);
    bool write(const char *data, std::size_t length);
    uint32_t id() const;

  private:
    int csock;
    uint32_t callid;
};

Reply::Reply(int sock, uint32_t id)
    : csock(sock),
      callid(id)
{
}

bool Reply::write(const char *data, std::size_t length)
{
    return ::write(csock, data, length) > 0;
}

uint32_t Reply::id() const
{
    return callid;
}

class MsgpackServer::Private
{
  public:
    Private();
    ~Private();

  public:
    std::string path;
    std::unordered_map<std::string, MsgpackCallback> handlers;
    int ssock, csock;
    bool active;
};

MsgpackServer::Private::Private()
    : ssock(0),
      active(false)
{
}

MsgpackServer::Private::~Private()
{
}

MsgpackServer::MsgpackServer(const std::string &path)
    : d(new Private())
{
    d->path = path;
}

MsgpackServer::~MsgpackServer()
{
    delete d;
}

void MsgpackServer::handle(const std::string &command,
                           const MsgpackCallback &func)
{
    if (func) {
        d->handlers[command] = func;
    } else {
        d->handlers.erase(command);
    }
}

bool MsgpackServer::start()
{
    d->active = false;
    struct sigaction sigIntHandler;

    sigIntHandler.sa_handler = [](int sig) {
        auto spd = spdlog::get("console");
        spd->error("SIGINT");
    };
    sigemptyset(&sigIntHandler.sa_mask);
    sigIntHandler.sa_flags = 0;

    sigaction(SIGINT, &sigIntHandler, NULL);

    auto spd = spdlog::get("console");

    if ((d->ssock = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
        spd->error("socket() failed");
        return false;
    }

    struct sockaddr_un addr = {0};
    addr.sun_family = AF_UNIX;
    d->path.copy(addr.sun_path, sizeof(addr.sun_path), 0);

    if (bind(d->ssock, (struct sockaddr *)&addr, sizeof(struct sockaddr_un)) <
        0) {
        close(d->ssock);
        spd->error("bind({}) failed", d->path);
        return false;
    }

    if (chmod(d->path.c_str(), 0666) < 0) {
        spd->error("chmod() failed", d->path);
        return false;
    }

    if (listen(d->ssock, 5) < 0) {
        spd->error("listen() failed", d->path);
        return false;
    }

    d->csock = accept(d->ssock, nullptr, nullptr);
    if (d->csock < 0) {
        spd->error("accept() failed", d->path);
        return false;
    }

    size_t const try_read_size = 256;
    msgpack::unpacker unp;

    d->active = true;
    while (d->active) {
        unp.reserve_buffer(try_read_size);
        ssize_t actual_read_size = read(d->csock, unp.buffer(), try_read_size);
        if (actual_read_size <= 0) {
            spd->error("read() failed");
            break;
        }

        unp.buffer_consumed(actual_read_size);

        msgpack::object_handle result;
        while (unp.next(result)) {
            msgpack::object obj(result.get());
            spd->debug("recv: {}", obj);
            try {
                const auto &tuple = obj.as<std::tuple<std::string, uint32_t, msgpack::object>>();
                const auto &it = d->handlers.find(std::get<0>(tuple));
                if (it != d->handlers.end()) {
                    Reply reply(d->csock, std::get<1>(tuple));
                    (it->second)(std::get<2>(tuple), reply);
                }
            } catch (const std::bad_cast &err) {
                spd->error("msgpack decoding error: {}", err.what());
            }
            if (!d->active)
                break;
        }
    }

    close(d->ssock);
    unlink(d->path.c_str());
    return true;
}

bool MsgpackServer::stop()
{
    if (d->active) {
        d->active = false;
        return true;
    }
    return false;
}
