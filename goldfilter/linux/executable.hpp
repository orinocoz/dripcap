#ifndef EXECUTABLE_HPP
#define EXECUTABLE_HPP

#include "executable_interface.hpp"

class Executable final : public ExecutableInterface
{
  public:
    std::string path() const override;
    bool testPermission() const override;
    bool grantPermission() override;
};

#endif
