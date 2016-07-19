#ifndef STREAM_HPP
#define STREAM_HPP

#include <memory>
#include <msgpack.hpp>

enum StreamFlag {
    STREAM_NOOP,
    STREAM_BEGIN,
    STREAM_END,
};

MSGPACK_ADD_ENUM(StreamFlag);

class NetStream
{
  public:
    NetStream() = default;
    NetStream(const NetStream &) = default;
    NetStream(const std::string &name, const std::string &ns, const std::string &id);
    ~NetStream();

  public:
    std::string name;
    std::string ns;
    std::string id;
    std::map<uint64_t, msgpack::object> data;
    StreamFlag flag;

    MSGPACK_DEFINE_MAP(name, ns, id, data, flag);
};

typedef std::shared_ptr<NetStream> NetStreamPtr;
typedef std::vector<NetStreamPtr> NetStreamList;

namespace msgpack
{
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
{
    namespace adaptor
    {

    template <>
    struct pack<NetStreamPtr> {
        template <typename Stream>
        msgpack::packer<Stream> &operator()(msgpack::packer<Stream> &o, NetStreamPtr const &v) const
        {
            o.pack(*v);
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
