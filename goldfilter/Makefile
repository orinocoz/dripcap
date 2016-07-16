BUILDDIR := build
TARGET_GOLDFILTER := $(BUILDDIR)/goldfilter
TARGET_GOLDMOD    := $(BUILDDIR)/goldmod
INCLUDES := -I. -Isrc -Ivendor/spdlog -Ivendor/msgpack-c/include -Ivendor/v8pp

SOURCE_GOLDFILTER := $(wildcard *.cpp) $(wildcard src/*.cpp)
SOURCE_GOLDMOD    := $(wildcard goldmod/*.cpp)
ifeq ($(shell uname -s), Linux)
INCLUDES += -Ilinux -I/usr/local -Ivendor/libv8 -Ivendor/libv8/include
SOURCE_GOLDFILTER += $(wildcard linux/*.cpp)
SOURCE_GOLDMOD    += $(wildcard linux/*.cpp)
LDFLAGS := -Lvendor/libv8/lib -Wl,-dn,-lpcap,-lcap,-lv8_libplatform,-lv8_base,-lv8_libbase,-lv8_snapshot,-licui18n,-licuuc,-licudata,-lrt,-dy,-lpthread,-ldl
else
INCLUDES += -Idarwin -I/usr/local
SOURCE_GOLDFILTER += $(wildcard darwin/*.cpp)
SOURCE_GOLDMOD    += $(wildcard darwin/*.cpp)
LDFLAGS := -lpcap -lv8_base -lv8_libbase -lv8_snapshot -lv8_libplatform
endif

OBJS_GOLDFILTER := $(patsubst %.cpp,%.o, $(SOURCE_GOLDFILTER))
OBJS_GOLDMOD    := $(patsubst %.cpp,%.o, $(SOURCE_GOLDMOD))
CXXFLAGS := -Wall -std=c++11 $(INCLUDES)
PCH := stdafx.pch

ifdef NODEBUG
	CXXFLAGS += -O3 -march=native
else
	CXXFLAGS += -g -ggdb
endif

all: $(TARGET_GOLDFILTER) $(TARGET_GOLDMOD)

$(TARGET_GOLDFILTER): $(BUILDDIR) $(PCH) $(OBJS_GOLDFILTER)
	$(CXX) -o $(TARGET_GOLDFILTER) $(OBJS_GOLDFILTER) $(CXXFLAGS) $(LDFLAGS)

$(TARGET_GOLDMOD): $(BUILDDIR) $(PCH) $(OBJS_GOLDMOD)
	$(CXX) -o $(TARGET_GOLDMOD) $(OBJS_GOLDMOD) $(CXXFLAGS) $(LDFLAGS)

$(PCH):
	$(CXX) stdafx.hpp -o $(PCH) $(CXXFLAGS)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

clean:
	@rm -rf $(OBJS_GOLDFILTER) $(TARGET_GOLDFILTER) $(OBJS_GOLDMOD) $(TARGET_GOLDMOD) $(BUILDDIR)

fmt:
	@clang-format -i **/*.cpp **/*.hpp **/*.js

.PHONY: clean fmt
