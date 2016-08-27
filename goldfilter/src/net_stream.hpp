#ifndef STREAM_HPP
#define STREAM_HPP

#include "include/v8.h"
#include <memory>
#include <msgpack.hpp>

enum StreamFlag {
    STREAM_NOOP,
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
    void end();

  public:
    std::string name;
    std::string ns;
    std::string id;
    msgpack::object data;
    StreamFlag flag = STREAM_NOOP;
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

    template <>
    struct convert<NetStreamPtr> {
        msgpack::object const &operator()(msgpack::object const &o, NetStreamPtr &v) const
        {
            const auto &map = o.as<std::unordered_map<std::string, msgpack::object>>();
            const auto &name = map.find("name");
            const auto &ns = map.find("namespace");
            const auto &id = map.find("id");
            const auto &data = map.find("data");
            const auto &flag = map.find("flag");

            v.reset(new NetStream());
            if (name != map.end()) {
                v->name = name->second.as<std::string>();
            }
            if (ns != map.end()) {
                v->ns = ns->second.as<std::string>();
            }
            if (id != map.end()) {
                v->id = id->second.as<std::string>();
            }
            if (data != map.end()) {
                v->data = data->second;
            }
            if (flag != map.end()) {
                v->flag = flag->second.as<StreamFlag>();
            }

            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
