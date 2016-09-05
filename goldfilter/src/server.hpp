#ifndef SERVER_HPP
#define SERVER_HPP

#include <string>
#include <memory>

class Server final
{
  public:
    Server(const std::string &sock, const std::string &tmp);
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
