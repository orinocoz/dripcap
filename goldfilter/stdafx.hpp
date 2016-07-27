#ifndef STDAFX_HPP
#define STDAFX_HPP

#ifdef _WIN32
#include "win32\targetver.h"
#include <WinSock2.h>
#include <tchar.h>
#undef interface
#endif

#include <cstdio>
#include <msgpack.hpp>
#include <spdlog/spdlog.h>

#endif
