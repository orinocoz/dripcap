#include "executable.hpp"
#include <cstdlib>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <unistd.h>

std::string Executable::path() const
{
    size_t length;
    int getProcessArgs[4] = {CTL_KERN, KERN_PROCARGS, getpid(), -1};
    sysctl(getProcessArgs, 4, nullptr, &length, nullptr, 0);
    char args[length];
    sysctl(getProcessArgs, 4, args, &length, nullptr, 0);
    return std::string(std::string(args, length).c_str());
}

bool Executable::testPermission() const
{
    DIR *dp = opendir("/dev");
    if (dp == nullptr)
        return false;

    bool ok = true;
    struct dirent *ep;
    while ((ep = readdir(dp))) {
        std::string name(ep->d_name);
        if (name.find("bpf") == 0) {
            struct stat buf;
            if (stat(("/dev/" + name).c_str(), &buf) < 0 || !(buf.st_mode & S_IRGRP)) {
                ok = false;
                break;
            }
        }
    }

    closedir(dp);
    return ok;
}

bool Executable::asRoot() const
{
    return (geteuid() == 0);
}
