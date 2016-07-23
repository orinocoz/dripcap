#include "script_class.hpp"
#include "buffer.hpp"
#include "include/libplatform/libplatform.h"
#include "include/v8.h"
#include "net_stream.hpp"
#include "packet.hpp"
#include <fstream>
#include <spdlog/spdlog.h>
#include <sstream>
#include <v8pp/class.hpp>
#include <v8pp/function.hpp>
#include <v8pp/module.hpp>
#include <v8pp/object.hpp>

using namespace v8;

class ArrayBufferAllocator : public ArrayBuffer::Allocator
{
  public:
    virtual void *Allocate(size_t length)
    {
        void *data = AllocateUninitialized(length);
        return data == NULL ? data : memset(data, 0, length);
    }
    virtual void *AllocateUninitialized(size_t length)
    {
        return malloc(length);
    }
    virtual void Free(void *data, size_t)
    {
        free(data);
    }
};

class ScriptClass::Private
{
  public:
    Private(const msgpack::object &options);
    ~Private();

  public:
    ArrayBufferAllocator allocator;
    Isolate *isolate;
    UniquePersistent<Context> context;
    UniquePersistent<Function> ctor;
    UniquePersistent<Object> analyzerObject;
    UniquePersistent<Object> dripcap;
    UniquePersistent<FunctionTemplate> require;
    std::unordered_map<std::string, UniquePersistent<UnboundScript>> modules;
    std::unordered_map<std::string, UniquePersistent<Function>> moduleChache;
    msgpack::object options;
};

