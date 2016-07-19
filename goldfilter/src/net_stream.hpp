#ifndef STREAM_HPP
#define STREAM_HPP

#include <memory>
#include <msgpack.hpp>

enum StreamFlag {
    STREAM_NOOP,
    STREAM_START,
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

    void start();
    void end();

  public:
    std::string name;
    std::string ns;
    std::string id;
    std::map<uint64_t, msgpack::object> data;
    StreamFlag flag;
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
            o.pack_map(5);
            o.pack("name");
            o.pack(v->name);
            o.pack("namespace");
            o.pack(v->ns);
            o.pack("id");
            o.pack(v->id);
            o.pack("data");
            o.pack(v->data);
            o.pack("flag");
            o.pack(v->flag);
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
