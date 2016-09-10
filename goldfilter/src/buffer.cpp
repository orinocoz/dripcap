#include "buffer.hpp"
#include <cstring>
#include <v8pp/class.hpp>

using namespace v8;

Buffer::Buffer(const DataPtr &holder)
    : holder(holder), vec(holder.get()), start(0), end(holder->size())
{
}

Buffer::Buffer(Data *vec, size_t start, size_t end)
    : vec(vec), start(start), end(end)
{
}

Buffer::Buffer(const v8::FunctionCallbackInfo<v8::Value> &args)
    : holder(std::make_shared<Data>()), vec(holder.get()), start(0), end(holder->size())
{
    Isolate *isolate = Isolate::GetCurrent();

    if (args.Length() == 1) {
        Buffer *buffer;
        if ((buffer = v8pp::class_<Buffer>::unwrap_object(isolate, args[0]))) {
            Buffer::Data buf;
            holder->assign(buffer->data() + buffer->start, buffer->data() + (buffer->end - buffer->start));
        } else {
            const auto &array = v8pp::from_v8<std::vector<unsigned char>>(isolate, args[0], std::vector<unsigned char>());
            for (unsigned char c : array) {
                holder->push_back(c);
            }
        }
    } else if (args.Length() == 2) {
        const std::string &str = v8pp::from_v8<std::string>(isolate, args[0], "");
        const std::string &type = v8pp::from_v8<std::string>(isolate, args[1], "utf8");

        if (type == "utf8") {
            holder->assign(str.begin(), str.end());
        } else if (type == "hex") {
            try {
                if (str.size() % 2 != 0) {
                    throw std::invalid_argument("");
                }
                for (size_t i = 0; i < str.size() / 2; ++i) {
                    holder->push_back(std::stoul(str.substr(i * 2, 2), nullptr, 16));
                }
            } catch (const std::invalid_argument &e) {
                throw std::invalid_argument("Invalid hex string");
            }
        } else {
            std::string err("Unknown encoding: ");
            throw std::invalid_argument(err + type);
        }
    }

    end = holder->size();
}

Buffer::~Buffer()
{
}

size_t Buffer::length() const
{
    return end - start;
}

void Buffer::readInt8(const v8::FunctionCallbackInfo<v8::Value> &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t offset = v8pp::from_v8<size_t>(isolate, args[0], 0);
    bool noassert = v8pp::from_v8<bool>(isolate, args[1], true);
    if (!noassert && offset + sizeof(int8_t) > length()) {
        args.GetReturnValue().Set(v8pp::throw_ex(isolate, "index out of range"));
    } else {
        args.GetReturnValue().Set(v8pp::to_v8(isolate, Number::New(isolate, static_cast<int8_t>(vec->at(offset + start)))));
    }
}

void Buffer::readInt16BE(const v8::FunctionCallbackInfo<v8::Value> &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t offset = v8pp::from_v8<size_t>(isolate, args[0], 0);
    bool noassert = v8pp::from_v8<bool>(isolate, args[1], true);
    if (!noassert && offset + sizeof(int16_t) > length()) {
        args.GetReturnValue().Set(v8pp::throw_ex(isolate, "index out of range"));
    } else {
        const unsigned char buf[2] = {
            vec->at(0 + offset + start),
            vec->at(1 + offset + start)};
        int16_t num = (buf[0] << 8) | (buf[1] << 0);
        args.GetReturnValue().Set(v8pp::to_v8(isolate, Number::New(isolate, num)));
    }
}

void Buffer::readInt32BE(const v8::FunctionCallbackInfo<v8::Value> &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t offset = v8pp::from_v8<size_t>(isolate, args[0], 0);
    bool noassert = v8pp::from_v8<bool>(isolate, args[1], true);
    if (!noassert && offset + sizeof(int32_t) > length()) {
        args.GetReturnValue().Set(v8pp::throw_ex(isolate, "index out of range"));
    } else {
        const unsigned char buf[4] = {
            vec->at(0 + offset + start),
            vec->at(1 + offset + start),
            vec->at(2 + offset + start),
            vec->at(3 + offset + start)};
        int32_t num = (buf[0] << 24) | (buf[1] << 16) | (buf[2] << 8) | (buf[3] << 0);
        args.GetReturnValue().Set(v8pp::to_v8(isolate, Number::New(isolate, num)));
    }
}

void Buffer::readUInt8(const v8::FunctionCallbackInfo<v8::Value> &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t offset = v8pp::from_v8<size_t>(isolate, args[0], 0);
    bool noassert = v8pp::from_v8<bool>(isolate, args[1], true);
    if (!noassert && offset + sizeof(uint8_t) > length()) {
        args.GetReturnValue().Set(v8pp::throw_ex(isolate, "index out of range"));
    } else {
        args.GetReturnValue().Set(v8pp::to_v8(isolate, Number::New(isolate, vec->at(offset + start))));
    }
}

void Buffer::get(uint32_t index, const v8::PropertyCallbackInfo<v8::Value> &info) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t offset = index;
    if (offset + sizeof(uint8_t) > length()) {
        info.GetReturnValue().Set(v8pp::throw_ex(isolate, "index out of range"));
    } else {
        info.GetReturnValue().Set(v8pp::to_v8(isolate, Number::New(isolate, vec->at(offset + start))));
    }
}

