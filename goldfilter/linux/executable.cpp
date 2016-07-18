#include "executable.hpp"
#include <sys/capability.h>
#include <unistd.h>
#include <iostream>

std::string Executable::path() const
{
    char buf[256] = {0};
    ssize_t length = readlink("/proc/self/exe", buf, sizeof(buf));
    if (length < 0)
        return std::string();
    return std::string(buf, length);
}

bool Executable::testPermission() const
{
    const std::string &execPath = path();
    cap_t cap = cap_get_file(execPath.c_str());
    if (!cap)
        return false;

    bool ok = false;
    cap_flag_value_t value;
    if (cap_get_flag(cap, CAP_NET_ADMIN, CAP_EFFECTIVE, &value) < 0 ||
        value == CAP_CLEAR)
        goto end;
    if (cap_get_flag(cap, CAP_NET_ADMIN, CAP_PERMITTED, &value) < 0 ||
        value == CAP_CLEAR)
        goto end;
    if (cap_get_flag(cap, CAP_NET_ADMIN, CAP_INHERITABLE, &value) < 0 ||
        value == CAP_CLEAR)
        goto end;
    if (cap_get_flag(cap, CAP_NET_RAW, CAP_EFFECTIVE, &value) < 0 ||
        value == CAP_CLEAR)
        goto end;
    if (cap_get_flag(cap, CAP_NET_RAW, CAP_PERMITTED, &value) < 0 ||
        value == CAP_CLEAR)
        goto end;
    if (cap_get_flag(cap, CAP_NET_RAW, CAP_INHERITABLE, &value) < 0 ||
        value == CAP_CLEAR)
        goto end;
    ok = true;

end:
    cap_free(cap);
    return ok;
}

bool Executable::asRoot() const
{
    return (geteuid() == 0);
}
