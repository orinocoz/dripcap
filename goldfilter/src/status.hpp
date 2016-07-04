#ifndef STATUS_HPP
#define STATUS_HPP

#include <msgpack.hpp>

struct Status {
    bool capturing;
    uint64_t queuedPackets;
    uint64_t packets;
    std::unordered_map<std::string, uint64_t> filtered;
};

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
            o.pack_map(4);
            o.pack("capturing");
            o.pack(v.capturing);
            o.pack("queued");
            o.pack(v.queuedPackets);
            o.pack("packets");
            o.pack(v.packets);
            o.pack("filtered");
            o.pack(v.filtered);
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
