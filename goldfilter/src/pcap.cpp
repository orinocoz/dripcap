#include "pcap.hpp"
#include "device.hpp"
#include "packet.hpp"
#include <mutex>
#include <pcap.h>
#include <spdlog/spdlog.h>
#include <thread>

#ifndef PCAP_NETMASK_UNKNOWN
#define PCAP_NETMASK_UNKNOWN 0xffffffff
#endif

class Pcap::Private
{
  public:
    Private();
    ~Private();

  public:
    PcapCallback handler;
    std::string interface;
    int snaplen;
    bool promisc;
    pcap_t *pcap;
    bpf_program bpf;

    std::thread thread;
    std::mutex mutex;
    bool active;
};

Pcap::Private::Private()
    : snaplen(1600), promisc(false), pcap(nullptr), active(false)
{
    bpf.bf_len = 0;
    bpf.bf_insns = nullptr;
}

Pcap::Private::~Private()
{
}

Pcap::Pcap()
    : d(new Private())
{
}

Pcap::~Pcap()
{
    stop();
    if (d->thread.joinable())
        d->thread.join();
    pcap_freecode(&d->bpf);
    delete d;
}

void Pcap::handle(const PcapCallback &func)
{
    std::lock_guard<std::mutex> lock(d->mutex);
    d->handler = func;
}

bool Pcap::start()
{
    std::lock_guard<std::mutex> lock(d->mutex);
    auto spd = spdlog::get("console");

    if (d->active)
        return true;

    char err[PCAP_ERRBUF_SIZE] = {'\0'};
    d->pcap =
        pcap_open_live(d->interface.c_str(), d->snaplen, d->promisc, 500, err);
    if (!d->pcap) {
        spd->error("pcap_open_live() failed ifs:{} snaplen:{} promisc:{} {}", d->interface, d->snaplen, d->promisc, err);
        return false;
    }

    if (d->bpf.bf_len > 0 && pcap_setfilter(d->pcap, &d->bpf) < 0) {
        spd->error("pcap_setfilter() failed");
        return false;
    }

    spd->debug("start ifs:{} snaplen:{} promisc:{}", d->interface, d->snaplen, d->promisc);

    d->active = true;
    d->thread = std::thread([this]() {
        uint64_t id = 0;
        int result = 0;
        while (result >= 0) {
            struct pcap_pkthdr *header = nullptr;
            const u_char *data;
            result = pcap_next_ex(d->pcap, &header, &data);
            if (result == 1) {
                if (d->handler) {
                    Packet *p = new Packet();
                    p->id = ++id;
                    p->ts_sec = header->ts.tv_sec;
                    p->ts_nsec = header->ts.tv_usec;
                    p->len = header->len;
                    p->payload.assign(data, data + header->caplen);
                    d->handler(p);
                }
            }
            {
                std::lock_guard<std::mutex> lock(d->mutex);
                if (!d->active)
                    break;
            }
        }

        pcap_close(d->pcap);
        d->pcap = nullptr;
    });

    return true;
}

bool Pcap::stop()
{
    std::lock_guard<std::mutex> lock(d->mutex);
    if (!d->active) {
        return false;
    } else {
        d->active = false;
        return true;
    }
}

std::vector<Device> Pcap::getAllDevs() const
{
    std::lock_guard<std::mutex> lock(d->mutex);
    auto spd = spdlog::get("console");

    pcap_if_t *alldevsp;
    char err[PCAP_ERRBUF_SIZE] = {'\0'};
    if (pcap_findalldevs(&alldevsp, err) < 0) {
        spd->error("pcap_findalldevs() failed: {}", err);
        return std::vector<Device>();
    }

    std::vector<Device> devs;
    for (pcap_if_t *ifs = alldevsp; ifs; ifs = ifs->next) {
        Device dev;
        dev.name = ifs->name;
        if (ifs->description)
            dev.description = ifs->description;
        dev.loopback = ifs->flags & PCAP_IF_LOOPBACK;
        dev.link = -1;

        pcap_t *pcap =
            pcap_open_live(ifs->name, d->snaplen, d->promisc, 500, err);
        if (pcap) {
            dev.link = pcap_datalink(pcap);
            pcap_close(pcap);
        }

        devs.push_back(dev);
    }

    pcap_freealldevs(alldevsp);
    return devs;
}

std::string Pcap::interface() const
{
    std::lock_guard<std::mutex> lock(d->mutex);
    return d->interface;
}

void Pcap::setInterface(const std::string &ifs)
{
    std::lock_guard<std::mutex> lock(d->mutex);
    d->interface = ifs;
}

bool Pcap::promiscuous() const
{
    std::lock_guard<std::mutex> lock(d->mutex);
    return d->promisc;
}

void Pcap::setPromiscuous(bool promisc)
{
    std::lock_guard<std::mutex> lock(d->mutex);
    d->promisc = promisc;
}

int Pcap::snaplen() const
{
    std::lock_guard<std::mutex> lock(d->mutex);
    return d->snaplen;
}

void Pcap::setSnaplen(int len)
{
    std::lock_guard<std::mutex> lock(d->mutex);
    d->snaplen = len;
}

bool Pcap::setBPF(const std::string &filter, std::string *error)
{
    std::lock_guard<std::mutex> lock(d->mutex);
    if (d->active)
        return false;

    char err[PCAP_ERRBUF_SIZE] = {'\0'};
    pcap_t *pcap = pcap_open_live(d->interface.c_str(), d->snaplen, d->promisc, 500, err);
    if (!pcap) {
        if (error)
            error->assign(err);
        return false;
    }

    pcap_freecode(&d->bpf);
    d->bpf.bf_len = 0;
    d->bpf.bf_insns = nullptr;

    if (pcap_compile(pcap, &d->bpf, filter.c_str(), true, PCAP_NETMASK_UNKNOWN) < 0) {
        if (error)
            error->assign(pcap_geterr(pcap));
        pcap_close(pcap);
        return false;
    }

    pcap_close(pcap);
    return true;
}
