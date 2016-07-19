#include "net_stream.hpp"
#include <v8pp/class.hpp>

using namespace v8;

NetStream::NetStream(const std::string &name, const std::string &ns, const std::string &id)
    : name(name),
      ns(ns),
      id(id),
      flag(STREAM_NOOP)
{
}

NetStream::~NetStream()
{
}

void NetStream::start()
{
    flag = STREAM_START;
}

void NetStream::end()
{
    flag = STREAM_END;
}

void NetStream::insert(FunctionCallbackInfo<Value> const &args)
{
    Isolate *isolate = Isolate::GetCurrent();
    if (args.Length() < 2) {
        args.GetReturnValue().Set(v8pp::throw_ex(isolate, "insufficient arguments"));
    } else {
        uint64_t seq = v8pp::from_v8<uint64_t>(isolate, args[0], 0);
        Local<Value> val = args[1];
        Local<Object> obj;
        Local<Value> data = args.This()->Get(v8pp::to_v8(isolate, "_data"));
        if (data->IsObject()) {
            obj = data.As<Object>();
        } else {
            obj = Object::New(isolate);
        }
        obj->Set(seq, val);
        args.This()->Set(v8pp::to_v8(isolate, "_data"), obj);
    }
}
