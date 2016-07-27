#ifndef MSGPACK_SERVER_INTERFACE_HPP
#define MSGPACK_SERVER_INTERFACE_HPP

#include <functional>
#include <msgpack.hpp>
#include <unordered_map>

class ReplyInterface
{
  public:
    template <class T>
    void operator()(const T &arg);
    void operator()();
    virtual bool write(const char *data, std::size_t length) = 0;

  private:
    virtual uint32_t id() const = 0;
};

template <class T>
void ReplyInterface::operator()(const T &arg)
{
    std::tuple<uint32_t, T> src(id(), arg);
    msgpack::pack(this, src);
}

inline void ReplyInterface::operator()()
{
    std::tuple<uint32_t> src(id());
    msgpack::pack(this, src);
}

typedef std::function<void(const msgpack::object &, ReplyInterface &)> MsgpackCallback;

class MsgpackServerInterface
{
  public:
    virtual void handle(const std::string &command, const MsgpackCallback &func) = 0;
    virtual bool start() = 0;
    virtual bool stop() = 0;
};

#endif
