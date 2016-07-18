#ifndef EXECUTABLE_INTERFACE_HPP
#define EXECUTABLE_INTERFACE_HPP

#include <string>

class ExecutableInterface
{
  public:
    virtual std::string path() const = 0;
    virtual bool testPermission() const = 0;
    virtual bool asRoot() const = 0;
};

#endif
