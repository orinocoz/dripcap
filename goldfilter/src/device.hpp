#ifndef DEVICE_HPP
#define DEVICE_HPP

#include <msgpack.hpp>

struct Device {
    Device() = default;
    Device(const msgpack::object &obj);

    std::string name;
    std::string description;
    int link = 0;
    bool loopback = false;
};

namespace msgpack
{
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
{
    namespace adaptor
    {

    template <>
    struct pack<Device> {
        template <typename Stream>
        msgpack::packer<Stream> &operator()(msgpack::packer<Stream> &o, Device const &v) const
        {
            o.pack_map(4);
            o.pack("name");
            o.pack(v.name);
            o.pack("description");
            o.pack(v.description);
            o.pack("link");
            o.pack(v.link);
            o.pack("loopback");
            o.pack(v.loopback);
            return o;
        }
    };
    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
