#ifndef OBJECT_CACHE_HPP
#define OBJECT_CACHE_HPP

#include <rocksdb/comparator.h>
#include <rocksdb/db.h>
#include <spdlog/spdlog.h>
#include <sstream>
#include <string>

template <class K>
class CacheComparator : public rocksdb::Comparator
{
  public:
    CacheComparator();
    ~CacheComparator() override;
    rocksdb::Slice slice(const K &id) const;
    int Compare(const rocksdb::Slice &a, const rocksdb::Slice &b) const override;
    const char *Name() const override;
    void FindShortestSeparator(std::string *start, const rocksdb::Slice &limit) const override;
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
rocksdb::Slice CacheComparator<K>::slice(const K &id) const
{
    return rocksdb::Slice(reinterpret_cast<const char *>(&id), sizeof(id));
}

template <class K>
int CacheComparator<K>::Compare(const rocksdb::Slice &a, const rocksdb::Slice &b) const
{
    return *reinterpret_cast<const uint64_t *>(a.data()) - *reinterpret_cast<const uint64_t *>(b.data());
}

template <class K>
const char *CacheComparator<K>::Name() const
{
    return "dripcap";
}

template <class K>
void CacheComparator<K>::FindShortestSeparator(std::string *start, const rocksdb::Slice &limit) const
{
}

template <class K>
void CacheComparator<K>::FindShortSuccessor(std::string *key) const
{
}

template <>
rocksdb::Slice CacheComparator<std::string>::slice(const std::string &id) const
{
    return rocksdb::Slice(id.data(), id.size());
}

template <>
int CacheComparator<std::string>::Compare(const rocksdb::Slice &a, const rocksdb::Slice &b) const
{
    return a.compare(b);
}

template <class K, class V>
class ObjectCache
{
  public:
    ObjectCache(const std::string &path);
    ~ObjectCache();
    V get(const K &id) const;
    bool has(const K &id) const;
    void set(const K &id, const V &obj);
    void remove(const K &id);

  private:
    void insert(const K &id, const V &obj) const;

  private:
    std::unique_ptr<CacheComparator<K>> comp;
    std::unique_ptr<rocksdb::DB> db;
    std::string path;

    mutable int cacheIndex;
    mutable std::array<K, 1024> cacheBuffer;
    mutable std::unordered_map<K, V> cache;
    mutable std::mutex mutex;
    mutable msgpack::zone zone;
};

template <class K, class V>
ObjectCache<K, V>::ObjectCache(const std::string &path)
    : comp(new CacheComparator<K>()),
      path(path),
      cacheIndex(0),
      cacheBuffer({})
{
    rocksdb::DB *rocksdb = nullptr;
    rocksdb::Options options;
    options.create_if_missing = true;
    options.comparator = comp.get();
    rocksdb::Status status = rocksdb::DB::Open(options, path + ".rocksdb", &rocksdb);
    if (!status.ok()) {
        spdlog::get("console")->error("{}", status.ToString());
    }
    db.reset(rocksdb);
}

template <class K, class V>
ObjectCache<K, V>::~ObjectCache()
{
    db.reset();
    rocksdb::DestroyDB(path, rocksdb::Options());
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
    const rocksdb::Slice &key = comp->slice(id);
    std::string value;
    rocksdb::Status s = db->Get(rocksdb::ReadOptions(), key, &value);
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
    const rocksdb::Slice &key = comp->slice(id);
    std::string value;
    rocksdb::ReadOptions option;
    option.fill_cache = false;
    rocksdb::Status s = db->Get(option, key, &value);
    return s.ok();
}

template <class K, class V>
void ObjectCache<K, V>::set(const K &id, const V &obj)
{
    std::stringstream buffer;
    msgpack::pack(buffer, obj);
    const rocksdb::Slice &key = comp->slice(id);
    rocksdb::Status s = db->Put(rocksdb::WriteOptions(), key, buffer.str());
    insert(id, obj);
}

template <class K, class V>
void ObjectCache<K, V>::remove(const K &id)
{
    const rocksdb::Slice &key = comp->slice(id);
    db->Delete(rocksdb::WriteOptions(), key);
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
