#ifndef PCAP_HPP
#define PCAP_HPP

#include "pcap_interface.hpp"

class Pcap : public PcapInterface
{
  public:
    Pcap();
    virtual ~Pcap();
    void handle(const PcapCallback &func) override;
    bool start() override;
    bool stop() override;
    std::vector<Device> getAllDevs() const override;

    std::string interface() const override;
    void setInterface(const std::string &ifs) override;
    bool promiscuous() const override;
    void setPromiscuous(bool promisc) override;
    int snaplen() const override;
    void setSnaplen(int len) override;

    bool setBPF(const std::string &filter, std::string *error) override;

  public:
    Pcap(Pcap const &) = delete;
    Pcap &operator=(Pcap const &) = delete;

  private:
    class Private;
    Private *d;
};

#endif
