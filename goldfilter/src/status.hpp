#ifndef STATUS_HPP
#define STATUS_HPP

#include <msgpack.hpp>

struct Status {
    Status() = default;
    bool capturing = false;
    uint64_t queuedPackets = 0;
    uint64_t packets = 0;
    uint64_t droppedPackets = 0;
    std::unordered_map<std::string, uint64_t> filtered;
    bool operator!=(const Status &stat) const;
};

bool Status::operator!=(const Status &stat) const
{
    if (capturing != stat.capturing || packets != stat.packets || filtered.size() != stat.filtered.size()) {
        return true;
    }
    for (const auto &pair : filtered) {
        if (stat.filtered.at(pair.first) != pair.second) {
            return true;
        }
    }
    return false;
}

namespace msgpack
{
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
{
    namespace adaptor
    {

    template <>
    struct pack<Status> {
        template <typename Stream>
        msgpack::packer<Stream> &operator()(msgpack::packer<Stream> &o, Status const &v) const
        {
            o.pack_map(5);
            o.pack("capturing");
            o.pack(v.capturing);
            o.pack("queued");
            o.pack(v.queuedPackets);
            o.pack("packets");
            o.pack(v.packets);
            o.pack("dropped");
            o.pack(v.droppedPackets);
            o.pack("filtered");
            o.pack(v.filtered);
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
