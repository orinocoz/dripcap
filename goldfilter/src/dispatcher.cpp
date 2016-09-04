#include "dispatcher.hpp"
#include "layer.hpp"
#include "net_stream.hpp"
#include "packet.hpp"
#include "script_class.hpp"
#include "object_cache.hpp"
#include <condition_variable>
#include <mutex>
#include <queue>
#include <spdlog/spdlog.h>
#include <sstream>
#include <thread>
#include <vector>

struct Dispatcher::Stream {
    msgpack::object context;
    bool loaded = false;

    std::vector<ScriptClassPtr> dissectors;
    bool started = false;

    MSGPACK_DEFINE(context, started);
};

class Dispatcher::Private
{
  public:
    static LayerPtr firstLayer(const PacketPtr &pkt, std::unordered_set<std::string> *history);

  public:
    Private(const std::string &path);
    std::queue<PacketPtr> waitingPackets;
    ObjectCache<uint64_t, PacketPtr> packets;
    std::vector<DissectorWorker *> workers;
    std::unordered_map<std::string, std::vector<FilterWorker *>> filterWorkers;
    std::unordered_map<std::string, std::shared_ptr<std::vector<uint64_t>>> filterdPackets;
    std::unordered_map<std::string, std::string> modules;
    std::unordered_map<std::string, std::vector<std::pair<std::string, msgpack::object>>> streamDissectors;

    bool exiting = false;
    uint64_t count = 0;
    uint64_t dropped = 0;
    uint64_t maxID = 0;
    uint64_t streamMaxID = 0;
    std::condition_variable cond;
    std::condition_variable filterCond;
    std::condition_variable streamCond;
    std::mutex mutex;
    std::thread streamThread;
};

Dispatcher::Private::Private(const std::string &path)
    : packets(path)
{
}

LayerPtr Dispatcher::Private::firstLayer(const PacketPtr &pkt, std::unordered_set<std::string> *history)
{
    std::function<LayerPtr(const LayerList &)> find = [pkt, history, &find](const LayerList &layers) -> LayerPtr {
        for (const auto &pair : layers) {
            const std::string &ns = pair.first;
            if (history->count(ns) == 0) {
                history->insert(ns);
                return pair.second;
            }
            LayerPtr child = find(pair.second->layers);
            if (child)
                return child;
        }
        return LayerPtr();
    };

    return find(pkt->layers);
}

struct Dispatcher::FilterContext {
    uint64_t fetchedMaxID = 0;
    uint64_t maxID = 0;
    std::set<uint64_t> set;
    std::set<uint64_t> filtering;
    std::shared_ptr<std::vector<uint64_t>> filtered;
};

class Dispatcher::FilterWorker
{
  public:
    FilterWorker(const std::string &source, const msgpack::object &options, const std::shared_ptr<Dispatcher::FilterContext> &ctx, Dispatcher::Private *parent);
    ~FilterWorker();

  public:
    bool exiting;
    std::shared_ptr<FilterContext> ctx;
    Dispatcher::Private *d;
    std::thread thread;
    msgpack::zone zone;
};

Dispatcher::FilterWorker::FilterWorker(const std::string &source, const msgpack::object &options, const std::shared_ptr<Dispatcher::FilterContext> &ctx, Dispatcher::Private *parent)
    : exiting(false), ctx(ctx), d(parent)
{
    msgpack::object opt = msgpack::object(options, zone);
    thread = std::thread([this, source, opt, ctx]() {

        auto spd = spdlog::get("server");
        ScriptClassPtr script = std::make_shared<ScriptClass>(opt);
        std::string err;

        {
            std::unique_lock<std::mutex> lock(d->mutex);
            for (const auto &pair : d->modules) {
                if (!script->loadModule(pair.first, pair.second, &err)) {
                    spd->error("{}", err);
                }
            }
        }

        if (!script->loadSource(source, &err)) {
            spd->error("{}", err);
            return false;
        }

        while (true) {
            std::unique_lock<std::mutex> lock(d->mutex);
            d->filterCond.wait(lock, [this, ctx] {
                return d->exiting || exiting || d->streamMaxID > ctx->fetchedMaxID;
            });
            if (d->exiting || exiting)
                return false;

            ++ctx->fetchedMaxID;
            ctx->filtering.insert(ctx->fetchedMaxID);
            PacketPtr pkt = d->packets.get(ctx->fetchedMaxID);

            lock.unlock();
            bool match = script->filter(pkt);
            lock.lock();

            if (match) {
                ctx->set.insert(pkt->id);
            }
            ctx->filtering.erase(pkt->id);
            if (ctx->filtering.empty()) {
                ctx->maxID = ctx->fetchedMaxID;
            } else {
                ctx->maxID = *ctx->filtering.begin() - 1;
            }

            auto it = ctx->set.begin();
            for (; it != ctx->set.end() && *it <= ctx->maxID; ++it) {
                ctx->filtered->push_back(*it);
            }
            ctx->set.erase(ctx->set.begin(), it);
        }
    });
}

