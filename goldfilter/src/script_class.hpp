#ifndef SCRIPT_CLASS_HPP
#define SCRIPT_CLASS_HPP

#include <msgpack.hpp>
#include <string>
#include <unordered_map>

struct Packet;
typedef std::shared_ptr<Packet> PacketPtr;

struct Layer;
typedef std::shared_ptr<Layer> LayerPtr;

class NetStream;
typedef std::shared_ptr<NetStream> NetStreamPtr;
typedef std::vector<NetStreamPtr> NetStreamList;

class ScriptClass final
{
  public:
    ScriptClass(const msgpack::object &options);
    ~ScriptClass();
    bool loadFile(const std::string &path, std::string *error = nullptr);
    bool loadSource(const std::string &source, std::string *error = nullptr);
    bool loadModule(const std::string &name, const std::string &source, std::string *error = nullptr);
    bool analyze(const PacketPtr &packet, const LayerPtr &parentLayer, std::string *error = nullptr) const;
    bool analyzeStream(const PacketPtr &packet, const LayerPtr &parentLayer, const msgpack::object &data,
                       msgpack::object *ctx, msgpack::zone *zone, NetStreamList *straems,
                       std::vector<PacketPtr> *packets, std::string *error = nullptr) const;
    bool filter(const PacketPtr &packet) const;

  public:
    ScriptClass(ScriptClass const &) = delete;
    ScriptClass &operator=(ScriptClass const &) = delete;

    class Private;

  private:
    class CreateParams;
    Private *d;
};

typedef std::shared_ptr<ScriptClass> ScriptClassPtr;

#endif
