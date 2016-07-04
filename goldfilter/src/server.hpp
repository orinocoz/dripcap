#ifndef SERVER_HPP
#define SERVER_HPP

#include <string>

class Server final
{
  public:
    explicit Server(const std::string &path);
    virtual ~Server();
    bool start();

  private:
    class Private;
    Private *d;
};

#endif
