#include "device.hpp"

Device::Device(const msgpack::object &obj)
{
    const auto &map = obj.as<std::unordered_map<std::string, msgpack::object>>();
    const auto &name = map.find("name");
    const auto &description = map.find("description");
    const auto &link = map.find("link");
    const auto &loopback = map.find("loopback");

    if (name != map.end()) {
        this->name = name->second.as<std::string>();
    }
    if (description != map.end()) {
        this->description = description->second.as<std::string>();
    }
    if (link != map.end()) {
        this->link = link->second.as<int>();
    }
    if (loopback != map.end()) {
        this->loopback = loopback->second.as<bool>();
    }
}
