#ifndef DB_LEVELDB_HPP
#define DB_LEVELDB_HPP

#include "db_interface.hpp"

namespace leveldb
{
class DB;
class Comparator;
}

class LevelDB : public DBInterface
{
  public:
    LevelDB(const std::string &path, leveldb::Comparator *comp = nullptr);
    ~LevelDB();
    void put(const std::string &key, const std::string &value) override;
    bool get(const std::string &key, std::string *value) const override;
    void del(const std::string &key) override;

  private:
    leveldb::DB *db;
    leveldb::Comparator *comp;
    std::string path;
};

#endif