namespace
{

Local<Value> MsgpackToV8(const msgpack::object &o, const ScriptClass::PacketCallback &func = ScriptClass::PacketCallback())
{
    Isolate *isolate = Isolate::GetCurrent();
    switch (o.type) {
    case msgpack::type::NIL:
        return Null(isolate);
    case msgpack::type::BOOLEAN:
        return Boolean::New(isolate, o.as<bool>());
    case msgpack::type::POSITIVE_INTEGER:
    case msgpack::type::NEGATIVE_INTEGER:
    case msgpack::type::FLOAT:
        return Number::New(isolate, o.as<double>());
    case msgpack::type::STR:
        return v8pp::to_v8(isolate, o.as<std::string>());
    case msgpack::type::BIN: {
        auto vec = std::make_shared<Buffer::Data>(o.as<Buffer::Data>());
        return v8pp::class_<Buffer>::create_object(isolate, vec);
    }
    case msgpack::type::ARRAY: {
        Local<Array> array = Array::New(isolate);
        const auto &objs = o.as<std::vector<msgpack::object>>();
        for (size_t i = 0; i < objs.size(); ++i) {
            array->Set(i, MsgpackToV8(objs[i], func));
        }
        return array;
    }
    case msgpack::type::MAP: {
        Local<Object> obj = Object::New(isolate);
        const auto &map = o.as<std::unordered_map<std::string, msgpack::object>>();
        for (const auto &pair : map) {
            obj->Set(v8pp::to_v8(isolate, pair.first), MsgpackToV8(pair.second, func));
        }
        return obj;
    }
    case msgpack::type::EXT: {
        {
            msgpack::type::ext ext = o.as<msgpack::type::ext>();
            switch (ext.type()) {
            case 0x1b: {
                auto vec = std::make_shared<Buffer::Data>();
                vec->assign(ext.data(), ext.data() + ext.size());
                return v8pp::class_<Buffer>::create_object(isolate, vec);
            } break;
            case 0x1f: {
                if (func) {
                    msgpack::object_handle result;
                    msgpack::unpack(result, ext.data(), ext.size());
                    msgpack::object obj(result.get());
                    const auto &tuple = obj.as<std::tuple<uint64_t, size_t, size_t>>();
                    Packet *pkt;
                    if ((pkt = func(std::get<0>(tuple)))) {
                        return v8pp::class_<Payload>::create_object(isolate, &pkt->payload, std::get<0>(tuple), std::get<1>(tuple), std::get<2>(tuple));
                    }
                }
            } break;
            case 0x20: {
                msgpack::object_handle result;
                msgpack::unpack(result, ext.data(), ext.size());
                msgpack::object obj(result.get());
                Local<Value> v = MsgpackToV8(obj, func);
                if (!v.IsEmpty() && v->IsArray()) {
                    Local<Array> array = v.As<Array>();
                    if (array->Length() > 0) {
                        Local<Value> name = array->Get(0);
                        if (name->IsString()) {
                            Local<Context> ctx = isolate->GetCurrentContext();
                            Local<External> external = ctx->GetEmbedderData(1).As<External>();
                            ScriptClass::Private *d = static_cast<ScriptClass::Private *>(external->Value());
                            const std::string &nameStr = v8pp::from_v8<std::string>(isolate, name, "");

                            Local<Value> exports;

                            const auto &cache = d->moduleChache.find(nameStr);
                            if (cache != d->moduleChache.end()) {
                                exports = Local<Function>::New(isolate, cache->second);
                            } else {
                                const auto &modules = d->modules;
                                const auto &it = modules.find(nameStr);
                                if (it != modules.end()) {
                                    Local<Context> context = Context::New(isolate);
                                    context->SetSecurityToken(isolate->GetCurrentContext()->GetSecurityToken());

                                    {
                                        Context::Scope context_scope(context);
                                        Local<Script> script = Local<UnboundScript>::New(isolate, it->second)->BindToCurrentContext();

                                        TryCatch try_catch;
                                        Local<Object> module = Object::New(isolate);
                                        Local<Object> global = context->Global();
                                        global->Set(v8pp::to_v8(isolate, "require"), Local<FunctionTemplate>::New(isolate, d->require)->GetFunction());
                                        global->Set(v8pp::to_v8(isolate, "module"), module);

                                        MaybeLocal<Value> maybeResult = script->Run(context);
                                        if (maybeResult.IsEmpty()) {
                                            String::Utf8Value err(try_catch.Exception());
                                            auto spd = spdlog::get("console");
                                            spd->error("modules: {}", *err);
                                        } else {
                                            exports = module->Get(v8pp::to_v8(isolate, "exports"));
                                        }

                                        if (!exports.IsEmpty() && exports->IsFunction()) {
                                            Local<Function> func = exports.As<Function>();
                                            func->Set(v8pp::to_v8(isolate, "__msgpackClass"), name);
                                            func->Set(v8pp::to_v8(isolate, "__esModule"), Boolean::New(isolate, true));
                                            d->moduleChache[it->first] = UniquePersistent<Function>(isolate, func);
                                        }
                                    }
                                }
                            }

                            if (!exports.IsEmpty() && exports->IsFunction()) {
                                std::vector<Handle<Value>> args;
                                for (size_t i = 1; i < array->Length(); ++i) {
                                    args.push_back(array->Get(i));
                                }
                                TryCatch try_catch;
                                Local<Object> obj = exports.As<Function>()->NewInstance(args.size(), args.data());
                                if (obj.IsEmpty()) {
                                    String::Utf8Value err(try_catch.Exception());
                                    auto spd = spdlog::get("console");
                                    spd->error("r {}", *err);
                                } else {
                                    return obj;
                                }
                            }
                        }
                    }
                }
            } break;
            default:;
            }
            auto vec = std::make_shared<Buffer::Data>();
            vec->assign(ext.data(), ext.data() + ext.size());
            return v8pp::class_<CustomValue>::create_object(isolate, vec);
        }
    }

    default:
        break;
    }
    return Local<Value>();
}

msgpack::object v8ToMsgpack(Local<Value> v, msgpack::zone *zone)
{
    Isolate *isolate = Isolate::GetCurrent();
    if (!v.IsEmpty()) {
        Payload *payload;
        if ((payload = v8pp::class_<Payload>::unwrap_object(isolate, v))) {
            std::stringstream buffer;
            const auto &pair = payload->range();
            msgpack::pack(buffer, std::tuple<uint64_t, size_t, size_t>(payload->pkt, pair.first, pair.second));
            const std::string &str = buffer.str();
            return msgpack::object(msgpack::type::ext(0x1f, str.data(), str.size()), *zone);
        }

        CustomValue *custom;
        if ((custom = v8pp::class_<CustomValue>::unwrap_object(isolate, v))) {
            return msgpack::object(msgpack::type::ext(0x20, reinterpret_cast<const char *>(custom->data()), custom->length()), *zone);
        }

        Buffer *buffer;
        if ((buffer = v8pp::class_<Buffer>::unwrap_object(isolate, v))) {
            Buffer::Data buf;
            buf.assign(buffer->data(), buffer->data() + buffer->length());
            return msgpack::object(buf, *zone);
        }

        if (v->IsString()) {
            Local<String> strObj = v.As<String>();
            std::string str;
            str.resize(strObj->Utf8Length() + 1);
            strObj->WriteUtf8(&str[0]);
            str.resize(str.size() - 1);
            return msgpack::object(str, *zone);
        }

        if (v->IsArray()) {
            std::vector<msgpack::object> list;
            Local<Array> array = v.As<Array>();
            for (size_t i = 0; i < array->Length(); ++i) {
                list.push_back(v8ToMsgpack(array->Get(i), zone));
            }
            return msgpack::object(list, *zone);
        }

        if (v->IsBoolean()) {
            return msgpack::object(v.As<Boolean>()->Value());
        }

        if (v->IsNumber()) {
            return msgpack::object(v.As<Number>()->Value());
        }

        if (v->IsObject()) {
            Local<Object> obj = v.As<Object>();
            Local<Value> args = obj->Get(v8pp::to_v8(isolate, std::string("toMsgpack")));
            Local<Value> ctor = obj->Get(v8pp::to_v8(isolate, std::string("constructor")));
            Local<Value> name = ctor.As<Object>()->Get(v8pp::to_v8(isolate, std::string("__msgpackClass")));

            if (args->IsFunction() && name->IsString()) {
                Local<Value> ret = args.As<Function>()->Call(v, 0, nullptr);
                if (ret->IsArray()) {
                    Local<Array> array = ret.As<Array>();
                    for (int i = array->Length() - 1; i >= 0; --i) {
                        array->Set(i + 1, array->Get(i));
                    }
                    array->Set(0, name);
                    const msgpack::object &obj = v8ToMsgpack(array, zone);
                    std::stringstream buffer;
                    msgpack::pack(buffer, obj);
                    const std::string &str = buffer.str();
                    return msgpack::object(msgpack::type::ext(0x20, str.data(), str.size()), *zone);
                }
            }

            std::unordered_map<std::string, msgpack::object> map;
            Local<Array> keys = obj->GetOwnPropertyNames();
            for (size_t i = 0; i < keys->Length(); ++i) {
                map[v8pp::from_v8<std::string>(isolate, keys->Get(i), "")] = v8ToMsgpack(obj->Get(keys->Get(i)), zone);
            }
            return msgpack::object(map, *zone);
        }
    }
    return msgpack::object(msgpack::type::nil_t());
}
}

