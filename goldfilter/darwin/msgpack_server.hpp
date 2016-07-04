#ifndef MSGPACK_SERVER_HPP
#define MSGPACK_SERVER_HPP

#include "msgpack_server_interface.hpp"

class MsgpackServer final : public MsgpackServerInterface
{
  public:
    explicit MsgpackServer(const std::string &path);
    virtual ~MsgpackServer();
    void handle(const std::string &command, const MsgpackCallback &func) override;
    bool start() override;
    bool stop() override;

  private:
    class Private;
    Private *d;
};

#endif
