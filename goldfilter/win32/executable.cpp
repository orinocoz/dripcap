#include "executable.hpp"

std::string Executable::path() const
{
    return "";
}

bool Executable::testPermission() const
{
    return true;
}

bool Executable::grantPermission()
{
    return true;
}
