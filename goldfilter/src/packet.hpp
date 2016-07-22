#ifndef PACKET_HPP
#define PACKET_HPP

#include "layer.hpp"
#include <msgpack.hpp>
#include <sstream>
#include <vector>

struct Packet {
    Packet();
    Packet(const msgpack::object &obj);

    uint64_t id;
    uint64_t ts_sec;
    uint32_t ts_nsec;
    uint32_t len;
    std::vector<unsigned char> payload;
    LayerList layers;

    std::unordered_set<std::string> history;
};

typedef std::vector<const Packet *> PacketList;

namespace msgpack
{
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
{
    namespace adaptor
    {

    template <>
    struct pack<Packet> {
        template <typename Stream>
        msgpack::packer<Stream> &operator()(msgpack::packer<Stream> &o, Packet const &v) const
        {
            o.pack_map(6);
            o.pack("id");
            o.pack(v.id);
            o.pack("ts_sec");
            o.pack(v.ts_sec);
            o.pack("ts_nsec");
            o.pack(v.ts_nsec);
            o.pack("len");
            o.pack(v.len);
            o.pack("payload");
            o.pack_ext(v.payload.size(), 0x1B);
            o.pack_ext_body(reinterpret_cast<const char *>(v.payload.data()), v.payload.size());

            std::stringstream buffer;
            msgpack::pack(buffer, v.layers);
            const std::string &str = buffer.str();
            o.pack("layers");
            o.pack_ext(str.size(), 0x2F);
            o.pack_ext_body(reinterpret_cast<const char *>(str.data()), str.size());
            return o;
        }
    };

    template <>
    struct pack<PacketList> {
        template <typename Stream>
        msgpack::packer<Stream> &operator()(msgpack::packer<Stream> &o, PacketList const &v) const
        {
            o.pack_array(v.size());
            for (const Packet *pkt : v)
                o.pack(*pkt);
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
