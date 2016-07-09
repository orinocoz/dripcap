#ifndef SCRIPT_CLASS_HPP
#define SCRIPT_CLASS_HPP

#include <string>
#include <msgpack.hpp>

struct Packet;

struct Layer;
typedef std::shared_ptr<Layer> LayerPtr;

class ScriptClass final
{
  public:
    ScriptClass(const msgpack::object &options);
    ~ScriptClass();
    bool loadFile(const std::string &path, std::string *error = nullptr);
    bool loadSource(const std::string &source, std::string *error = nullptr);
    bool analyze(Packet *packet, const LayerPtr &parentLayer, std::string *error = nullptr) const;
    bool filter(Packet *packet) const;

    class Private;

  private:
    class CreateParams;
    Private *d;
};

typedef std::shared_ptr<ScriptClass> ScriptClassPtr;

#endif
