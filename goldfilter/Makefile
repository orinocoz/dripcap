BUILDDIR := build
TARGET := $(BUILDDIR)/goldfilter
INCLUDES := -I. -Isrc -Ivendor/spdlog -Ivendor/msgpack-c/include -Ivendor/v8pp

SOURCE := $(wildcard *.cpp) $(wildcard src/*.cpp)
ifeq ($(shell uname -s), Linux)
INCLUDES += -Ilinux -I/usr/local -Ivendor/libv8 -Ivendor/libv8/include
SOURCE += $(wildcard linux/*.cpp)
LDFLAGS := -Lvendor/libv8/lib -Wl,-dn,-lpcap,-lcap,-lrocksdb,-lsnappy,-lbz2,-lz,-lv8_libplatform,-lv8_base,-lv8_libbase,-lv8_snapshot,-licui18n,-licuuc,-licudata,-lrt,-dy,-lpthread,-ldl
else
INCLUDES += -Idarwin -I/usr/local -I/usr/local/include
SOURCE += $(wildcard darwin/*.cpp)
LDFLAGS := -L/usr/local/lib -lpcap -lv8_base -lv8_libbase -lv8_snapshot -lv8_libplatform /usr/local/opt/rocksdb/lib/librocksdb.a /usr/local/opt/snappy/lib/libsnappy.a  /usr/local/opt/lz4/lib/liblz4.a -lbz2 -lz
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
	@rm -rf $(OBJS) $(TARGET) $(BUILDDIR) $(DEPS)

fmt:
	@clang-format -i **/*.cpp **/*.hpp

.PHONY: clean fmt

ifneq ($(MAKECMDGOALS),clean)

DEPS := $(patsubst %.cpp,%.d, $(SOURCE))

%.d:%.cpp
	@$(CXX) $(CXXFLAGS) -MF"$@" -MG -MM -MP -MT"$@" -MT"$(<:.cpp=.o)" "$<"

-include $(DEPS)
endif
