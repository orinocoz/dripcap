#ifndef LAYER_HPP
#define LAYER_HPP

#include <memory>
#include <msgpack.hpp>
#include "net_stream.hpp"

struct Layer;
typedef std::shared_ptr<Layer> LayerPtr;
typedef std::unordered_map<std::string, LayerPtr> LayerList;

struct Packet;

struct Layer {
    Packet *packet;
    std::string ns;
    std::string name;
    msgpack::object payload;
    std::unordered_map<std::string, msgpack::object> ext;
    LayerList layers;
    NetStreamList streams;
    msgpack::zone zone;
};

namespace msgpack
{
MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
{
    namespace adaptor
    {

    template <>
    struct pack<LayerPtr> {
        template <typename Stream>
        msgpack::packer<Stream> &operator()(msgpack::packer<Stream> &o, LayerPtr const &v) const
        {
            o.pack_map(4 + v->ext.size());
            for (const auto &pair : v->ext) {
                o.pack(pair.first);
                o.pack(pair.second);
            }
            o.pack("namespace");
            o.pack(v->ns);
            o.pack("name");
            o.pack(v->name);
            o.pack("payload");
            o.pack(v->payload);
            o.pack("layers");
            o.pack(v->layers);
            o.pack("streams");
            o.pack(v->streams);
            return o;
        }
    };

    template <>
    struct pack<LayerList> {
        template <typename Stream>
        msgpack::packer<Stream> &operator()(msgpack::packer<Stream> &o, LayerList const &v) const
        {
            o.pack_map(v.size());
            for (const auto &pair : v) {
                o.pack(pair.first);
                o.pack(pair.second);
            }
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
