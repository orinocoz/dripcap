#ifndef LAYER_HPP
#define LAYER_HPP

#include "net_stream.hpp"
#include <memory>
#include <msgpack.hpp>

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
            o.pack_map(5 + v->ext.size());
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
    struct convert<LayerPtr> {
        msgpack::object const &operator()(msgpack::object const &o, LayerPtr &v) const
        {
            v.reset(new Layer);
            v->ext = o.as<std::unordered_map<std::string, msgpack::object>>();

            const auto &ns = v->ext.find("namespace");
            const auto &name = v->ext.find("name");
            const auto &payload = v->ext.find("payload");
            const auto &layers = v->ext.find("layers");
            const auto &streams = v->ext.find("streams");

            if (ns != v->ext.end()) {
                v->ns = ns->second.as<std::string>();
            }
            if (name != v->ext.end()) {
                v->name = name->second.as<std::string>();
            }
            if (payload != v->ext.end()) {
                v->payload = payload->second;
            }
            if (layers != v->ext.end()) {
                v->layers = layers->second.as<LayerList>();
            }
            if (streams != v->ext.end()) {
                v->streams = streams->second.as<NetStreamList>();
            }

            v->ext.erase("namespace");
            v->ext.erase("name");
            v->ext.erase("payload");
            v->ext.erase("layers");
            v->ext.erase("streams");
            return o;
        }
    };

    } // namespace adaptor
} // MSGPACK_API_VERSION_NAMESPACE(MSGPACK_DEFAULT_API_NS)
} // namespace msgpack

#endif
