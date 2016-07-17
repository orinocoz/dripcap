#ifndef STREAM_HPP
#define STREAM_HPP

#include <msgpack.hpp>

enum StreamFlag {
    STREAM_NOOP,
    STREAM_BEGIN,
    STREAM_END,
};

MSGPACK_ADD_ENUM(StreamFlag);

class Stream
{
  public:
    Stream() = default;
    Stream(const Stream &) = default;
    Stream(const std::string &name, const std::string &ns, const std::string &id);
    ~Stream();

  public:
    std::string name;
    std::string ns;
    std::string id;
    std::map<uint64_t, msgpack::object> data;
    StreamFlag flag;

    MSGPACK_DEFINE_MAP(name, ns, id, data, flag);
};

#endif