class LayerWrapper
{
  public:
    LayerWrapper();
    explicit LayerWrapper(const LayerPtr &layer);
    ~LayerWrapper();

    void syncToScript();
    void syncFromScript();

    std::string ns() const;
    void setNs(const std::string &ns);

    std::string name() const;
    void setName(const std::string &name);

    LayerPtr getLayer() const;
    Local<Object> findLayer(const LayerPtr &layer) const;

  private:
    msgpack::object v8ToMsgpack(Local<Value> v);
    Local<Value> msgpackToV8(const msgpack::object &o);

  private:
    LayerPtr layer;
};

LayerWrapper::LayerWrapper()
    : layer(std::make_shared<Layer>())
{
}

LayerWrapper::LayerWrapper(const LayerPtr &layer)
    : layer(layer)
{
}

LayerWrapper::~LayerWrapper()
{
}

std::string LayerWrapper::ns() const
{
    return layer->ns;
}

void LayerWrapper::setNs(const std::string &ns)
{
    layer->ns = ns;
}

std::string LayerWrapper::name() const
{
    return layer->name;
}

void LayerWrapper::setName(const std::string &name)
{
    layer->name = name;
}

void LayerWrapper::syncToScript()
{
    Isolate *isolate = Isolate::GetCurrent();
    Local<Object> obj = v8pp::class_<LayerWrapper>::find_object(isolate, this);
    for (const auto &pair : layer->ext) {
        obj->Set(v8pp::to_v8(isolate, pair.first), msgpackToV8(pair.second));
    }

    std::map<std::string, Local<Value>> list;
    for (const auto &pair : layer->layers) {
        pair.second->packet = layer->packet;
        Local<Object> obj = v8pp::class_<LayerWrapper>::create_object(isolate, pair.second);
        LayerWrapper *wrapper = v8pp::class_<LayerWrapper>::unwrap_object(isolate, obj);
        wrapper->syncToScript();
        list[pair.first] = obj;
    }
    obj->ForceSet(v8pp::to_v8(isolate, "layers"), v8pp::to_v8(isolate, list), PropertyAttribute(ReadOnly | DontDelete));

    Local<Value> payload = msgpackToV8(layer->payload);
    if (!payload.IsEmpty()) {
        obj->Set(v8pp::to_v8(isolate, "payload"), payload);
    }

    Local<Array> streams = Array::New(isolate);
    for (size_t i = 0; i < layer->streams.size(); ++i) {
        const NetStream &st = *layer->streams.at(i);
        Local<Value> data = msgpackToV8(st.data);
        obj->Set(v8pp::to_v8(isolate, "data"), data);
        streams->Set(i, obj);
    }
    obj->ForceSet(v8pp::to_v8(isolate, "streams"), streams, PropertyAttribute(ReadOnly | DontDelete));
}

