# Modernized Makefile for Highlight
# This file compiles the highlight library and binaries.

CXX ?= g++
QMAKE ?= qmake
AR ?= ar

# Version and Paths
SO_VERSION = 4.0
CORE_DIR = ./core/
CLI_DIR = ./cli/
GUI_QT_DIR = ./gui-qt/
INCLUDE_DIR = ./include/
ASTYLE_DIR = $(CORE_DIR)astyle/
DILU_DIR = $(CORE_DIR)Diluculum/

# Configuration Defaults
HL_CONFIG_DIR ?= /etc/highlight/
HL_DATA_DIR ?= /usr/share/highlight/
HL_DOC_DIR ?= /usr/share/doc/highlight/

# Compiler and Linker Flags
# -MMD -MP generates dependency files automatically
CFLAGS += -Wall -O2 ${MYCFLAGS} -DNDEBUG -std=c++17 -D_FILE_OFFSET_BITS=64 -MMD -MP -Wno-unknown-warning-option -Wno-deprecated-declarations
CFLAGS_DILU = -fno-strict-aliasing
CXX_DIR = -DHL_DATA_DIR=\"$(HL_DATA_DIR)\" -DHL_CONFIG_DIR=\"$(HL_CONFIG_DIR)\"
CPPFLAGS += -I $(INCLUDE_DIR)
LDFLAGS += ${MYLDFLAGS}

# Lua Detection
## Uses env to detect lua flags.
# LUA_PKG_NAME := $(shell pkg-config --exists lua5.3 && echo lua5.3 || echo lua)
# LUA_CFLAGS := $(shell pkg-config --cflags $(LUA_PKG_NAME))
# LUA_LIBS := $(shell pkg-config --libs $(LUA_PKG_NAME))

ifneq ($(OS), Windows_NT)
	LDFLAGS += -ldl
endif

ifdef PIC
	CFLAGS += -fPIC
endif

# Object Definitions
CORE_OBJS := stylecolour.o stringtools.o xhtmlgenerator.o latexgenerator.o \
		texgenerator.o rtfgenerator.o htmlgenerator.o ansigenerator.o \
		svggenerator.o codegenerator.o xterm256generator.o \
		pangogenerator.o bbcodegenerator.o odtgenerator.o \
		syntaxreader.o elementstyle.o themereader.o keystore.o \
		lspclient.o datadir.o preformatter.o platform_fs.o

ASTYLE_OBJS := ASStreamIterator.o ASResource.o ASFormatter.o ASBeautifier.o ASEnhancer.o

DILU_OBJS := InternalUtils.o LuaExceptions.o LuaFunction.o LuaState.o \
		LuaUserData.o LuaUtils.o LuaValue.o LuaVariable.o LuaWrappers.o

CLI_OBJS := arg_parser.o cmdlineoptions.o main.o help.o

ALL_LIB_OBJS := $(CORE_OBJS) $(ASTYLE_OBJS) $(DILU_OBJS)
ALL_OBJS := $(ALL_LIB_OBJS) $(CLI_OBJS)
DEPS := $(ALL_OBJS:.o=.d)

# VPATH allows Make to find sources in subdirectories
vpath %.cpp $(CORE_DIR):$(ASTYLE_DIR):$(DILU_DIR):$(CLI_DIR)
vpath %.cc $(CLI_DIR)

# Main Targets
.PHONY: all cli lib-static lib-shared gui-qt clean clean-obj

all: cli

cli: libhighlight.a $(CLI_OBJS)
	$(CXX) $(LDFLAGS) -o highlight $(CLI_OBJS) -L. -lhighlight $(LUA_LIBS)

lib-static libhighlight.a: $(ALL_LIB_OBJS)
	$(AR) -crs $@ $^

lib-shared libhighlight.so.$(SO_VERSION): CFLAGS += -fPIC
lib-shared libhighlight.so.$(SO_VERSION): $(ALL_LIB_OBJS)
	$(CXX) -shared -Wl,-soname,libhighlight.so.$(SO_VERSION) -o $@ -lc $^

gui-qt: libhighlight.a
	cd $(GUI_QT_DIR) && \
	$(QMAKE) 'DEFINES+=HL_DATA_DIR=\\\"$(HL_DATA_DIR)\\\" HL_CONFIG_DIR=\\\"$(HL_CONFIG_DIR)\\\" HL_DOC_DIR=\\\"$(HL_DOC_DIR)\\\" ' && \
	$(MAKE)

# Pattern Rules
%.o: %.cpp
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(LUA_CFLAGS) -c $< -o $@

%.o: %.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

# Specialized rules for objects requiring directory paths
datadir.o: datadir.cpp
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(LUA_CFLAGS) $(CXX_DIR) -c $< -o $@

main.o: main.cpp
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(LUA_CFLAGS) $(CXX_DIR) -c $< -o $@

# Apply special Diluculum flag
LuaValue.o: LuaValue.cpp
	$(CXX) $(CFLAGS) $(CFLAGS_DILU) $(CPPFLAGS) $(LUA_CFLAGS) -c $< -o $@

# Include generated dependencies
-include $(DEPS)

clean:
	rm -f *.o *.d highlight libhighlight.a libhighlight.so.*
	@if [ -d $(GUI_QT_DIR) ]; then $(MAKE) -C $(GUI_QT_DIR) clean || true; fi
	rm -f $(GUI_QT_DIR)/Makefile* $(GUI_QT_DIR)/.qmake.stash

clean-obj:
	rm -f *.o *.d
