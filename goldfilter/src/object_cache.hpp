#ifndef OBJECT_CACHE_HPP
#define OBJECT_CACHE_HPP

#include <leveldb/db.h>
#include <leveldb/comparator.h>
#include <spdlog/spdlog.h>
#include <string>

template <class K>
class CacheComparator : public leveldb::Comparator
{
  public:
    CacheComparator();
    ~CacheComparator() override;
    leveldb::Slice slice(const K &id) const;
    int Compare(const leveldb::Slice &a, const leveldb::Slice &b) const override;
    const char *Name() const override;
    void FindShortestSeparator(std::string *start, const leveldb::Slice &limit) const override;
    void FindShortSuccessor(std::string *key) const override;
};

template <class K>
CacheComparator<K>::CacheComparator()
{
}

template <class K>
CacheComparator<K>::~CacheComparator()
{
}

template <class K>
leveldb::Slice CacheComparator<K>::slice(const K &id) const
{
    return leveldb::Slice(reinterpret_cast<const char *>(&id), sizeof(id));
}

template <class K>
int CacheComparator<K>::Compare(const leveldb::Slice &a, const leveldb::Slice &b) const
{
    return *reinterpret_cast<const uint64_t *>(a.data()) - *reinterpret_cast<const uint64_t *>(b.data());
}

template <class K>
const char *CacheComparator<K>::Name() const
{
    return "dripcap";
}

template <class K>
void CacheComparator<K>::FindShortestSeparator(std::string *start, const leveldb::Slice &limit) const
{
}

template <class K>
void CacheComparator<K>::FindShortSuccessor(std::string *key) const
{
}

template <>
leveldb::Slice CacheComparator<std::string>::slice(const std::string &id) const
{
    return leveldb::Slice(id.data(), id.size());
}

template <>
int CacheComparator<std::string>::Compare(const leveldb::Slice &a, const leveldb::Slice &b) const
{
    return a.compare(b);
}

template <class K, class V>
class ObjectCache
{
  public:
    ObjectCache(const std::string &path);
    V get(const K &id) const;
    bool has(const K &id) const;
    void set(const K &id, const V &obj);
    void remove(const K &id);

  private:
    void insert(const K &id, const V &obj) const;

  private:
    std::unique_ptr<CacheComparator<K>> comp;
    std::unique_ptr<leveldb::DB> db;

    mutable int cacheIndex;
    mutable std::array<K, 1024> cacheBuffer;
    mutable std::unordered_map<K, V> cache;
    mutable std::mutex mutex;
    mutable msgpack::zone zone;
};

template <class K, class V>
ObjectCache<K, V>::ObjectCache(const std::string &path)
    : comp(new CacheComparator<K>()),
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

template <class K, class V>
V ObjectCache<K, V>::get(const K &id) const
{
    {
        std::lock_guard<std::mutex> lock(mutex);
        const auto &it = cache.find(id);
        if (it != cache.end()) {
            return it->second;
        }
    }
    const leveldb::Slice &key = comp->slice(id);
    std::string value;
    leveldb::Status s = db->Get(leveldb::ReadOptions(), key, &value);
    if (s.ok()) {
        msgpack::object_handle result;
        msgpack::unpack(result, value.data(), value.size());
        msgpack::object obj(result.get(), zone);
        const V &ptr = obj.as<V>();
        insert(id, ptr);
        return ptr;
    }
    return V();
}

template <class K, class V>
bool ObjectCache<K, V>::has(const K &id) const
{
    {
        std::lock_guard<std::mutex> lock(mutex);
        const auto &it = cache.find(id);
        if (it != cache.end()) {
            return true;
        }
    }
    const leveldb::Slice &key = comp->slice(id);
    std::string value;
    leveldb::ReadOptions option;
    option.fill_cache = false;
    leveldb::Status s = db->Get(option, key, &value);
    return s.ok();
}

template <class K, class V>
void ObjectCache<K, V>::set(const K &id, const V &obj)
{
    std::stringstream buffer;
    msgpack::pack(buffer, obj);
    const leveldb::Slice &key = comp->slice(id);
    leveldb::Status s = db->Put(leveldb::WriteOptions(), key, buffer.str());
    insert(id, obj);
}

template <class K, class V>
void ObjectCache<K, V>::remove(const K &id)
{
    const leveldb::Slice &key = comp->slice(id);
    db->Delete(leveldb::WriteOptions(), key);
    cache.erase(id);
}

template <class K, class V>
void ObjectCache<K, V>::insert(const K &id, const V &obj) const
{
    std::lock_guard<std::mutex> lock(mutex);
    const K &cacheId = cacheBuffer[cacheIndex];
    cache.erase(cacheId);
    cacheBuffer[cacheIndex] = id;
    cacheIndex = (cacheIndex + 1) % cacheBuffer.size();
    cache[id] = obj;
}

#endif
