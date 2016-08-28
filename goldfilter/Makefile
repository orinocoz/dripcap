BUILDDIR := build
TARGET := $(BUILDDIR)/goldfilter
INCLUDES := -I. -Isrc -Ivendor/spdlog -Ivendor/msgpack-c/include -Ivendor/v8pp

SOURCE := $(wildcard *.cpp) $(wildcard src/*.cpp)
ifeq ($(shell uname -s), Linux)
INCLUDES += -Ilinux -I/usr/local -Ivendor/libv8 -Ivendor/libv8/include
SOURCE += $(wildcard linux/*.cpp)
LDFLAGS := -Lvendor/libv8/lib -Wl,-dn,-lpcap,-lcap,-lleveldb,-lsnappy,-lv8_libplatform,-lv8_base,-lv8_libbase,-lv8_snapshot,-licui18n,-licuuc,-licudata,-lrt,-dy,-lpthread,-ldl
else
INCLUDES += -Idarwin -I/usr/local
SOURCE += $(wildcard darwin/*.cpp)
LDFLAGS := -lpcap -lv8_base -lv8_libbase -lv8_snapshot -lv8_libplatform -lleveldb
endif

OBJS := $(patsubst %.cpp,%.o, $(SOURCE))
CXXFLAGS := -Wall -std=c++11 $(INCLUDES)
PCH := stdafx.pch

ifdef NODEBUG
	CXXFLAGS += -O3 -mtune=native
	STRIP := strip
else
	CXXFLAGS += -g -ggdb
	STRIP := touch
endif

all: $(TARGET)

$(TARGET): $(BUILDDIR) $(PCH) $(OBJS)
	$(CXX) -o $(TARGET) $(OBJS) $(CXXFLAGS) $(LDFLAGS)
	@$(STRIP) $(TARGET)

$(PCH):
	$(CXX) stdafx.hpp -o $(PCH) $(CXXFLAGS)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

clean:
	@rm -rf $(OBJS) $(TARGET) $(BUILDDIR)

fmt:
	@clang-format -i **/*.cpp **/*.hpp

.PHONY: clean fmt