void Buffer::readUInt16BE(const v8::FunctionCallbackInfo<v8::Value> &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t offset = v8pp::from_v8<size_t>(isolate, args[0], 0);
    bool noassert = v8pp::from_v8<bool>(isolate, args[1], true);
    if (!noassert && offset + sizeof(uint16_t) > length()) {
        args.GetReturnValue().Set(v8pp::throw_ex(isolate, "index out of range"));
    } else {
        const unsigned char buf[2] = {
            vec->at(0 + offset + start),
            vec->at(1 + offset + start)};
        uint16_t num = (buf[0] << 8) | (buf[1] << 0);
        args.GetReturnValue().Set(v8pp::to_v8(isolate, Number::New(isolate, num)));
    }
}

void Buffer::readUInt32BE(const v8::FunctionCallbackInfo<v8::Value> &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t offset = v8pp::from_v8<size_t>(isolate, args[0], 0);
    bool noassert = v8pp::from_v8<bool>(isolate, args[1], true);
    if (!noassert && offset + sizeof(uint32_t) > length()) {
        args.GetReturnValue().Set(v8pp::throw_ex(isolate, "index out of range"));
    } else {
        const unsigned char buf[4] = {
            vec->at(0 + offset + start),
            vec->at(1 + offset + start),
            vec->at(2 + offset + start),
            vec->at(3 + offset + start)};
        uint32_t num = (buf[0] << 24) | (buf[1] << 16) | (buf[2] << 8) | (buf[3] << 0);
        args.GetReturnValue().Set(v8pp::to_v8(isolate, Number::New(isolate, num)));
    }
}

void Buffer::slice(const v8::FunctionCallbackInfo<v8::Value> &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t s = v8pp::from_v8<size_t>(isolate, args[0], 0);
    size_t e = std::min(v8pp::from_v8<size_t>(isolate, args[1], length()), length());
    const auto &pair = sliceRange(s, e);
    Local<Object> obj = v8pp::class_<Buffer>::create_object(isolate, vec, pair.first, pair.second);
    args.GetReturnValue().Set(obj);
}

std::pair<size_t, size_t> Buffer::sliceRange(size_t s, size_t e) const
{
    return std::make_pair(std::min(start + s, end), start + std::min(std::max(s, e), length()));
}

bool Buffer::equals(const Buffer &buf) const
{
    return (length() == buf.length() && memcmp(vec->data(), buf.vec->data(), length()) == 0);
}

const unsigned char *Buffer::data() const
{
    return vec->data();
}

void Buffer::toString(const v8::FunctionCallbackInfo<v8::Value> &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    const std::string &type = v8pp::from_v8<std::string>(isolate, args[0], "utf8");

    if (type == "utf8") {
        const char *s = reinterpret_cast<const char *>(vec->data()) + start;
        args.GetReturnValue().Set(v8pp::to_v8(isolate, std::string(s, end - start)));
    } else if (type == "hex") {
        std::stringstream stream;
        for (size_t i = start; i < end; ++i) {
            stream << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(vec->at(i));
        }
        args.GetReturnValue().Set(v8pp::to_v8(isolate, stream.str()));
    } else {
        std::string err("Unknown encoding: ");
        args.GetReturnValue().Set(v8pp::throw_ex(isolate, (err + type).c_str()));
    }
}

std::string Buffer::valueOf() const
{
    size_t tail = std::min(start + 16, end);
    std::string str("<Buffer ");
    std::stringstream stream;
    for (size_t i = start; i < tail; ++i) {
        stream << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(vec->at(i)) << " ";
    }
    str += stream.str();
    if (end - start > 16)
        str += "...";
    return str + ">";
}

void Buffer::from(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    Local<Object> obj = v8pp::class_<Buffer>::create_object(Isolate::GetCurrent(), args);
    args.GetReturnValue().Set(obj);
}

bool Buffer::isBuffer(const v8::Local<v8::Value> &value)
{
    return v8pp::class_<Buffer>::unwrap_object(Isolate::GetCurrent(), value);
}

CustomValue::CustomValue(const DataPtr &holder)
    : Buffer(holder)
{
}

CustomValue::~CustomValue()
{
}

Payload::Payload(Data *data, size_t start, size_t end)
    : Buffer(data, start, end)
{
}

Payload::~Payload()
{
}

std::pair<size_t, size_t> Payload::range() const
{
    return std::make_pair(start, end);
}

std::string Payload::valueOf() const
{
    size_t tail = std::min(start + 16, end);
    std::string str("<Payload ");
    std::stringstream stream;
    for (size_t i = start; i < tail; ++i) {
        stream << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(vec->at(i)) << " ";
    }
    str += stream.str();
    if (end - start > 16)
        str += "...";
    return str + ">";
}

void Payload::slice(v8::FunctionCallbackInfo<v8::Value> const &args) const
{
    Isolate *isolate = Isolate::GetCurrent();
    size_t s = v8pp::from_v8<size_t>(isolate, args[0], 0);
    size_t e = std::min(v8pp::from_v8<size_t>(isolate, args[1], length()), length());
    const auto &pair = sliceRange(s, e);
    Local<Object> obj = v8pp::class_<Payload>::create_object(isolate, vec, pair.first, pair.second);
    args.GetReturnValue().Set(obj);
}

size_t Payload::copy(Data *buf) const
{
    buf->assign(data() + start, data() + end);
    return length();
}
