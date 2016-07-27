#ifndef DISPATCHER_HPP
#define DISPATCHER_HPP

#include <msgpack.hpp>
#include <string>
#include <vector>

struct Packet;

class Dispatcher final
{
  public:
    Dispatcher();
    virtual ~Dispatcher();
    bool loadDissector(const std::string &source, const msgpack::object &options, std::string *error);
    bool loadStreamDissector(const std::string &source, const msgpack::object &options, std::string *error);
    bool setFilter(const std::string &name, const std::string &source, const msgpack::object &options);
    bool loadModule(const std::string &name, const std::string &source, std::string *error);

    void insert(Packet *pkt);
    std::vector<Packet *> get(uint64_t start, uint64_t end) const;
    std::vector<Packet *> get(const std::vector<uint64_t> &list) const;
    std::vector<uint64_t> getFiltered(const std::string &name, uint64_t start, uint64_t end) const;
    uint64_t queuedSize() const;
    uint64_t size() const;
    std::unordered_map<std::string, uint64_t> filtered() const;

  public:
    Dispatcher(Dispatcher const &) = delete;
    Dispatcher &operator=(Dispatcher const &) = delete;

  private:
    class Private;
    class DissectorWorker;
    class FilterWorker;
    struct FilterContext;
    struct Stream;
    Private *d;
};

#endif
