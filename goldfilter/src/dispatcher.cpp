#include "dispatcher.hpp"
#include "packet.hpp"
#include "layer.hpp"
#include "script_class.hpp"
#include "channel.hpp"
#include <spdlog/spdlog.h>
#include <queue>
#include <vector>
#include <thread>
#include <sstream>
#include <mutex>
#include <condition_variable>

class Dispatcher::Private
{
  public:
    static LayerPtr firstLayer(Packet *pkt);

  public:
    std::queue<Packet *> waitingPackets;
    std::vector<Packet *> packets;
    std::vector<DissectorWorker *> workers;
    std::unordered_map<std::string, std::vector<FilterWorker *>> filterWorkers;
    std::unordered_map<std::string, std::shared_ptr<std::vector<uint64_t>>> filterdPackets;
    std::unordered_map<std::string, std::string> modules;

    bool exiting = false;
    uint64_t maxID = 0;
    std::condition_variable cond;
    std::condition_variable filterCond;
    std::mutex mutex;

    Channel<Packet *> packetChan;
};

LayerPtr Dispatcher::Private::firstLayer(Packet *pkt)
{
    std::function<LayerPtr(const LayerList &)> find = [pkt, &find](const LayerList &layers) -> LayerPtr {
        for (const auto &pair : layers) {
            const std::string &ns = pair.first;
            if (pkt->history.count(ns) == 0) {
                pkt->history.insert(ns);
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

        ScriptClassPtr script = std::make_shared<ScriptClass>(opt);

        std::string err;

        {
            std::unique_lock<std::mutex> lock(d->mutex);
            for (const auto &pair : d->modules) {
                if (!script->loadModule(pair.first, pair.second, &err)) {
                    auto spd = spdlog::get("console");
                    spd->error("errord {}", err);
                }
            }
        }

        if (!script->loadSource(source, &err)) {
            auto spd = spdlog::get("console");
            spd->error("errort {}", err);
            return false;
        }

        while (true) {
            std::unique_lock<std::mutex> lock(d->mutex);
            d->filterCond.wait(lock, [this, ctx] {
                return d->exiting || exiting || d->maxID > ctx->fetchedMaxID;
            });
            if (d->exiting || exiting)
                return false;

            ++ctx->fetchedMaxID;
            ctx->filtering.insert(ctx->fetchedMaxID);
            Packet *pkt = d->packets.at(ctx->fetchedMaxID - 1);

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

    Channel<std::pair<std::string, msgpack::object>> sourceChan;
};

Dispatcher::DissectorWorker::DissectorWorker(Dispatcher::Private *parent)
    : d(parent)
{
    thread = std::thread([this]() {
        auto spd = spdlog::get("console");

        while (true) {
            switch (ChannelBase::select({&sourceChan, &d->packetChan})) {
            case 0: {
                const auto &pair = sourceChan.recv();
                if (pair.first.empty()) {
                    return false;
                }
                ScriptClassPtr script = std::make_shared<ScriptClass>(pair.second);

                auto spd = spdlog::get("console");
                spd->error("modules count {}", modules.size());
                for (const auto &pair : modules) {
                    std::string err;
                    if (!script->loadModule(pair.first, pair.second, &err)) {
                        auto spd = spdlog::get("console");
                        spd->error("errord {}", err);
                    }
                }

                if (script->loadSource(pair.first, nullptr)) {
                    const auto &map = pair.second.as<std::unordered_map<std::string, msgpack::object>>();
                    const msgpack::object &array = map.at("namespaces");
                    for (const std::string &ns : array.as<std::vector<std::string>>()) {
                        dissectors[ns].push_back(script);
                    }
                }
            } break;
            case 1: {
                Packet *pkt = d->packetChan.recv();
                if (!pkt) {
                    return false;
                }

                LayerPtr parentLayer = d->firstLayer(pkt);
                while (parentLayer) {
                    const auto &it = dissectors.find(parentLayer->ns);
                    if (it != dissectors.end()) {
                        for (const auto &dissector : it->second) {
                            std::string err;
                            if (!dissector->analyze(pkt, parentLayer, &err)) {
                                auto spd = spdlog::get("console");
                                spd->error("errord {}", err);
                            }
                        }
                    }
                    parentLayer = d->firstLayer(pkt);
                }

                {
                    std::unique_lock<std::mutex> lock(d->mutex);
                    if (d->packets.size() < pkt->id)
                        d->packets.resize(pkt->id);
                    d->packets[pkt->id - 1] = pkt;

                    if (d->maxID == 0) {
                        if (d->packets.at(0)) {
                            d->maxID = 1;
                        } else {
                            continue;
                        }
                    }
                    while (d->maxID < d->packets.size() && d->packets.at(d->maxID))
                        d->maxID++;

                    d->filterCond.notify_all();
                }
            } break;
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
    sourceChan.send(std::make_pair(source, msgpack::object(options, zone)));
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

Dispatcher::Dispatcher()
    : d(new Private())
{
    int numcore = std::max(1u, std::thread::hardware_concurrency());
    for (int i = 0; i < numcore; ++i) {
        d->workers.push_back(new DissectorWorker(d));
    }
}

Dispatcher::~Dispatcher()
{
    {
        std::lock_guard<std::mutex> lock(d->mutex);
        d->exiting = true;
    }
    d->cond.notify_all();
    d->filterCond.notify_all();

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
        delete d->waitingPackets.front();
        d->waitingPackets.pop();
    }

    for (const Packet *pkt : d->packets)
        delete pkt;

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

void Dispatcher::insert(Packet *pkt)
{
    if (!pkt || pkt->id == 0)
        return;

    LayerPtr layer = std::make_shared<Layer>();
    layer->name = "Raw Layer";
    layer->ns = "::<Ethernet>";

    std::stringstream buffer;
    msgpack::pack(buffer, std::pair<size_t, size_t>(0, pkt->payload.size()));
    const std::string &str = buffer.str();
    layer->payload = msgpack::object(msgpack::type::ext(0x1f, str.data(), str.size()), layer->zone);
    pkt->layers[layer->ns] = layer;

    {
        std::lock_guard<std::mutex> lock(d->mutex);
        d->waitingPackets.push(pkt);
        d->packetChan.send(pkt);
    }
    d->cond.notify_all();
}

std::vector<const Packet *> Dispatcher::get(uint64_t start, uint64_t end) const
{
    std::vector<const Packet *> packets;

    if (start == 0 || end == 0 || start > end)
        return packets;

    std::lock_guard<std::mutex> lock(d->mutex);

    for (uint64_t i = start; i <= end; ++i) {
        if (i > d->packets.size())
            break;
        const Packet *pkt = d->packets.at(i - 1);
        if (pkt)
            packets.push_back(pkt);
    }
    return packets;
}

std::vector<const Packet *> Dispatcher::get(const std::vector<uint64_t> &list) const
{
    std::vector<const Packet *> packets;
    std::lock_guard<std::mutex> lock(d->mutex);

    for (uint64_t i : list) {
        if (i > d->packets.size())
            break;
        const Packet *pkt = d->packets.at(i - 1);
        if (pkt)
            packets.push_back(pkt);
    }

    std::sort(packets.begin(), packets.end(), [](const Packet *a, const Packet *b) {
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
    return d->maxID;
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
