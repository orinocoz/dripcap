#ifndef SERVER_HPP
#define SERVER_HPP

#include <string>
#include <memory>

class Server final
{
  public:
    explicit Server(const std::string &path);
    virtual ~Server();
    bool start();

  public:
    Server(Server const &) = delete;
    Server &operator=(Server const &) = delete;

  private:
    class LoggerSink;
    class Private;
    Private *d;
};

#endif
