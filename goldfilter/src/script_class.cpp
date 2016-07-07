#include "script_class.hpp"
#include "buffer.hpp"
#include <fstream>
#include <sstream>
#include <spdlog/spdlog.h>
#include "packet.hpp"
#include "include/libplatform/libplatform.h"
#include "include/v8.h"
#include <v8pp/class.hpp>
#include <v8pp/object.hpp>
#include <v8pp/module.hpp>
#include <v8pp/function.hpp>

using namespace v8;

namespace
{

Local<Value> MsgpackToV8(const msgpack::object &o, Packet *packet = nullptr)
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
            array->Set(i, MsgpackToV8(objs[i], packet));
        }
        return array;
    }
    case msgpack::type::MAP: {
        Local<Object> obj = Object::New(isolate);
        const auto &map = o.as<std::unordered_map<std::string, msgpack::object>>();
        for (const auto &pair : map) {
            obj->Set(v8pp::to_v8(isolate, pair.first), MsgpackToV8(pair.second, packet));
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
            }
            case 0x1f: {
                if (packet) {
                    msgpack::object_handle result;
                    msgpack::unpack(result, ext.data(), ext.size());
                    msgpack::object obj(result.get());
                    const auto &pair = obj.as<std::pair<size_t, size_t>>();
                    return v8pp::class_<Payload>::create_object(isolate, &packet->payload, pair.first, pair.second);
                }
            }
            case 0x20: {
                msgpack::object_handle result;
                msgpack::unpack(result, ext.data(), ext.size());
                msgpack::object obj(result.get());
                Local<Value> v = MsgpackToV8(obj, packet);
                if (!v.IsEmpty() && v->IsArray()) {
                    Local<Array> array = v.As<Array>();
                    if (array->Length() > 0) {
                        Local<Value> name = array->Get(0);
                        if (name->IsString()) {
                            Local<Context> ctx = isolate->GetCurrentContext();
                            Local<Value> registerd = ctx->GetEmbedderData(0);
                            if (!registerd.IsEmpty() && registerd->IsObject()) {
                                Local<Value> func = registerd.As<Object>()->Get(name.As<String>());
                                if (func->IsFunction()) {
                                    std::vector<Handle<Value>> args;
                                    for (size_t i = 1; i < array->Length(); ++i) {
                                        args.push_back(array->Get(i));
                                    }
                                    TryCatch try_catch;
                                    Local<Object> obj = func.As<Function>()->NewInstance(args.size(), args.data());
                                    if (obj.IsEmpty()) {
                                        String::Utf8Value err(try_catch.Exception());
                                        auto spd = spdlog::get("console");
                                        spd->error("{}", *err);
                                    } else {
                                        return obj;
                                    }
                                }
                            }
                        }
                    }
                }
            }
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
        "ns", "name", "layers", "payload"};
    Local<Array> extKeys = obj->GetOwnPropertyNames();
    for (size_t i = 0; i < extKeys->Length(); ++i) {
        const std::string &name = v8pp::from_v8<std::string>(isolate, extKeys->Get(i), "");
        if (reserved.count(name) == 0) {
            layer->ext[name] = v8ToMsgpack(obj->Get(extKeys->Get(i)));
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
        if (wrapper && wrapper->layer == finding) {
            return layer.As<Object>();
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
    Isolate *isolate = Isolate::GetCurrent();
    if (!v.IsEmpty()) {
        Payload *payload;
        if ((payload = v8pp::class_<Payload>::unwrap_object(isolate, v))) {
            std::stringstream buffer;
            msgpack::pack(buffer, payload->range());
            const std::string &str = buffer.str();
            return msgpack::object(msgpack::type::ext(0x1f, str.data(), str.size()), layer->zone);
        }

        CustomValue *custom;
        if ((custom = v8pp::class_<CustomValue>::unwrap_object(isolate, v))) {
            return msgpack::object(msgpack::type::ext(0x20, reinterpret_cast<const char *>(custom->data()), custom->length()), layer->zone);
        }

        Buffer *buffer;
        if ((buffer = v8pp::class_<Buffer>::unwrap_object(isolate, v))) {
            Buffer::Data buf;
            buf.assign(buffer->data(), buffer->data() + buffer->length());
            return msgpack::object(buf, layer->zone);
        }

        if (v->IsString()) {
            Local<String> strObj = v.As<String>();
            std::string str;
            str.resize(strObj->Utf8Length() + 1);
            strObj->WriteUtf8(&str[0]);
            str.resize(str.size() - 1);
            return msgpack::object(str, layer->zone);
        }

        if (v->IsArray()) {
            std::vector<msgpack::object> list;
            Local<Array> array = v.As<Array>();
            for (size_t i = 0; i < array->Length(); ++i) {
                list.push_back(v8ToMsgpack(array->Get(i)));
            }
            return msgpack::object(list, layer->zone);
        }

        if (v->IsBoolean()) {
            return msgpack::object(v.As<Boolean>()->Value());
        }

        if (v->IsNumber()) {
            return msgpack::object(v.As<Number>()->Value());
        }

        if (v->IsObject()) {
            Local<Object> obj = v.As<Object>();
            Local<Value> f = obj->Get(v8pp::to_v8(isolate, std::string("toMsgpack")));
            if (f->IsFunction()) {
                const msgpack::object &obj = v8ToMsgpack(f.As<Function>()->Call(v, 0, nullptr));
                std::stringstream buffer;
                msgpack::pack(buffer, obj);
                const std::string &str = buffer.str();
                return msgpack::object(msgpack::type::ext(0x20, str.data(), str.size()), layer->zone);
            }

            std::unordered_map<std::string, msgpack::object> map;
            Local<Array> keys = obj->GetOwnPropertyNames();
            for (size_t i = 0; i < keys->Length(); ++i) {
                map[v8pp::from_v8<std::string>(isolate, keys->Get(i), "")] = v8ToMsgpack(obj->Get(keys->Get(i)));
            }
            return msgpack::object(map, layer->zone);
        }
    }
    return msgpack::object(msgpack::type::nil_t());
}

Local<Value> LayerWrapper::msgpackToV8(const msgpack::object &o)
{
    return MsgpackToV8(o, layer->packet);
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
    return v8pp::class_<Payload>::create_object(Isolate::GetCurrent(), &packet->payload, 0, packet->payload.size());
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
    msgpack::object options;
};

ScriptClass::Private::Private(const msgpack::object &options)
    : options(options)
{
    Isolate::CreateParams create_params;
    create_params.array_buffer_allocator = &allocator;
    isolate = Isolate::New(create_params);

    Isolate::Scope isolate_scope(isolate);
    HandleScope handle_scope(isolate);
    context = UniquePersistent<Context>(isolate, Context::New(isolate));

    Context::Scope context_scope(Local<Context>::New(isolate, context));

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

    v8pp::class_<CustomValue>(isolate)
        .inherit<Buffer>();

    v8pp::class_<Payload>(isolate)
        .inherit<Buffer>()
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

    v8pp::module dripcapModule(isolate);
    dripcapModule.set("Buffer", buffer);

    Local<FunctionTemplate> layerFunc = FunctionTemplate::New(isolate, [](FunctionCallbackInfo<Value> const &args) {
        Isolate *isolate = Isolate::GetCurrent();
        Local<Object> obj = args.Data().As<Function>()->NewInstance();
        obj->ForceSet(v8pp::to_v8(isolate, "layers"), Object::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        obj->ForceSet(v8pp::to_v8(isolate, "fields"), Array::New(isolate), PropertyAttribute(ReadOnly | DontDelete));
        obj->ForceSet(v8pp::to_v8(isolate, "attrs"), Object::New(isolate), PropertyAttribute(ReadOnly | DontDelete));

        args.GetReturnValue().Set(obj);
    }, layer.js_function_template()->GetFunction());
    dripcapModule.set("Layer", layerFunc);

    Local<Object> dripcap = dripcapModule.new_instance();
    Local<FunctionTemplate> f = FunctionTemplate::New(isolate, [](FunctionCallbackInfo<Value> const &args) {
        Isolate *isolate = Isolate::GetCurrent();
        const std::string &name = v8pp::from_v8<std::string>(isolate, args[0], "");
        Local<Object> obj = args.Data().As<Object>();

        if (name == "dripcap") {
            args.GetReturnValue().Set(obj);
        } else {
            Local<Context> ctx = isolate->GetCurrentContext();
            //Local<Value> internal = obj->GetHiddenValue(v8pp::to_v8(isolate, "0"));
            Local<Value> internal = ctx->Global()->Get(
                v8pp::to_v8(isolate, "__module"));
            if (!internal.IsEmpty() && internal->IsObject()) {
                Local<Value> module = internal.As<Object>()->Get(v8pp::to_v8(isolate, name));
                    auto spd = spdlog::get("console");
                        String::Utf8Value ex(module);
                spd->error("mod_registerc: {} {}", name, *ex);
                if (!module.IsEmpty()) {
                    args.GetReturnValue().Set(module);
                    return;
                }
            }
            std::string err("Cannot find module '");
            args.GetReturnValue().Set(v8pp::throw_ex(isolate, (err + name + "'").c_str()));
        }
    }, dripcap);

    isolate->GetCurrentContext()->Global()->Set(
        v8pp::to_v8(isolate, "require"), f->GetFunction());

    auto spd = spdlog::get("console");
    try {
        const auto &map = options.as<std::unordered_map<std::string, msgpack::object>>();
        const auto &modules = map.at("modules").as<std::unordered_map<std::string, std::string>>();

        for (const auto &pair : modules) {
            Local<String> source = v8pp::to_v8(isolate, pair.second);
            Local<Context> context = Context::New(isolate);
            Context::Scope context_scope(context);
            TryCatch try_catch;
            MaybeLocal<Script> script = Script::Compile(context, source);
            if (script.IsEmpty()) {
                String::Utf8Value err(try_catch.Exception());
                spd->error("modules: {}", *err);
                continue;
            }

            Local<Object> module = Object::New(isolate);
            context->Global()->Set(
                v8pp::to_v8(isolate, "require"), f->GetFunction());
            context->Global()->Set(
                v8pp::to_v8(isolate, "module"), module);

            MaybeLocal<Value> maybeResult = script.ToLocalChecked()->Run(context);
            if (maybeResult.IsEmpty()) {
                String::Utf8Value err(try_catch.Exception());
                spd->error("modules: {}", *err);
                continue;
            }

            Local<Value> exports = module->Get(v8pp::to_v8(isolate, "exports"));
            Local<Value> registerd = context->GetEmbedderData(0);
            if (registerd.IsEmpty() || !registerd->IsObject()) {
                registerd = Object::New(isolate);
            }
                String::Utf8Value ex(exports);
            spd->error("mod_registerr: {} {}", pair.first, *ex);
            registerd.As<Object>()->Set(v8pp::to_v8(isolate, pair.first), exports);
            context->SetEmbedderData(0, registerd);
            //dripcap->SetHiddenValue(v8pp::to_v8(isolate, "0"), registerd);
            context->Global()->Set(
                v8pp::to_v8(isolate, "__module"), registerd);
        }
    } catch (const std::bad_cast &err) {
        spd->error("modules: {}", err.what());
    }
}

ScriptClass::Private::~Private()
{
    ctor.Reset();
    context.Reset();
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
        spd->error("error {}", *err);
        return false;
    }

    return maybeRes.ToLocalChecked()->BooleanValue();
}
