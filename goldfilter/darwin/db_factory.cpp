#include "db_factory.hpp"
#include <leveldb/comparator.h>
#include <leveldb/db.h>
#include <spdlog/spdlog.h>

namespace {

}

LevelDB::LevelDB(const std::string &path, leveldb::Comparator *comp)
    : db(nullptr), comp(comp), path(path)
{
    leveldb::Options options;
    options.create_if_missing = true;
    options.comparator = comp;
    leveldb::Status status = leveldb::DB::Open(options, path, &db);
    if (!status.ok()) {
        spdlog::get("console")->error("{}", status.ToString());
    }
}

LevelDB::~LevelDB()
{
    delete db;
    delete comp;
    leveldb::DestroyDB(path, leveldb::Options());
}

void LevelDB::put(const std::string &key, const std::string &value)
{
    db->Put(leveldb::WriteOptions(), key, value);
}

bool LevelDB::get(const std::string &key, std::string *value) const
{
    return db->Get(leveldb::ReadOptions(), key, value).ok();
}

void LevelDB::del(const std::string &key)
{
    db->Delete(leveldb::WriteOptions(), key);
}

DBInterface* DBFactory::create(const std::string &path, Type type) const
{
   leveldb::Comparator *comp = nullptr;
   if (type == DBFactory::ObjectCache) {

   }
  return new LevelDB(path, comp);
}
