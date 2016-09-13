#ifndef BUFFER_HPP
#define BUFFER_HPP

#include "include/v8.h"
#include <iomanip>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

class Buffer
{
  public:
    typedef std::vector<unsigned char> Data;
    typedef std::shared_ptr<Data> DataPtr;

  public:
    Buffer(const DataPtr &holder);
    Buffer(Data *vec, size_t start, size_t end);
    explicit Buffer(const v8::FunctionCallbackInfo<v8::Value> &args);
    virtual ~Buffer();
    size_t length() const;

    void readInt8(const v8::FunctionCallbackInfo<v8::Value> &args) const;
    void readInt16BE(const v8::FunctionCallbackInfo<v8::Value> &args) const;
    void readInt32BE(const v8::FunctionCallbackInfo<v8::Value> &args) const;

    void readUInt8(const v8::FunctionCallbackInfo<v8::Value> &args) const;
    void readUInt16BE(const v8::FunctionCallbackInfo<v8::Value> &args) const;
    void readUInt32BE(const v8::FunctionCallbackInfo<v8::Value> &args) const;

    void get(uint32_t index, const v8::PropertyCallbackInfo<v8::Value> &info) const;
    void slice(const v8::FunctionCallbackInfo<v8::Value> &args) const;
    bool equals(const Buffer &buf) const;
    void toString(const v8::FunctionCallbackInfo<v8::Value> &args) const;
    int indexOf(const v8::FunctionCallbackInfo<v8::Value> &args) const;
    std::string valueOf() const;
    const unsigned char *data() const;
    std::pair<size_t, size_t> range() const;

  public:
    static void from(const v8::FunctionCallbackInfo<v8::Value> &args);
    static bool isBuffer(const v8::Local<v8::Value> &value);

  public:
    Buffer(Buffer const &) = delete;
    Buffer &operator=(Buffer const &) = delete;

  protected:
    std::pair<size_t, size_t> sliceRange(size_t start, size_t end) const;

  protected:
    DataPtr holder;
    Data *vec;
    size_t start;
    size_t end;
};

class CustomValue : public Buffer
{
  public:
    CustomValue(const DataPtr &holder);
    ~CustomValue();
};

class Payload : public Buffer
{
  public:
    Payload(Data *data, size_t start, size_t end);
    ~Payload();
    void slice(v8::FunctionCallbackInfo<v8::Value> const &args) const;
    std::string valueOf() const;
    size_t copy(Data *buf) const;
};

#endif
