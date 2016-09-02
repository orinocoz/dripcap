#ifndef OBJECT_CACHE_HPP
#define OBJECT_CACHE_HPP

#include <leveldb/db.h>
#include <leveldb/comparator.h>
#include <spdlog/spdlog.h>

template <class T>
class ObjectCache
{
  private:
    class Comparator : public leveldb::Comparator
    {
      public:
        Comparator();
        ~Comparator() override;
        int Compare(const leveldb::Slice &a, const leveldb::Slice &b) const override;
        const char *Name() const override;
        void FindShortestSeparator(std::string *start, const leveldb::Slice &limit) const override;
        void FindShortSuccessor(std::string *key) const override;
    };

  public:
    ObjectCache(const std::string &path);
    T get(uint64_t id) const;
    bool has(uint64_t id) const;
    void set(uint64_t id, const T &obj);

  private:
    void insert(uint64_t id, const T &obj) const;

  private:
    std::unique_ptr<Comparator> comp;
    std::unique_ptr<leveldb::DB> db;

    mutable int cacheIndex;
    mutable std::array<uint64_t, 128> cacheBuffer;
    mutable std::unordered_map<uint64_t, T> cache;
    mutable std::mutex mutex;
};

template <class T>
ObjectCache<T>::Comparator::Comparator()
{
}

template <class T>
ObjectCache<T>::Comparator::~Comparator()
{
}

template <class T>
int ObjectCache<T>::Comparator::Compare(const leveldb::Slice &a, const leveldb::Slice &b) const
{
    return *reinterpret_cast<const uint64_t *>(a.data()) - *reinterpret_cast<const uint64_t *>(b.data());
}

template <class T>
const char *ObjectCache<T>::Comparator::Name() const
{
    return "dripcap";
}

template <class T>
void ObjectCache<T>::Comparator::FindShortestSeparator(std::string *start, const leveldb::Slice &limit) const
{
}

template <class T>
void ObjectCache<T>::Comparator::FindShortSuccessor(std::string *key) const
{
}

template <class T>
ObjectCache<T>::ObjectCache(const std::string &path)
    : comp(new Comparator()),
      cacheIndex(0),
      cacheBuffer({})
{
    leveldb::DB *leveldb = nullptr;
    leveldb::Options options;
    options.create_if_missing = true;
    options.comparator = comp.get();
    leveldb::Status status = leveldb::DB::Open(options, path + ".leveldb", &leveldb);
    if (!status.ok()) {
        spdlog::get("console")->error("{}", status.ToString());
    }
    db.reset(leveldb);
}

template <class T>
T ObjectCache<T>::get(uint64_t id) const
{
    {
        std::lock_guard<std::mutex> lock(mutex);
        const auto &it = cache.find(id);
        if (it != cache.end()) {
            return it->second;
        }
    }
    leveldb::Slice key(reinterpret_cast<const char *>(&id), sizeof(id));
    std::string value;
    leveldb::Status s = db->Get(leveldb::ReadOptions(), key, &value);
    if (s.ok()) {
        msgpack::object_handle result;
        msgpack::unpack(result, value.data(), value.size());
        msgpack::object obj(result.get());
        const T &ptr = obj.as<T>();
        insert(id, ptr);
        return ptr;
    }
    return PacketPtr();
}

template <class T>
bool ObjectCache<T>::has(uint64_t id) const
{
    {
        std::lock_guard<std::mutex> lock(mutex);
        const auto &it = cache.find(id);
        if (it != cache.end()) {
            return true;
        }
    }
    leveldb::Slice key(reinterpret_cast<const char *>(&id), sizeof(id));
    std::string value;
    leveldb::ReadOptions option;
    option.fill_cache = false;
    leveldb::Status s = db->Get(option, key, &value);
    return s.ok();
}

template <class T>
void ObjectCache<T>::set(uint64_t id, const T &obj)
{
    if (!obj) {
        return;
    }
    std::stringstream buffer;
    msgpack::pack(buffer, obj);
    leveldb::Slice key(reinterpret_cast<const char *>(&id), sizeof(id));
    leveldb::Status s = db->Put(leveldb::WriteOptions(), key, buffer.str());
    insert(id, obj);
}

template <class T>
void ObjectCache<T>::insert(uint64_t id, const T &obj) const
{
    std::lock_guard<std::mutex> lock(mutex);
    uint64_t cacheId = cacheBuffer[cacheIndex];
    if (cacheId > 0) {
        cache.erase(cacheId);
    }
    cacheBuffer[cacheIndex] = id;
    cacheIndex = (cacheIndex + 1) % cacheBuffer.size();
    cache[id] = obj;
}

#endif
