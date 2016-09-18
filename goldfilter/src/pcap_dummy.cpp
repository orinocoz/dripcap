#include "pcap_dummy.hpp"
#include "device.hpp"
#include "packet.hpp"
#include <chrono>
#include <mutex>
#include <pcap.h>
#include <spdlog/spdlog.h>
#include <thread>

class PcapDummy::Private
{
  public:
    Private();
    ~Private();

  public:
    PcapCallback handler;
    std::string interface;
    int snaplen;
    bool promisc;
    bool active;

    std::vector<PacketPtr> packets;
    std::vector<Device> devices;

    std::thread thread;
    std::mutex mutex;
};

PcapDummy::Private::Private()
    : snaplen(1600), promisc(false), active(false)
{
}

PcapDummy::Private::~Private()
{
}

PcapDummy::PcapDummy()
	: d(new Private())
{

}

PcapDummy::PcapDummy(const msgpack::object &obj)
    : d(new Private())
{
    const auto &map = obj.as<std::unordered_map<std::string, msgpack::object>>();
    const auto &packets = map.find("packets");
    const auto &devices = map.find("devices");
    for (const auto &obj : packets->second.as<std::vector<msgpack::object>>()) {
        d->packets.push_back(obj.as<PacketPtr>());
    }
    for (const auto &obj : devices->second.as<std::vector<msgpack::object>>()) {
        d->devices.push_back(Device(obj));
    }
}

PcapDummy::~PcapDummy()
{
    stop();
    delete d;
}

void PcapDummy::handle(const PcapCallback &func)
{
    d->handler = func;
}

bool PcapDummy::start()
{
    {
        std::lock_guard<std::mutex> lock(d->mutex);
        if (d->active)
            return false;

        d->active = true;
    }

    d->thread = std::thread([this]() {
        size_t count = 0;
        while (true) {
            PacketPtr pkt;
            {
                std::lock_guard<std::mutex> lock(d->mutex);
                if (!d->active)
                    return;
                if (d->packets.size() > 0) {
                    pkt = d->packets.at(count);
                    count = (count + 1) % d->packets.size();
                }
            }

            if (pkt && d->handler)
                d->handler(pkt);

            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    });
    return true;
}

bool PcapDummy::stop()
{
    {
        std::lock_guard<std::mutex> lock(d->mutex);
        if (!d->active)
            return false;

        d->active = false;
    }

    d->thread.join();
    return true;
}

std::vector<Device> PcapDummy::getAllDevs() const
{
    return d->devices;
}

std::string PcapDummy::interface() const
{
    return d->interface;
}

void PcapDummy::setInterface(const std::string &ifs)
{
    d->interface = ifs;
}

bool PcapDummy::promiscuous() const
{
    return d->promisc;
}

void PcapDummy::setPromiscuous(bool promisc)
{
    d->promisc = promisc;
}

int PcapDummy::snaplen() const
{
    return d->snaplen;
}

void PcapDummy::setSnaplen(int len)
{
}

bool PcapDummy::setBPF(const std::string &filter, std::string *error)
{
    return true;
}