Dispatcher::FilterWorker::~FilterWorker()
{
    if (thread.joinable())
        thread.join();
}

class Dispatcher::DissectorWorker
{

  public:
    DissectorWorker(Dispatcher::Private *parent);
    ~DissectorWorker();
    bool loadDissector(const std::string &source, const msgpack::object &options, std::string *error);
    bool loadModule(const std::string &name, const std::string &source, std::string *error);

  public:
    Dispatcher::Private *d;
    std::thread thread;
    std::queue<std::pair<std::string, msgpack::object>> sources;
    std::vector<std::pair<std::string, std::string>> modules;
    std::unordered_map<std::string, std::vector<ScriptClassPtr>> dissectors;
    msgpack::zone zone;
};

Dispatcher::DissectorWorker::DissectorWorker(Dispatcher::Private *parent)
    : d(parent)
{
    thread = std::thread([this]() {
        auto spd = spdlog::get("server");
        while (true) {
            std::unique_lock<std::mutex> lock(d->mutex);
            d->cond.wait(lock, [this] {
                return !d->waitingPackets.empty() || !sources.empty() || d->exiting;
            });
            if (d->exiting)
                return false;

            while (!sources.empty()) {
                const auto &pair = sources.front();

                ScriptClassPtr script = std::make_shared<ScriptClass>(pair.second);

                for (const auto &pair : modules) {
                    std::string err;
                    if (!script->loadModule(pair.first, pair.second, &err)) {
                        spd->error("{}", err);
                    }
                }

                if (script->loadSource(pair.first, nullptr)) {
                    const auto &map = pair.second.as<std::unordered_map<std::string, msgpack::object>>();
                    const msgpack::object &array = map.at("namespaces");
                    for (const std::string &ns : array.as<std::vector<std::string>>()) {
                        dissectors[ns].push_back(script);
                    }
                }

                sources.pop();
            }

            while (!d->waitingPackets.empty()) {
                PacketPtr pkt = d->waitingPackets.front();
                d->waitingPackets.pop();
                lock.unlock();

                std::unordered_set<std::string> history;
                LayerPtr parentLayer = d->firstLayer(pkt, &history);
                while (parentLayer) {
                    const auto &it = dissectors.find(parentLayer->ns);
                    if (it != dissectors.end()) {
                        for (const auto &dissector : it->second) {
                            std::string err;
                            if (!dissector->analyze(pkt, parentLayer, &err)) {
                                spd->error("{}", err);
                            }
                        }
                    }
                    parentLayer = d->firstLayer(pkt, &history);
                }

                lock.lock();
                d->packets.set(pkt->id, pkt);

                if (d->maxID == 0) {
                    if (d->packets.has(1)) {
                        d->maxID = 1;
                    } else {
                        continue;
                    }
                }
                while (d->packets.has(d->maxID + 1))
                    d->maxID++;

                d->filterCond.notify_all();
                d->streamCond.notify_all();
            }
        }
    });
}

Dispatcher::DissectorWorker::~DissectorWorker()
{
    if (thread.joinable())
        thread.join();
}

bool Dispatcher::DissectorWorker::loadDissector(const std::string &source, const msgpack::object &options, std::string *error)
{
    {
        std::lock_guard<std::mutex> lock(d->mutex);
        sources.push(std::make_pair(source, msgpack::object(options, zone)));
    }

    d->cond.notify_all();
    return true;
}

bool Dispatcher::DissectorWorker::loadModule(const std::string &name, const std::string &source, std::string *error)
{
    std::lock_guard<std::mutex> lock(d->mutex);
    modules.push_back(std::make_pair(name, source));
    return true;
}

