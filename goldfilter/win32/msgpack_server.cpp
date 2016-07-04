#include "msgpack_server.hpp"
#include <msgpack.hpp>

typedef long ssize_t;

typedef std::basic_string<TCHAR> tstring;

inline void operator<<(tstring &t, const std::string &s)
{
#ifdef _UNICODE
    if (s.size() > 0) {
        t.resize(s.size() + 1);
        size_t length = 0;
        mbstowcs_s(&length, &t[0], t.size(), s.c_str(), _TRUNCATE);
        t.resize(length);
    } else {
        t.clear();
    }
#else
    t = s;
#endif
}

class Reply : public ReplyInterface
{
  public:
    Reply(HANDLE pipe, uint32_t id);
    bool write(const char *data, std::size_t length);
    uint32_t id() const;

  private:
    HANDLE hPipe;
    uint32_t callid;
};

Reply::Reply(HANDLE pipe, uint32_t id)
    : hPipe(pipe),
      callid(id)
{
}

bool Reply::write(const char *data, std::size_t len)
{
    DWORD length = 0;
    WriteFile(hPipe, data, len, &length, NULL);
    return length > 0;
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
    tstring path;
    std::unordered_map<std::string, MsgpackCallback> handlers;
    HANDLE hPipe;
    bool active;
};

MsgpackServer::Private::Private()
    : active(false)
{
}

MsgpackServer::Private::~Private()
{
}

MsgpackServer::MsgpackServer(const std::string &path)
    : d(new Private())
{
    d->path << path;
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
    auto spd = spdlog::get("console");
    size_t const try_read_size = 256;

    d->hPipe =
        CreateNamedPipe(d->path.c_str(), PIPE_ACCESS_DUPLEX, PIPE_TYPE_BYTE, 1,
                        try_read_size, try_read_size, 1000, NULL);
    if (d->hPipe == INVALID_HANDLE_VALUE) {
        spd->error("CreateNamedPipe() failed");
        return false;
    }

    if (!ConnectNamedPipe(d->hPipe, NULL)) {
        spd->error("ConnectNamedPipe() failed");
        return false;
    }

    msgpack::unpacker unp;

    d->active = true;
    while (d->active) {
        unp.reserve_buffer(try_read_size);

        DWORD actual_read_size = 0;
        if (!ReadFile(d->hPipe, unp.buffer(), try_read_size, &actual_read_size,
                      NULL)) {
            spd->error("ReadFile() failed");
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
                    Reply reply(d->hPipe, std::get<1>(tuple));
                    (it->second)(std::get<2>(tuple), reply);
                }
            } catch (const std::bad_cast &err) {
                spd->error("msgpack decoding error: {}", err.what());
            }

            if (!d->active)
                break;
        }
    }

    CloseHandle(d->hPipe);
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
