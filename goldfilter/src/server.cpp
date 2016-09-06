#include "server.hpp"
#include "dispatcher.hpp"
#include "include/libplatform/libplatform.h"
#include "include/v8.h"
#include "msgpack_server.hpp"
#include "packet.hpp"
#include "pcap.hpp"
#include "pcap_dummy.hpp"
#include "script_class.hpp"
#include "status.hpp"
#include <chrono>
#include <condition_variable>
#include <iostream>
#include <spdlog/sinks/sink.h>
#include <spdlog/spdlog.h>
#include <thread>
#include <v8pp/module.hpp>

namespace console
{

void log(v8::FunctionCallbackInfo<v8::Value> const &args)
{
    v8::HandleScope handle_scope(args.GetIsolate());

    for (int i = 0; i < args.Length(); ++i) {
        if (i > 0)
            std::cout << ' ';
        v8::String::Utf8Value str(args[i]);
        std::cout << *str;
    }
    std::cout << std::endl;
}

v8::Handle<v8::Value> init(v8::Isolate *isolate)
{
    v8pp::module m(isolate);
    m.set("log", &log);
    return m.new_instance();
}

} // namespace console

struct Log {
    spdlog::level::level_enum level;
    spdlog::log_clock::time_point time;
    std::string message;
};
typedef std::shared_ptr<Log> LogPtr;

MSGPACK_ADD_ENUM(spdlog::level::level_enum);

