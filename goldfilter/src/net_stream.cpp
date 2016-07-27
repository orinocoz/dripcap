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

void NetStream::end()
{
    flag = STREAM_END;
}