void LayerWrapper::syncFromScript()
{
    Isolate *isolate = Isolate::GetCurrent();
    Local<Object> obj = v8pp::class_<LayerWrapper>::find_object(isolate, this);

    Local<Object> layers = obj->Get(v8pp::to_v8(isolate, std::string("layers"))).As<Object>();
    layer->layers.clear();

    Local<Array> layerKeys = layers->GetOwnPropertyNames();
    for (size_t i = 0; i < layerKeys->Length(); ++i) {
        LayerWrapper *wrapper = v8pp::class_<LayerWrapper>::unwrap_object(isolate, layers->Get(layerKeys->Get(i)));
        const std::string &name = v8pp::from_v8<std::string>(isolate, layerKeys->Get(i), "");
        if (wrapper) {
            wrapper->getLayer()->packet = layer->packet;
            wrapper->syncFromScript();
            layer->layers[name] = wrapper->getLayer();
        }
    }

    Local<Value> payload = obj->Get(v8pp::to_v8(isolate, std::string("payload")));
    layer->payload = v8ToMsgpack(payload);

    static const std::unordered_set<std::string> reserved = {
        "namespace", "name", "layers", "payload", "streams"};
    Local<Array> extKeys = obj->GetOwnPropertyNames();
    for (size_t i = 0; i < extKeys->Length(); ++i) {
        const std::string &name = v8pp::from_v8<std::string>(isolate, extKeys->Get(i), "");
        if (reserved.count(name) == 0) {
            layer->ext[name] = v8ToMsgpack(obj->Get(extKeys->Get(i)));
        }
    }

    layer->streams.clear();
    Local<Array> streams = obj->Get(v8pp::to_v8(isolate, std::string("streams"))).As<Array>();
    for (size_t i = 0; i < streams->Length(); ++i) {
        Local<Object> stream = streams->Get(i).As<Object>();
        NetStream *ns = v8pp::class_<NetStream>::unwrap_object(isolate, stream);
        if (ns) {
            Local<Value> data = stream->Get(v8pp::to_v8(isolate, std::string("data")));
            ns->data = v8ToMsgpack(data);
            layer->streams.push_back(std::make_shared<NetStream>(*ns));
        }
    }
}

Local<Object> LayerWrapper::findLayer(const LayerPtr &finding) const
{
    Isolate *isolate = Isolate::GetCurrent();
    Local<Object> obj = v8pp::class_<LayerWrapper>::find_object(isolate, this);
    if (layer == finding)
        return obj;

    Local<Object> array = obj->Get(v8pp::to_v8(isolate, std::string("layers"))).As<Object>();
    Local<Array> layerKeys = array->GetOwnPropertyNames();
    for (size_t i = 0; i < layerKeys->Length(); ++i) {
        Local<Value> layer = array->Get(layerKeys->Get(i));
        LayerWrapper *wrapper = v8pp::class_<LayerWrapper>::unwrap_object(isolate, layer);
        if (wrapper) {
            if (wrapper->layer == finding) {
                return layer.As<Object>();
            }
            Local<Object> child = wrapper->findLayer(finding);
            if (!child.IsEmpty()) {
                return child;
            }
        }
    }
    return Local<Object>();
}

LayerPtr LayerWrapper::getLayer() const
{
    return layer;
}

msgpack::object LayerWrapper::v8ToMsgpack(Local<Value> v)
{
    return ::v8ToMsgpack(v, &layer->zone);
}

Local<Value> LayerWrapper::msgpackToV8(const msgpack::object &o)
{
    return MsgpackToV8(o, [this](uint64_t id) -> Packet * {
        if (id == layer->packet->id) {
            return layer->packet;
        }
        return nullptr;
    });
}

class PacketWrapper
{
  public:
    PacketWrapper(Packet *packet);
    ~PacketWrapper();
    uint64_t id() const;
    uint32_t len() const;
    uint64_t ts_sec() const;
    uint32_t ts_nsec() const;
    Local<Value> ts() const;
    Local<Value> payload() const;

    void syncToScript();
    void syncFromScript();

    Local<Object> findLayer(const LayerPtr &layer) const;

  private:
    Packet *packet;
};

PacketWrapper::PacketWrapper(Packet *packet)
    : packet(packet)
{
}

PacketWrapper::~PacketWrapper()
{
}

uint64_t PacketWrapper::id() const
{
    return packet->id;
}

uint32_t PacketWrapper::len() const
{
    return packet->len;
}

uint64_t PacketWrapper::ts_sec() const
{
    return packet->ts_sec;
}

uint32_t PacketWrapper::ts_nsec() const
{
    return packet->ts_nsec;
}

Local<Value> PacketWrapper::ts() const
{
    return Date::New(Isolate::GetCurrent(), packet->ts_sec);
}

Local<Value> PacketWrapper::payload() const
{
    return v8pp::class_<Payload>::create_object(Isolate::GetCurrent(), &packet->payload, packet->id, 0, packet->payload.size());
}

