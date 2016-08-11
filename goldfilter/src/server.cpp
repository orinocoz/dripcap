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
#include <spdlog/spdlog.h>
#include <leveldb/db.h>

#include <iostream>
#include <sstream>

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

class Server::Private
{
  public:
    Private(const std::string &path);
    ~Private();
    bool capturing;
    Status status;
    MsgpackServer server;
    Dispatcher *dispatcher;
    std::unique_ptr<PcapInterface> pcap;
    v8::Platform *platform;
    leveldb::DB *db;
};

Server::Private::Private(const std::string &path)
    : capturing(false), server(path)
{
    leveldb::Options options;
    options.create_if_missing = true;
    leveldb::Status status = leveldb::DB::Open(options, path + ".leveldb", &db);
    if (!status.ok()) {
        spdlog::get("console")->error("{}", status.ToString());
    }
    dispatcher = new Dispatcher(db);
}

Server::Private::~Private()
{
    delete dispatcher;
    delete db;
}

Server::Server(const std::string &path)
    : d(new Private(path))
{
    // Initialize V8.
    v8::V8::InitializeICU();
    v8::V8::InitializeExternalStartupData("");
    d->platform = v8::platform::CreateDefaultPlatform();
    v8::V8::InitializePlatform(d->platform);
    v8::V8::Initialize();

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
        stat.filtered = d->dispatcher->filtered();
        if (stat != d->status) {
            d->status = stat;
            reply(d->status);
        } else {
            reply();
        }
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
        d->pcap->handle([this](Packet *p) {
            d->dispatcher->insert(p);
        });
        reply();
    });

    // pcap thread
    d->pcap->handle([this](Packet *p) {
        d->dispatcher->insert(p);
    });
}

Server::~Server()
{
    v8::V8::Dispose();
    v8::V8::ShutdownPlatform();
    delete d->platform;
}

bool Server::start()
{
    bool result = d->server.start();
    d->pcap->stop();
    return result;
}