Dispatcher::Dispatcher(const std::string &path)
    : d(new Private(path))
{
    int numcore = std::max(1u, std::thread::hardware_concurrency());
    for (int i = 0; i < numcore; ++i) {
        d->workers.push_back(new DissectorWorker(d));
    }

    d->streamThread = std::thread([this, path]() {
        auto spd = spdlog::get("server");

        uint64_t maxID = 0;
        ObjectCache<std::string, Stream> streamCache(path + "_stream");
        msgpack::zone zone;

        while (true) {
            std::unique_lock<std::mutex> lock(d->mutex);
            d->streamCond.wait(lock, [this, &maxID] {
                return d->maxID > maxID || d->exiting;
            });
            if (d->exiting)
                return false;

            ++maxID;
            PacketPtr pkt = d->packets.get(maxID);

            lock.unlock();

            typedef std::unordered_map<LayerPtr, NetStreamList> StreamList;
            std::function<StreamList(const LayerList &)> findStreams = [&findStreams](const LayerList &layers) {
                StreamList list;
                for (const auto &pair : layers) {
                    list[pair.second] = pair.second->streams;
                    for (const auto &pair2 : findStreams(pair.second->layers)) {
                        list[pair2.first] = pair2.second;
                    }
                }
                return list;
            };

            StreamList streamList = findStreams(pkt->layers);
            while (!streamList.empty()) {
                StreamList list;
                list.swap(streamList);

                for (const auto &pair : list) {
                    for (const NetStreamPtr &net : pair.second) {
                        std::string id = net->ns;
                        id.append(1, '\0');
                        id.append(net->id);
                        Stream stream = streamCache.get(id);
                        if (!stream.loaded) {
                            stream.loaded = true;
                            lock.lock();
                            for (const auto &pair : d->streamDissectors[net->ns]) {
                                std::string err;
                                ScriptClassPtr script = std::make_shared<ScriptClass>(pair.second);
                                if (!script->loadSource(pair.first, &err)) {
                                    spd->error("{}", err);
                                    continue;
                                }
                                for (const auto &pair : d->modules) {
                                    if (!script->loadModule(pair.first, pair.second, &err)) {
                                        spd->error("{}", err);
                                    }
                                }
                                stream.dissectors.push_back(script);
                            }
                            lock.unlock();
                        }
                        if (net->flag == STREAM_END) {
                            if (stream.started) {
                                for (const ScriptClassPtr &script : stream.dissectors) {
                                    std::string err;
                                    NetStreamList streams;
                                    std::vector<PacketPtr> packets;
                                    if (!script->analyzeStream(pkt, pair.first, net->data, &stream.context, &zone, &streams, &packets, &err)) {
                                        spd->error("{}", err);
                                    }
                                    streamList[pair.first].insert(streamList[pair.first].end(), streams.begin(), streams.end());
                                    for (const PacketPtr &pkt : packets) {
                                        insert(pkt);
                                    }
                                }
                            }
                            streamCache.remove(id);
                        } else {
                            if (!stream.started) {
                                stream.started = true;
                            }
                            for (const ScriptClassPtr &script : stream.dissectors) {
                                std::string err;
                                NetStreamList streams;
                                std::vector<PacketPtr> packets;
                                if (!script->analyzeStream(pkt, pair.first, net->data, &stream.context, &zone, &streams, &packets, &err)) {
                                    spd->error("{}", err);
                                }
                                streamList[pair.first].insert(streamList[pair.first].end(), streams.begin(), streams.end());
                                for (const PacketPtr &pkt : packets) {
                                    insert(pkt);
                                }
                            }
                        }
                        streamCache.set(id, stream);
                    }
                }
            }

            lock.lock();
            d->streamMaxID = maxID;
        }
    });
}

Dispatcher::~Dispatcher()
{
    {
        std::lock_guard<std::mutex> lock(d->mutex);
        d->exiting = true;
    }
    d->cond.notify_all();
    d->filterCond.notify_all();
    d->streamCond.notify_all();

    for (DissectorWorker *worker : d->workers) {
        delete worker;
    }
    d->workers.clear();

    for (const auto &pair : d->filterWorkers) {
        for (const FilterWorker *worker : pair.second) {
            delete worker;
        }
    }
    d->filterWorkers.clear();

    while (!d->waitingPackets.empty()) {
        d->waitingPackets.pop();
    }

    if (d->streamThread.joinable())
        d->streamThread.join();

    delete d;
}

bool Dispatcher::loadDissector(const std::string &path, const msgpack::object &options, std::string *error)
{
    for (DissectorWorker *worker : d->workers) {
        bool result = worker->loadDissector(path, options, error);
        if (!result)
            return false;
    }
    return true;
}

bool Dispatcher::loadStreamDissector(const std::string &source, const msgpack::object &options, std::string *error)
{
    std::lock_guard<std::mutex> lock(d->mutex);

    const auto &map = options.as<std::unordered_map<std::string, msgpack::object>>();
    const msgpack::object &array = map.at("namespaces");
    for (const std::string &ns : array.as<std::vector<std::string>>()) {
        d->streamDissectors[ns].push_back(std::make_pair(source, options));
    }

    return true;
}

