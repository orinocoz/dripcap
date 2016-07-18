#include "executable.hpp"
#include <sys/capability.h>
#include <unistd.h>
#include <libgen.h>
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

bool Executable::grantPermission()
{
    const size_t length = 256;
    char buf[length] = {0};
    path().copy(buf, length - 1);
    const std::string &execPath = std::string(dirname(buf)) + "/goldfilter";
    cap_t cap = cap_get_file(execPath.c_str());
    if (!cap)
        cap = cap_init();

    bool ok = false;
    cap_value_t caps[] = {CAP_NET_ADMIN, CAP_NET_RAW};
    if (cap_set_flag(cap, CAP_EFFECTIVE, 2, caps, CAP_SET) < 0)
        goto end;
    if (cap_set_flag(cap, CAP_PERMITTED, 2, caps, CAP_SET) < 0)
        goto end;
    if (cap_set_flag(cap, CAP_INHERITABLE, 2, caps, CAP_SET) < 0)
        goto end;
    if (cap_set_file(execPath.c_str(), cap) < 0)
        goto end;
    ok = true;

end:
    cap_free(cap);
    return ok;
}

bool Executable::startup() const
{
    return true;
}

bool Executable::asRoot() const
{
    return (geteuid() == 0);
}
