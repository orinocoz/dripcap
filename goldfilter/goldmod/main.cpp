#include <cstdlib>
#include "executable.hpp"

int main()
{
    bool result = Executable().grantPermission();
    return result ? EXIT_SUCCESS : EXIT_FAILURE;
}
