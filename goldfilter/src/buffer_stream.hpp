#ifndef BUFFER_STREAM_HPP
#define BUFFER_STREAM_HPP

#include "include/v8.h"
#include <msgpack.hpp>

namespace rocksdb
{
class DB;
}

class BufferStream
{
  public:
    BufferStream();
    BufferStream(const std::string &id);
    virtual ~BufferStream();
    void write(const v8::FunctionCallbackInfo<v8::Value> &args);
    void read(const v8::FunctionCallbackInfo<v8::Value> &args);

    std::string id() const;
    uint64_t length() const;
    void setDB(rocksdb::DB *db);

  private:
    class Private;
    Private *d;
};

#endif