bool Dispatcher::setFilter(const std::string &name, const std::string &source, const msgpack::object &options)
{
    auto it = d->filterWorkers.find(name);
    if (it != d->filterWorkers.end()) {
        {
            std::lock_guard<std::mutex> lock(d->mutex);
            for (FilterWorker *worker : it->second) {
                worker->exiting = true;
            }
        }
        d->filterCond.notify_all();
        for (FilterWorker *worker : it->second) {
            delete worker;
        }
        d->filterWorkers.erase(name);
        d->filterdPackets.erase(name);
    }
    if (!name.empty() && !source.empty()) {
        std::vector<FilterWorker *> workers;
        auto filtered = std::make_shared<std::vector<uint64_t>>();
        auto ctx = std::make_shared<Dispatcher::FilterContext>();
        ctx->filtered = filtered;

        int numcore = std::max(1u, std::thread::hardware_concurrency());
        for (int i = 0; i < numcore; ++i) {
            workers.push_back(new FilterWorker(source, options, ctx, d));
        }

        d->filterWorkers[name] = workers;
        d->filterdPackets[name] = filtered;
    }
    return true;
}

bool Dispatcher::loadModule(const std::string &name, const std::string &source, std::string *error)
{
    for (DissectorWorker *worker : d->workers) {
        bool result = worker->loadModule(name, source, error);
        if (!result)
            return false;
        d->modules[name] = source;
    }
    return true;
}

void Dispatcher::insert(const PacketPtr &pkt)
{
    if (!pkt)
        return;

    {
        std::lock_guard<std::mutex> lock(d->mutex);

        if (d->waitingPackets.size() >= 1024) {
            d->dropped++;
            return;
        }

        pkt->id = ++d->count;
    }

    if (pkt->layers.empty()) {
        LayerPtr layer = std::make_shared<Layer>();
        layer->name = "Raw Layer";
        layer->ns = "::<Ethernet>";

        std::stringstream buffer;
        msgpack::pack(buffer, std::tuple<size_t, size_t>(0, pkt->payload.size()));
        const std::string &str = buffer.str();
        layer->payload = msgpack::object(msgpack::type::ext(0x1f, str.data(), str.size()), layer->zone);
        pkt->layers[layer->ns] = layer;
    }

    {
        std::lock_guard<std::mutex> lock(d->mutex);
        d->waitingPackets.push(pkt);
    }
    d->cond.notify_all();
}

std::vector<PacketPtr> Dispatcher::get(uint64_t start, uint64_t end) const
{
    std::vector<PacketPtr> packets;

    if (start == 0 || end == 0 || start > end)
        return packets;

    std::lock_guard<std::mutex> lock(d->mutex);

    for (uint64_t i = start; i <= end; ++i) {
        if (i > d->streamMaxID)
            break;
        PacketPtr pkt = d->packets.get(i);
        if (pkt)
            packets.push_back(pkt);
    }
    return packets;
}

std::vector<PacketPtr> Dispatcher::get(const std::vector<uint64_t> &list) const
{
    std::vector<PacketPtr> packets;
    std::lock_guard<std::mutex> lock(d->mutex);

    for (uint64_t i : list) {
        PacketPtr pkt = d->packets.get(i);
        if (pkt)
            packets.push_back(pkt);
    }

    std::sort(packets.begin(), packets.end(), [](const PacketPtr &a, const PacketPtr &b) {
        return a->id < b->id;
    });
    return packets;
}

std::vector<uint64_t> Dispatcher::getFiltered(const std::string &name, uint64_t start, uint64_t end) const
{
    std::vector<uint64_t> packets;

    if (start > end)
        return packets;

    std::lock_guard<std::mutex> lock(d->mutex);
    const auto &it = d->filterdPackets.find(name);
    if (it != d->filterdPackets.end()) {
        for (uint64_t i = start; i < end; ++i) {
            if (i >= it->second->size())
                break;
            packets.push_back(it->second->at(i));
        }
    }
    return packets;
}

uint64_t Dispatcher::queuedSize() const
{
    std::lock_guard<std::mutex> lock(d->mutex);
    return d->waitingPackets.size();
}

uint64_t Dispatcher::size() const
{
    std::lock_guard<std::mutex> lock(d->mutex);
    return d->streamMaxID;
}

uint64_t Dispatcher::dropped() const
{
    std::lock_guard<std::mutex> lock(d->mutex);
    return d->dropped;
}

std::unordered_map<std::string, uint64_t> Dispatcher::filtered() const
{
    std::unordered_map<std::string, uint64_t> map;
    std::lock_guard<std::mutex> lock(d->mutex);
    for (const auto &pair : d->filterdPackets) {
        map[pair.first] = pair.second->size();
    }
    return map;
}
