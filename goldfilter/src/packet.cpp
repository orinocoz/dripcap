#include "packet.hpp"

Packet::Packet(const msgpack::object &obj)
{
    const auto &map = obj.as<std::unordered_map<std::string, msgpack::object>>();
    const auto &id = map.find("id");
    const auto &ts_sec = map.find("ts_sec");
    const auto &ts_nsec = map.find("ts_nsec");
    const auto &len = map.find("len");
    const auto &payload = map.find("payload");

    if (id != map.end()) {
        this->id = id->second.as<uint64_t>();
    }
    if (ts_sec != map.end()) {
        this->ts_sec = ts_sec->second.as<uint64_t>();
    }
    if (ts_nsec != map.end()) {
        this->ts_nsec = ts_nsec->second.as<uint32_t>();
    }
    if (len != map.end()) {
        this->len = len->second.as<uint32_t>();
    }
    if (payload != map.end()) {
        this->payload = payload->second.as<std::vector<unsigned char>>();
    }
}
