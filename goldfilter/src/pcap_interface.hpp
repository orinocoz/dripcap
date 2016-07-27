#ifndef PCAP_INTERFACE_HPP
#define PCAP_INTERFACE_HPP

#include "device.hpp"
#include <functional>
#include <string>
#include <vector>

struct Packet;

typedef std::function<void(Packet *)> PcapCallback;

class PcapInterface
{
  public:
    PcapInterface();
    virtual ~PcapInterface();
    virtual void handle(const PcapCallback &func) = 0;
    virtual bool start() = 0;
    virtual bool stop() = 0;
    virtual std::vector<Device> getAllDevs() const = 0;

    virtual std::string interface() const = 0;
    virtual void setInterface(const std::string &ifs) = 0;
    virtual bool promiscuous() const = 0;
    virtual void setPromiscuous(bool promisc) = 0;
    virtual int snaplen() const = 0;
    virtual void setSnaplen(int len) = 0;

    virtual bool setBPF(const std::string &filter, std::string *error) = 0;
};

#endif
