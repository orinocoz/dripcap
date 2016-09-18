#ifndef PCAP_DUMMY_HPP
#define PCAP_DUMMY_HPP

#include "pcap_interface.hpp"
#include <msgpack.hpp>

class PcapDummy : public PcapInterface
{
  public:
	PcapDummy();
    PcapDummy(const msgpack::object &obj);
    virtual ~PcapDummy();
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

  private:
    class Private;
    Private *d;
};

#endif
