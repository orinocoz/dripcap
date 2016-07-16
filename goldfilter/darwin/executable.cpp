#include "executable.hpp"
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/stat.h>

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
            int fd;
            if ((fd = open(("/dev/" + name).c_str(), O_RDONLY)) < 0) {
                if (errno == EACCES) {
                    ok = false;
                    break;
                }
            } else {
                close(fd);
            }
        }
    }

    closedir(dp);
    return ok;
}

bool Executable::grantPermission()
{
    const std::string &execPath = path();
    struct stat buf;
    if (chown(execPath.c_str(), geteuid(), getgid()) < 0)
        return false;
    if (stat(execPath.c_str(), &buf) < 0)
        return false;
    if (chmod(execPath.c_str(), buf.st_mode | S_ISUID | S_ISGID) < 0)
        return false;
    return true;
}

bool Executable::startup() const
{
    return true;
}

bool Executable::asRoot() const
{
    return (geteuid() == 0);
}
