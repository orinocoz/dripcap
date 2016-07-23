#ifndef VIRTUAL_PACKET_HPP
#define VIRTUAL_PACKET_HPP

#include "layer.hpp"

struct VirtualPacket {
    uint64_t ts_sec = 0;
    uint32_t ts_nsec = 0;
    uint32_t len = 0;
    LayerList layers;
};

#endif
