#ifndef PACKET_HPP
#define PACKET_HPP

#include "layer.hpp"
#include <memory>
#include <msgpack.hpp>
#include <sstream>
#include <vector>

struct Packet {
    Packet() = default;

    uint64_t id = 0;
    uint64_t ts_sec = 0;
    uint32_t ts_nsec = 0;
    uint32_t len = 0;
    std::vector<unsigned char> payload;
    std::string stream;
    LayerList layers;

    msgpack::zone zone;
};

typedef std::shared_ptr<Packet> PacketPtr;
typedef std::vector<PacketPtr> PacketList;

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
            o.pack_map(7);
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
            o.pack("stream");
            o.pack(v.stream);

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
            for (const PacketPtr &pkt : v)
                o.pack(*pkt);
            return o;
        }
    };

    template <>
    struct convert<PacketPtr> {
        msgpack::object const &operator()(msgpack::object const &o, PacketPtr &v) const
        {
            const auto &map = o.as<std::unordered_map<std::string, msgpack::object>>();
            const auto &id = map.find("id");
            const auto &ts_sec = map.find("ts_sec");
            const auto &ts_nsec = map.find("ts_nsec");
            const auto &len = map.find("len");
            const auto &payload = map.find("payload");
            const auto &stream = map.find("stream");
            const auto &layers = map.find("layers");

            v.reset(new Packet());
            if (id != map.end()) {
                v->id = id->second.as<uint64_t>();
            }
            if (ts_sec != map.end()) {
                v->ts_sec = ts_sec->second.as<uint64_t>();
            }
            if (ts_nsec != map.end()) {
                v->ts_nsec = ts_nsec->second.as<uint32_t>();
            }
            if (len != map.end()) {
                v->len = len->second.as<uint32_t>();
            }
            if (payload != map.end()) {
                if (payload->second.type == msgpack::type::BIN) {
                    v->payload = payload->second.as<std::vector<unsigned char>>();
                } else {
                    msgpack::type::ext ext = payload->second.as<msgpack::type::ext>();
                    v->payload.assign(ext.data(), ext.data() + ext.size());
                }
            }
            if (stream != map.end()) {
                v->stream = stream->second.as<std::string>();
            }
            if (layers != map.end()) {
                msgpack::type::ext ext = layers->second.as<msgpack::type::ext>();
                msgpack::object_handle result;
                msgpack::unpack(result, ext.data(), ext.size());
                msgpack::object layers(result.get(), v->zone);
                v->layers = layers.as<LayerList>();
            }
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
