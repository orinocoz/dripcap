#include "buffer_stream.hpp"
#include "buffer.hpp"
#include <leveldb/db.h>
#include <random>
#include <sstream>
#include <v8pp/class.hpp>

using namespace v8;

class BufferStream::Private
{
  public:
    Private(const std::string &id = std::string());
    ~Private();
    std::string indexID(uint64_t index) const;
    uint64_t chunks() const;
    void setChunks(uint64_t chunks);
    uint64_t length() const;
    void setLength(uint64_t length);

  public:
    std::string id;
    uint64_t index;
    leveldb::DB *db;
};

BufferStream::Private::Private(const std::string &id)
    : id(id), index(0), db(nullptr)
{
    if (id.empty()) {
        std::random_device rd;
        std::mt19937_64 gen(rd());
        std::uniform_int_distribution<unsigned char> dist;

        std::stringstream idStream;
        for (size_t i = 0; i < 18; ++i) {
            idStream << std::hex << std::setfill('0') << std::setw(2) << static_cast<int>(dist(gen));
        }
        this->id = idStream.str();
    }
}

BufferStream::Private::~Private()
{
}

uint64_t BufferStream::Private::chunks() const
{
    if (db) {
        const std::string &keyBuffer = id + ".chunks";
        std::string value;
        leveldb::Slice key(keyBuffer.data(), keyBuffer.size());
        leveldb::Status s = db->Get(leveldb::ReadOptions(), key, &value);
        if (s.ok() && value.size() == sizeof(uint64_t)) {
            return *reinterpret_cast<const uint64_t *>(value.data());
        }
    }
    return 0;
}

void BufferStream::Private::setChunks(uint64_t chunks)
{
    if (db) {
        const std::string &keyBuffer = id + ".chunks";
        leveldb::Slice key(keyBuffer.data(), keyBuffer.size());
        leveldb::Slice value(reinterpret_cast<const char *>(&chunks), sizeof(chunks));
        db->Put(leveldb::WriteOptions(), key, value);
    }
}

uint64_t BufferStream::Private::length() const
{
    if (db) {
        const std::string &keyBuffer = id + ".length";
        std::string value;
        leveldb::Slice key(keyBuffer.data(), keyBuffer.size());
        leveldb::Status s = db->Get(leveldb::ReadOptions(), key, &value);
        if (s.ok() && value.size() == sizeof(uint64_t)) {
            return *reinterpret_cast<const uint64_t *>(value.data());
        }
    }
    return 0;
}

void BufferStream::Private::setLength(uint64_t length)
{
    if (db) {
        const std::string &keyBuffer = id + ".length";
        leveldb::Slice key(keyBuffer.data(), keyBuffer.size());
        leveldb::Slice value(reinterpret_cast<const char *>(&length), sizeof(length));
        leveldb::Status s = db->Put(leveldb::WriteOptions(), key, value);
    }
}

std::string BufferStream::Private::indexID(uint64_t index) const
{
    std::string key;
    key.resize(sizeof(uint64_t));
    *reinterpret_cast<uint64_t *>(&key[0]) = index;
    key += id;
    return key;
}

BufferStream::BufferStream()
    : d(new Private())
{
}

BufferStream::BufferStream(const std::string &id)
    : d(new Private(id))
{
}

BufferStream::~BufferStream()
{
    delete d;
}

void BufferStream::write(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    Isolate *isolate = Isolate::GetCurrent();
    bool ok = false;
    Buffer *buffer;
    Payload *payload;
    uint64_t chunks = d->chunks();
    uint64_t length = d->length();
    if ((payload = v8pp::class_<Payload>::unwrap_object(isolate, args[0]))) {
        const std::pair<size_t, size_t> &range = payload->range();
        size_t len = range.second - range.first;
        if (len > 0) {
            const std::string &keyBuffer = d->indexID(chunks);
            leveldb::Slice key(keyBuffer.data(), keyBuffer.size());
            leveldb::Slice value(reinterpret_cast<const char *>(payload->data() + range.first), len);
            d->db->Put(leveldb::WriteOptions(), key, value);
            chunks++;
            length += len;
        }
        ok = true;
    } else if ((buffer = v8pp::class_<Buffer>::unwrap_object(isolate, args[0]))) {
        if (buffer->length() > 0) {
            const std::string &keyBuffer = d->indexID(chunks);
            leveldb::Slice key(keyBuffer.data(), keyBuffer.size());
            leveldb::Slice value(reinterpret_cast<const char *>(buffer->data()), buffer->length());
            d->db->Put(leveldb::WriteOptions(), key, value);
            chunks++;
            length += buffer->length();
        }
        ok = true;
    }
    if (ok) {
        d->setChunks(chunks);
        d->setLength(length);
    }
    args.GetReturnValue().Set(v8pp::to_v8(isolate, Boolean::New(isolate, ok)));
}

void BufferStream::read(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    Isolate *isolate = Isolate::GetCurrent();
    const std::string &keyBuffer = d->indexID(d->index);
    leveldb::Slice key(keyBuffer.data(), keyBuffer.size());
    std::string value;
    leveldb::Status s = d->db->Get(leveldb::ReadOptions(), key, &value);
    if (s.ok()) {
        d->index++;
        auto vec = std::make_shared<Buffer::Data>();
        vec->assign(value.data(), value.data() + value.size());
        args.GetReturnValue().Set(v8pp::to_v8(isolate, v8pp::class_<Buffer>::create_object(isolate, vec)));
    } else {
        args.GetReturnValue().Set(Null(isolate));
    }
}

std::string BufferStream::id() const
{
    return d->id;
}

uint64_t BufferStream::length() const
{
    return d->length();
}

void BufferStream::setDB(leveldb::DB *db)
{
    d->db = db;
}