void PacketWrapper::syncToScript()
{
    Isolate *isolate = Isolate::GetCurrent();
    std::map<std::string, Local<Value>> list;
    for (const auto &pair : packet->layers) {
        pair.second->packet = packet;
        Local<Object> obj = v8pp::class_<LayerWrapper>::create_object(isolate, pair.second);
        obj->ForceSet(v8pp::to_v8(isolate, "layers"), Object::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        obj->ForceSet(v8pp::to_v8(isolate, "fields"), Array::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        obj->ForceSet(v8pp::to_v8(isolate, "attrs"), Object::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        obj->ForceSet(v8pp::to_v8(isolate, "streams"), Array::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        LayerWrapper *wrapper = v8pp::class_<LayerWrapper>::unwrap_object(isolate, obj);
        wrapper->syncToScript();
        list[pair.first] = obj;
    }
    Local<Object> obj = v8pp::class_<PacketWrapper>::find_object(isolate, this);
    v8pp::set_const(isolate, obj, "layers", list);
}

void PacketWrapper::syncFromScript()
{
    Isolate *isolate = Isolate::GetCurrent();
    std::vector<Local<Value>> list;
    Local<Object> obj = v8pp::class_<PacketWrapper>::find_object(isolate, this);
    Local<Object> array = obj->Get(v8pp::to_v8(isolate, std::string("layers"))).As<Object>();
    packet->layers.clear();

    Local<Array> layerKeys = array->GetOwnPropertyNames();
    for (size_t i = 0; i < layerKeys->Length(); ++i) {
        LayerWrapper *wrapper = v8pp::class_<LayerWrapper>::unwrap_object(isolate, array->Get(layerKeys->Get(i)));
        const std::string &name = v8pp::from_v8<std::string>(isolate, layerKeys->Get(i), "");
        if (wrapper) {
            wrapper->getLayer()->packet = packet;
            wrapper->syncFromScript();
            packet->layers[name] = wrapper->getLayer();
        }
    }
}

Local<Object> PacketWrapper::findLayer(const LayerPtr &layer) const
{
    Isolate *isolate = Isolate::GetCurrent();
    Local<Object> obj = v8pp::class_<PacketWrapper>::find_object(isolate, this);
    Local<Object> array = obj->Get(v8pp::to_v8(isolate, std::string("layers"))).As<Object>();

    Local<Array> layerKeys = array->GetOwnPropertyNames();
    for (size_t i = 0; i < layerKeys->Length(); ++i) {
        LayerWrapper *wrapper = v8pp::class_<LayerWrapper>::unwrap_object(isolate, array->Get(layerKeys->Get(i)));
        if (wrapper) {
            Local<Object> value = wrapper->findLayer(layer);
            if (!value.IsEmpty())
                return value;
        }
    }
    return Local<Object>();
}

class ScriptClass::CreateParams : public Isolate::CreateParams
{
  public:
    CreateParams(ScriptClass::Private *d)
    {
        array_buffer_allocator = &d->allocator;
    }
};

ScriptClass::Private::Private(const msgpack::object &options)
    : isolate(Isolate::New(CreateParams(this))),
      options(options)
{
    Isolate::Scope isolate_scope(isolate);
    HandleScope handle_scope(isolate);
    context = UniquePersistent<Context>(isolate, Context::New(isolate));

    Context::Scope context_scope(Local<Context>::New(isolate, context));

    auto indexOperator = [](uint32_t index, const PropertyCallbackInfo<Value> &info) {
        Buffer *buffer = v8pp::class_<Buffer>::unwrap_object(Isolate::GetCurrent(), info.This());
        if (buffer) {
            buffer->get(index, info);
        }
    };

    v8pp::class_<Buffer> buffer(isolate);
    buffer
        .ctor<const FunctionCallbackInfo<Value> &>()
        .set("from", &Buffer::from)
        .set("isBuffer", &Buffer::isBuffer)
        .set("length", v8pp::property(&Buffer::length))
        .set("readInt8", &Buffer::readInt8)
        .set("readInt16BE", &Buffer::readInt16BE)
        .set("readInt32BE", &Buffer::readInt32BE)
        .set("readUInt8", &Buffer::readUInt8)
        .set("readUInt16BE", &Buffer::readUInt16BE)
        .set("readUInt32BE", &Buffer::readUInt32BE)
        .set("slice", &Buffer::slice)
        .set("equals", &Buffer::equals)
        .set("toString", &Buffer::toString)
        .set("valueOf", &Buffer::valueOf);

    buffer.class_function_template()->PrototypeTemplate()->SetIndexedPropertyHandler(indexOperator);

    v8pp::class_<CustomValue>(isolate)
        .inherit<Buffer>();

    v8pp::class_<Payload> payload(isolate);
    payload.inherit<Buffer>()
        .set("length", v8pp::property(&Buffer::length))
        .set("readInt8", &Buffer::readInt8)
        .set("readInt16BE", &Buffer::readInt16BE)
        .set("readInt32BE", &Buffer::readInt32BE)
        .set("readUInt8", &Buffer::readUInt8)
        .set("readUInt16BE", &Buffer::readUInt16BE)
        .set("readUInt32BE", &Buffer::readUInt32BE)
        .set("slice", &Payload::slice)
        .set("equals", &Buffer::equals)
        .set("toString", &Buffer::toString)
        .set("valueOf", &Payload::valueOf);

    payload.class_function_template()->PrototypeTemplate()->SetIndexedPropertyHandler(indexOperator);

    v8pp::class_<PacketWrapper>(isolate)
        .set("id", v8pp::property(&PacketWrapper::id))
        .set("len", v8pp::property(&PacketWrapper::len))
        .set("ts_sec", v8pp::property(&PacketWrapper::ts_sec))
        .set("ts_nsec", v8pp::property(&PacketWrapper::ts_nsec))
        .set("ts", v8pp::property(&PacketWrapper::ts))
        .set("payload", v8pp::property(&PacketWrapper::payload));

    v8pp::class_<LayerWrapper> layer(isolate);
    layer
        .ctor<>()
        .set("namespace", v8pp::property(&LayerWrapper::ns, &LayerWrapper::setNs))
        .set("name", v8pp::property(&LayerWrapper::name, &LayerWrapper::setName));

    layer.class_function_template()->SetClassName(v8pp::to_v8(isolate, "Layer"));

    v8pp::class_<NetStream> stream(isolate);
    stream
        .ctor<const std::string &, const std::string &, const std::string &>()
        .set("end", &NetStream::end)
        .set("name", &NetStream::name)
        .set("namespace", &NetStream::ns)
        .set("id", &NetStream::id);

    v8pp::module dripcapModule(isolate);
    dripcapModule.set("Buffer", buffer);
    dripcapModule.set("NetStream", stream);

    Local<FunctionTemplate> layerFunc = FunctionTemplate::New(isolate, [](FunctionCallbackInfo<Value> const &args) {
        Isolate *isolate = Isolate::GetCurrent();
        Local<Object> obj = args.Data().As<Function>()->NewInstance();
        obj->ForceSet(v8pp::to_v8(isolate, "layers"), Object::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        obj->ForceSet(v8pp::to_v8(isolate, "fields"), Array::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        obj->ForceSet(v8pp::to_v8(isolate, "attrs"), Object::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        obj->ForceSet(v8pp::to_v8(isolate, "streams"), Array::New(isolate), PropertyAttribute(ReadOnly | DontDelete));

        args.GetReturnValue().Set(obj);
    }, layer.js_function_template()->GetFunction());
    dripcapModule.set("Layer", layerFunc);

    dripcap = UniquePersistent<Object>(isolate, dripcapModule.new_instance());

    Local<FunctionTemplate> f = FunctionTemplate::New(isolate, [](FunctionCallbackInfo<Value> const &args) {
        Isolate *isolate = Isolate::GetCurrent();
        EscapableHandleScope scope(isolate);
        ScriptClass::Private *d = static_cast<ScriptClass::Private *>(args.Data().As<External>()->Value());

        const std::string &name = v8pp::from_v8<std::string>(isolate, args[0], "");

        if (name == "dripcap") {
            args.GetReturnValue().Set(Local<Object>::New(isolate, d->dripcap));
        } else {
            const auto &cache = d->moduleChache.find(name);
            if (cache != d->moduleChache.end()) {
                args.GetReturnValue().Set(Local<Function>::New(isolate, cache->second));
                return;
            }

            const auto &it = d->modules.find(name);
            if (it != d->modules.end()) {
                auto spd = spdlog::get("console");

                Local<Context> context = Context::New(isolate);
                context->SetSecurityToken(isolate->GetCurrentContext()->GetSecurityToken());

                Local<Value> exports;
                {
                    Context::Scope context_scope(context);
                    Local<Script> script = Local<UnboundScript>::New(isolate, it->second)->BindToCurrentContext();

                    TryCatch try_catch;
                    Local<Object> module = Object::New(isolate);
                    Local<Object> global = context->Global();
                    global->Set(v8pp::to_v8(isolate, "require"), Local<FunctionTemplate>::New(isolate, d->require)->GetFunction());
                    global->Set(v8pp::to_v8(isolate, "module"), module);

                    MaybeLocal<Value> maybeResult = script->Run(context);
                    if (maybeResult.IsEmpty()) {
                        String::Utf8Value err(try_catch.Exception());
                        spd->error("modules: {}", *err);
                    } else {
                        exports = module->Get(v8pp::to_v8(isolate, "exports"));
                    }

                    if (!exports.IsEmpty() && exports->IsFunction()) {
                        Local<Function> func = exports.As<Function>();
                        func->Set(v8pp::to_v8(isolate, "__msgpackClass"), v8pp::to_v8(isolate, name));
                        func->Set(v8pp::to_v8(isolate, "__esModule"), Boolean::New(isolate, true));
                        d->moduleChache[it->first] = UniquePersistent<Function>(isolate, func);
                        args.GetReturnValue().Set(exports);
                        return;
                    }
                }
            }

            std::string err("Cannot find module '");
            args.GetReturnValue().Set(v8pp::throw_ex(isolate, (err + name + "'").c_str()));
        }
    }, External::New(isolate, this));
    require = UniquePersistent<FunctionTemplate>(isolate, f);

    isolate->GetCurrentContext()->Global()->Set(
        v8pp::to_v8(isolate, "require"), f->GetFunction());

    v8pp::module console(isolate);
    console.set("error", [](FunctionCallbackInfo<Value> const &args) {
        auto spd = spdlog::get("console");
        for (size_t i = 0; i < args.Length(); ++i) {
            String::Utf8Value data(args[i]);
            spd->error("{}", *data);
        }
    });
    isolate->GetCurrentContext()->Global()->Set(
        v8::String::NewFromUtf8(isolate, "console"), console.new_instance());

    isolate->GetCurrentContext()->SetEmbedderData(1, External::New(isolate, this));
}

ScriptClass::Private::~Private()
{
    require.Reset();
    for (auto &pair : modules) {
        pair.second.Reset();
    }
    for (auto &pair : moduleChache) {
        pair.second.Reset();
    }
    dripcap.Reset();
    ctor.Reset();
    context.Reset();
    analyzerObject.Reset();
    isolate->Dispose();
}

ScriptClass::ScriptClass(const msgpack::object &options)
    : d(new Private(options))
{
}

ScriptClass::~ScriptClass()
{
    delete d;
}

bool ScriptClass::loadSource(const std::string &src, std::string *error)
{
    Isolate::Scope isolate_scope(d->isolate);
    HandleScope handle_scope(d->isolate);
    Local<Context> context = Local<Context>::New(d->isolate, d->context);
    Context::Scope context_scope(context);
    auto spd = spdlog::get("console");

    Local<String> source = v8pp::to_v8(d->isolate, src);

    TryCatch try_catch;
    MaybeLocal<Script> script = Script::Compile(context, source);
    if (script.IsEmpty()) {
        String::Utf8Value err(try_catch.Exception());
        if (error)
            error->assign(*err);
        spd->error("load: {}", *err);
        return false;
    }

    Local<Object> module = Object::New(d->isolate);
    context->Global()->Set(
        v8pp::to_v8(d->isolate, "module"), module);

    MaybeLocal<Value> maybeResult = script.ToLocalChecked()->Run(context);
    if (maybeResult.IsEmpty()) {
        String::Utf8Value err(try_catch.Exception());
        if (error)
            error->assign(*err);
        spd->error("load: {}", *err);
        return false;
    }

    Local<Value> result = module->Get(v8pp::to_v8(d->isolate, "exports"));
    if (result->IsFunction()) {
        d->ctor = UniquePersistent<Function>(d->isolate, result.As<Function>());
    }

    return true;
}

bool ScriptClass::loadFile(const std::string &path, std::string *error)
{
    auto spd = spdlog::get("console");
    spd->debug("load: {}", path);

    std::stringstream sstream;
    std::ifstream ifs;
    ifs.open(path.c_str(), std::ios::in);
    if (ifs) {
        sstream << ifs.rdbuf();
        ifs.close();
    } else {
        return false;
    }

    return loadSource(sstream.str(), error);
}

bool ScriptClass::loadModule(const std::string &name, const std::string &source, std::string *error)
{
    Isolate::Scope isolate_scope(d->isolate);
    HandleScope handle_scope(d->isolate);
    Local<Context> context = Local<Context>::New(d->isolate, d->context);
    Context::Scope context_scope(context);

    TryCatch try_catch;
    ScriptCompiler::Source src(v8pp::to_v8(d->isolate, source));
    MaybeLocal<UnboundScript> script = ScriptCompiler::CompileUnboundScript(d->isolate, &src);
    if (script.IsEmpty()) {
        String::Utf8Value err(try_catch.Exception());
        if (error)
            error->assign(*err);
        return false;
    }
    d->modules[name] = UniquePersistent<UnboundScript>(d->isolate, script.ToLocalChecked());
    return true;
}

bool ScriptClass::analyze(Packet *packet, const LayerPtr &parentLayer, std::string *error) const
{
    Isolate::Scope isolate_scope(d->isolate);
    HandleScope handle_scope(d->isolate);
    Local<Context> context = Local<Context>::New(d->isolate, d->context);
    Context::Scope context_scope(context);
    Local<Function> ctor = Local<Function>::New(d->isolate, d->ctor);

    TryCatch try_catch;
    MaybeLocal<Object> maybeObject;
    {
        Local<Value> args[1] = {Object::New(d->isolate)};
        if (args[0].IsEmpty()) {
            args[0] = Object::New(d->isolate);
        }
        maybeObject = ctor->NewInstance(context, 1, args);
        if (maybeObject.IsEmpty()) {
            String::Utf8Value err(try_catch.Exception());
            if (error)
                error->assign(*err);
            return false;
        }
    }

    Local<Object> obj = maybeObject.ToLocalChecked();
    Local<String> key = v8pp::to_v8(d->isolate, "analyze");

    Local<Value> maybeFunc = obj->Get(key);
    if (!maybeFunc->IsFunction()) {
        if (error)
            error->assign("analyze function needed");
        return false;
    }

    Local<Function> analyze_func = maybeFunc.As<Function>();
    {
        Local<Object> pkt = v8pp::class_<PacketWrapper>::create_object(d->isolate, packet);
        PacketWrapper *wrapper = v8pp::class_<PacketWrapper>::unwrap_object(d->isolate, pkt);
        wrapper->syncToScript();
        Local<Object> layer = wrapper->findLayer(parentLayer);

        Local<Value> args[2] = {pkt, layer};
        if (layer.IsEmpty()) {
            if (error)
                error->assign("wrong parentLayer instance");
            return false;
        }
        MaybeLocal<Value> maybeRes = analyze_func->Call(obj, 2, args);
        if (maybeRes.IsEmpty()) {
            String::Utf8Value err(try_catch.Exception());
            if (error)
                error->assign(*err);
            return false;
        }
        v8pp::class_<PacketWrapper>::unwrap_object(d->isolate, pkt)->syncFromScript();
    }

    return true;
}

bool ScriptClass::analyzeStream(Packet *packet, const LayerPtr &parentLayer, const msgpack::object &data, const PacketCallback &func, std::string *error) const
{
    Isolate::Scope isolate_scope(d->isolate);
    HandleScope handle_scope(d->isolate);
    Local<Context> context = Local<Context>::New(d->isolate, d->context);
    Context::Scope context_scope(context);
    Local<Function> ctor = Local<Function>::New(d->isolate, d->ctor);

    TryCatch try_catch;
    if (d->analyzerObject.IsEmpty()) {
        MaybeLocal<Object> maybeObject;
        {
            Local<Value> args[1] = {Object::New(d->isolate)};
            if (args[0].IsEmpty()) {
                args[0] = Object::New(d->isolate);
            }
            maybeObject = ctor->NewInstance(context, 1, args);
            if (maybeObject.IsEmpty()) {
                String::Utf8Value err(try_catch.Exception());
                if (error)
                    error->assign(*err);
                return false;
            }
        }
        d->analyzerObject = UniquePersistent<Object>(d->isolate, maybeObject.ToLocalChecked());
    }

    Local<Object> obj = Local<Object>::New(d->isolate, d->analyzerObject);
    Local<Value> maybeFunc = obj->Get(v8pp::to_v8(d->isolate, "analyze"));

    if (!maybeFunc->IsFunction()) {
        if (error)
            error->assign("analyze function needed");
        return false;
    }

    Local<Function> analyze_func = maybeFunc.As<Function>();
    {
        Local<Object> pkt = v8pp::class_<PacketWrapper>::create_object(d->isolate, packet);
        PacketWrapper *wrapper = v8pp::class_<PacketWrapper>::unwrap_object(d->isolate, pkt);
        wrapper->syncToScript();
        Local<Object> layer = wrapper->findLayer(parentLayer);
        Local<Array> array = Array::New(d->isolate);

        Local<Value> args[4] = {pkt, layer, MsgpackToV8(data, func), array};
        MaybeLocal<Value> maybeRes = analyze_func->Call(obj, 4, args);
        if (maybeRes.IsEmpty()) {
            String::Utf8Value err(try_catch.Exception());
            if (error)
                error->assign(*err);
            return false;
        }

        for (size_t i = 0; i < array->Length(); ++i) {

            Local<Object> stream = array->Get(i).As<Object>();
            NetStream *ns = v8pp::class_<NetStream>::unwrap_object(d->isolate, stream);
            if (ns) {
                Local<Value> data = stream->Get(v8pp::to_v8(d->isolate, std::string("data")));
                ns->data = v8ToMsgpack(data, &parentLayer->zone);
            }
        }

        v8pp::class_<PacketWrapper>::unwrap_object(d->isolate, pkt)->syncFromScript();
    }

    return true;
}

bool ScriptClass::filter(Packet *packet) const
{
    Isolate::Scope isolate_scope(d->isolate);
    HandleScope handle_scope(d->isolate);
    Local<Context> context = Local<Context>::New(d->isolate, d->context);
    Context::Scope context_scope(context);
    Local<Function> ctor = Local<Function>::New(d->isolate, d->ctor);

    Local<Object> pkt = v8pp::class_<PacketWrapper>::create_object(d->isolate, packet);
    PacketWrapper *wrapper = v8pp::class_<PacketWrapper>::unwrap_object(d->isolate, pkt);
    wrapper->syncToScript();

    TryCatch try_catch;
    Local<Value> args[1] = {pkt};
    MaybeLocal<Value> maybeRes = ctor->Call(context->Global(), 1, args);
    if (maybeRes.IsEmpty()) {
        String::Utf8Value err(try_catch.Exception());
        auto spd = spdlog::get("console");
        spd->error("errorx {}", *err);
        return false;
    }

    return maybeRes.ToLocalChecked()->BooleanValue();
}
