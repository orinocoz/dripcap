#include "packet_stream.hpp"
#include <v8pp/class.hpp>

using namespace v8;

PacketStream::PacketStream(const std::string &name, const std::string &ns, const std::string &id)
    : name(name),
      ns(ns),
      id(id),
      flag(STREAM_NOOP)
{
}

PacketStream::~PacketStream()
{
}

void PacketStream::end()
{
    flag = STREAM_END;
}
