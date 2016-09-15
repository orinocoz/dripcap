#ifndef DB_INTERFACE_HPP
#define DB_INTERFACE_HPP

#include <string>

class DBInterface
{
  public:
    virtual ~DBInterface()
    {
    }
    virtual void put(const std::string &key, const std::string &value) = 0;
    virtual bool get(const std::string &key, std::string *value) const = 0;
    virtual void del(const std::string &key) = 0;
};

class DBFactoryInterface
{
public:
  enum Type {
    Default,
    ObjectCache
  };
  public:
    virtual ~DBFactoryInterface()
    {
    }
    virtual DBInterface* create(const std::string &path, Type type) const = 0;
};

#endif