namespace msgpack
{
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
{
    namespace adaptor
    {

    template <>
    struct pack<LogPtr> {
        template <typename Stream>
        msgpack::packer<Stream> &operator()(msgpack::packer<Stream> &o, LogPtr const &v) const
        {
            o.pack_map(3);
            o.pack("level");
            o.pack(v->level);
            o.pack("time");
            o.pack(std::chrono::system_clock::to_time_t(v->time));
            o.pack("message");
            o.pack(v->message);
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

class Server::Private
{
  public:
    Private(const std::string &sock, const std::string &tmp);
    ~Private();
    bool capturing;
    Status status;
    MsgpackServer server;
    std::unique_ptr<Dispatcher> dispatcher;
    std::unique_ptr<PcapInterface> pcap;
    v8::Platform *platform;

    std::mutex logMutex;
    std::array<LogPtr, 128> logBuffer;
    size_t logBufferIndex = 0;

    std::mutex pingMutex;
    std::condition_variable pingCond;
    std::thread pingThread;
    bool pingReceived;
    bool pingQuit;
};

Server::Private::Private(const std::string &sock, const std::string &tmp)
    : capturing(false), server(sock), pingReceived(false), pingQuit(false)
{
    dispatcher.reset(new Dispatcher(tmp));

    pingThread = std::thread([this]() {
        while (true) {
            using namespace std::chrono;
            steady_clock::time_point tp = steady_clock::now() + seconds(30);
            std::unique_lock<std::mutex> lock(pingMutex);
            if (pingCond.wait_until(lock, tp) == std::cv_status::timeout) {
                if (pingReceived) {
                    pingReceived = false;
                } else {
                    server.stop();
                    return;
                }
            } else if (pingQuit) {
                return;
            }
        }
    });
}

Server::Private::~Private()
{
    {
        std::lock_guard<std::mutex> lock(pingMutex);
        pingQuit = true;
    }
    pingCond.notify_all();
    if (pingThread.joinable()) {
        pingThread.join();
    }
}

class Server::LoggerSink : public spdlog::sinks::sink
{
  public:
    LoggerSink(Server::Private *parent);
    ~LoggerSink();
    void log(const spdlog::details::log_msg &msg) override;
    void flush() override;

  private:
    Server::Private *d;
};

Server::LoggerSink::LoggerSink(Server::Private *parent)
    : d(parent)
{
}

Server::LoggerSink::~LoggerSink()
{
}

void Server::LoggerSink::log(const spdlog::details::log_msg &msg)
{
    std::lock_guard<std::mutex> lock(d->logMutex);
    auto log = std::make_shared<Log>();
    log->time = msg.time;
    log->level = msg.level;
    log->message = msg.raw.str();
    d->logBuffer[d->logBufferIndex] = log;
    d->logBufferIndex = (d->logBufferIndex + 1) % d->logBuffer.size();
}

void Server::LoggerSink::flush()
{
}

Server::Server(const std::string &sock, const std::string &tmp)
    : d(new Private(sock, tmp))
{
    // Initialize V8.
    v8::V8::InitializeICU();
    v8::V8::InitializeExternalStartupData("");
    d->platform = v8::platform::CreateDefaultPlatform();
    v8::V8::InitializePlatform(d->platform);
    v8::V8::Initialize();

    spdlog::create("server", {std::make_shared<LoggerSink>(d)});

    d->pcap.reset(new Pcap());

    d->server.handle("exit", [this](const msgpack::object &arg, ReplyInterface &reply) {
        reply(std::string("bye"));
        d->server.stop();
    });

    d->server.handle("start", [this](const msgpack::object &arg, ReplyInterface &reply) {
        d->capturing = d->pcap->start();
        reply();
    });

    d->server.handle("stop", [this](const msgpack::object &arg, ReplyInterface &reply) {
        d->pcap->stop();
        d->capturing = false;
        reply();
    });

    d->server.handle("ping", [this](const msgpack::object &arg, ReplyInterface &reply) {
        {
            std::lock_guard<std::mutex> lock(d->pingMutex);
            d->pingReceived = true;
        }
        reply();
    });

    d->server.handle("set_opt", [this](const msgpack::object &arg, ReplyInterface &reply) {
        const auto &map = arg.as<std::unordered_map<std::string, msgpack::object>>();

        {
            const auto &it = map.find("interface");
            if (it != map.end()) {
                d->pcap->setInterface(it->second.as<std::string>());
            }
        }

        {
            const auto &it = map.find("promiscuous");
            if (it != map.end()) {
                d->pcap->setPromiscuous(it->second.as<bool>());
            }
        }

        {
            const auto &it = map.find("snaplen");
            if (it != map.end()) {
                d->pcap->setSnaplen(it->second.as<int>());
            }
        }

        std::unordered_map<std::string, std::string> result;
        {
            const auto &it = map.find("filter");
            if (it != map.end()) {
                std::string error;
                if (!d->pcap->setBPF(it->second.as<std::string>(), &error)) {
                    result["error"] = error;
                }
            }
        }

        reply(result);
    });

    d->server.handle("set_filter", [this](const msgpack::object &arg, ReplyInterface &reply) {
        const auto &map = arg.as<std::unordered_map<std::string, msgpack::object>>();

        std::unordered_map<std::string, std::string> result;
        const auto &source = map.find("source");
        const auto &name = map.find("name");
        const auto &options = map.find("options");
        d->dispatcher->setFilter(name->second.as<std::string>(), source->second.as<std::string>(), options->second);
        reply(result);
    });

    d->server.handle("load_dissector", [this](const msgpack::object &arg, ReplyInterface &reply) {
        const auto &map = arg.as<std::unordered_map<std::string, msgpack::object>>();
        std::unordered_map<std::string, std::string> result;
        const auto &source = map.find("source");
        const auto &options = map.find("options");

        if (source != map.end()) {
            std::string error;
            if (!d->dispatcher->loadDissector(source->second.as<std::string>(), options->second, &error)) {
                result["error"] = error;
            }
        } else {
            result["error"] = "module path not specified";
        }

        reply(result);
    });

    d->server.handle("load_stream_dissector", [this](const msgpack::object &arg, ReplyInterface &reply) {
        const auto &map = arg.as<std::unordered_map<std::string, msgpack::object>>();
        std::unordered_map<std::string, std::string> result;
        const auto &source = map.find("source");
        const auto &options = map.find("options");

        if (source != map.end()) {
            std::string error;
            if (!d->dispatcher->loadStreamDissector(source->second.as<std::string>(), options->second, &error)) {
                result["error"] = error;
            }
        } else {
            result["error"] = "module path not specified";
        }

        reply(result);
    });

    d->server.handle("load_module", [this](const msgpack::object &arg, ReplyInterface &reply) {
        const auto &map = arg.as<std::unordered_map<std::string, msgpack::object>>();
        std::unordered_map<std::string, std::string> result;
        const auto &name = map.find("name");
        const auto &source = map.find("source");

        if (name != map.end() && source != map.end()) {
            std::string error;
            if (!d->dispatcher->loadModule(name->second.as<std::string>(), source->second.as<std::string>(), &error)) {
                result["error"] = error;
            }
        } else {
            result["error"] = "module path not specified";
        }

        reply(result);
    });

    d->server.handle("get_status", [this](const msgpack::object &arg, ReplyInterface &reply) {
        Status stat;
        stat.capturing = d->capturing;
        stat.queuedPackets = d->dispatcher->queuedSize();
        stat.packets = d->dispatcher->size();
        stat.droppedPackets = d->dispatcher->dropped();
        stat.filtered = d->dispatcher->filtered();
        if (stat != d->status) {
            d->status = stat;
            reply(d->status);
        } else {
            reply();
        }
    });

    d->server.handle("read_stream", [this](const msgpack::object &arg, ReplyInterface &reply) {
        const auto &map = arg.as<std::unordered_map<std::string, msgpack::object>>();
        const auto &id = map.find("id");
        const auto &index = map.find("index");
        if (id != map.end() && index != map.end()) {
            const auto &data = d->dispatcher->readStream(id->second.as<std::string>(),
                                                         index->second.as<uint64_t>());
            if (!data.empty()) {
                reply(data);
                return;
            }
        }
        reply();
    });

    d->server.handle("stream_length", [this](const msgpack::object &arg, ReplyInterface &reply) {
        reply(d->dispatcher->streamLength(arg.as<std::string>()));
    });

    d->server.handle("get_packets", [this](const msgpack::object &arg, ReplyInterface &reply) {
        const auto &map = arg.as<std::unordered_map<std::string, msgpack::object>>();
        const auto &l = map.find("list");
        const auto &r = map.find("range");
        if (l != map.end()) {
            const auto &list = l->second.as<std::vector<uint64_t>>();
            const PacketList &packets = d->dispatcher->get(list);
            reply(packets);
        } else if (r != map.end()) {
            const auto &range = r->second.as<std::pair<uint64_t, uint64_t>>();
            const PacketList &packets = d->dispatcher->get(range.first, range.second);
            reply(packets);
        } else {
            reply(PacketList());
        }
    });

    d->server.handle("get_filtered", [this](const msgpack::object &arg, ReplyInterface &reply) {
        const auto &map = arg.as<std::unordered_map<std::string, msgpack::object>>();
        const auto &name = map.find("name");
        const auto &range = map.find("range");
        if (name != map.end() && range != map.end()) {
            const auto &pair = range->second.as<std::pair<uint64_t, uint64_t>>();
            const auto &packets = d->dispatcher->getFiltered(name->second.as<std::string>(), pair.first, pair.second);
            reply(packets);
        } else {
            reply(PacketList());
        }
    });

    d->server.handle("get_devices", [this](const msgpack::object &arg, ReplyInterface &reply) {
        reply(d->pcap->getAllDevs());
    });

    d->server.handle("set_testdata", [this](const msgpack::object &arg, ReplyInterface &reply) {
        d->pcap.reset(new PcapDummy(arg));
        d->pcap->handle([this](const PacketPtr &p) {
            d->dispatcher->insert(p);
        });
        reply();
    });

    d->server.handle("fetch_logs", [this](const msgpack::object &arg, ReplyInterface &reply) {
        std::vector<LogPtr> logs;
        {
            std::lock_guard<std::mutex> lock(d->logMutex);
            for (size_t i = 0; i < d->logBuffer.size(); ++i) {
                size_t index = (d->logBufferIndex + i) % d->logBuffer.size();
                const LogPtr &log = d->logBuffer[index];
                if (log) {
                    logs.push_back(log);
                    d->logBuffer[index].reset();
                }
            }
        }
        reply(logs);
    });

    // pcap thread
    d->pcap->handle([this](const PacketPtr &p) {
        d->dispatcher->insert(p);
    });
}

Server::~Server()
{
    spdlog::drop("server");
    v8::Platform *platform = d->platform;
    delete d;
    v8::V8::Dispose();
    v8::V8::ShutdownPlatform();
    delete platform;
}

bool Server::start()
{
    bool result = d->server.start();
    d->pcap->stop();
    return result;
}
