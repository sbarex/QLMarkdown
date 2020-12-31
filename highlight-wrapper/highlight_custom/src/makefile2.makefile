# Simple Makefile for Highlight
# This file will compile the highlight library and binaries.
# See INSTALL for instructions.

# Add -DHL_DATA_DIR=\"/your/path/\" to CFLAGS if you want to define a
# custom installation directory not listed in INSTALL.
# Copy *.conf, ./langDefs, ./themes and ./plugins to /your/path/.
# See ../makefile for the definition of ${data_dir}

# Add -DHL_CONFIG_DIR=\"/your/path/\" to define the configuration directory
# (default: /etc/highlight)

# See src/gui-qt/highlight.pro for the Qt GUI compilation options

#CXX ?= clang++
CXX ?= g++

QMAKE ?= qmake

CFLAGS:=-Wall -O2 ${CFLAGS} ${MYCFLAGS} -std=c++11 -D_FILE_OFFSET_BITS=64 -Wno-unknown-warning-option

#CFLAGS:= -fPIC -O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -fasynchronous-unwind-tables -fstack-clash-protection

#CFLAGS:=-ggdb -O0 ${CFLAGS} -std=c++11

CFLAGS_DILU=-fno-strict-aliasing

SO_VERSION=3.61

# Source paths
CORE_DIR=./core/
CLI_DIR=./cli/
GUI_QT_DIR=./gui-qt/

# Include path
INCLUDE_DIR=./include/

# try to detect Lua versioning scheme
#LUA_PKG_NAME=lua5.3
#LUA_TEST=$(shell pkg-config --exists ${LUA_PKG_NAME}; echo $$?)

#ifeq (${LUA_TEST},1)
#LUA_PKG_NAME=lua
#endif

## Uses env to detect lua flags.
## LUA_CFLAGS=$(shell pkg-config --cflags ${LUA_PKG_NAME})
## LUA_LIBS=$(shell pkg-config --libs ${LUA_PKG_NAME})

# luajit lib
# LUA_LIBS=$(shell pkg-config --libs luajit)

# Third-Party software paths
ASTYLE_DIR=${CORE_DIR}astyle/
REGEX_DIR=${CORE_DIR}re/
DILU_DIR=${CORE_DIR}Diluculum/

ifndef HL_CONFIG_DIR
	HL_CONFIG_DIR = /etc/highlight/
endif
ifndef HL_DATA_DIR
	HL_DATA_DIR = /usr/share/highlight/
endif
ifndef HL_DOC_DIR
	HL_DOC_DIR = /usr/share/doc/highlight/
endif

ifdef PIC
	CFLAGS+=-fPIC
endif

LDFLAGS = -ldl ${MYLDFLAGS}
# Do not strip by default (Mac OS X lazy pointer issues)
# Add -static to avoid linking with shared libs (can cause trouble when highlight
# is run as service)
#LDFLAGS = ${LDFLAGS} -s
#LDFLAGS= -Wl,--as-needed

CXX_COMPILE=${CXX} ${CFLAGS} -c -I ${INCLUDE_DIR} ${LUA_CFLAGS}

# Data directories (data dir, configuration file dir)
CXX_DIR=-DHL_DATA_DIR=\"${HL_DATA_DIR}\" -DHL_CONFIG_DIR=\"${HL_CONFIG_DIR}\"

AR=ar
ARFLAGS=-crs

# objects files to build the library
CORE_OBJECTS:=stylecolour.o stringtools.o \
	xhtmlgenerator.o latexgenerator.o texgenerator.o rtfgenerator.o \
	htmlgenerator.o ansigenerator.o svggenerator.o codegenerator.o \
	xterm256generator.o pangogenerator.o bbcodegenerator.o odtgenerator.o\
	syntaxreader.o elementstyle.o themereader.o keystore.o\
	datadir.o preformatter.o platform_fs.o\
	ASStreamIterator.o ASResource.o ASFormatter.o ASBeautifier.o ASEnhancer.o

DILU_OBJECTS:=InternalUtils.o  LuaExceptions.o  LuaFunction.o  LuaState.o\
	LuaUserData.o  LuaUtils.o  LuaValue.o  LuaVariable.o  LuaWrappers.o

# command line interface
CLI_OBJECTS:=arg_parser.o cmdlineoptions.o main.o help.o

# Qt user interface
GUI_OBJECTS:=${GUI_QT_DIR}main.cpp ${GUI_QT_DIR}mainwindow.cpp ${GUI_QT_DIR}io_report.cpp\
	${GUI_QT_DIR}showtextfile.cpp


cli: libhighlight.a ${CLI_OBJECTS}
	${CXX} ${LDFLAGS} -o highlight ${CLI_OBJECTS} -L. -lhighlight ${LUA_LIBS}

lib-static libhighlight.a: ${CORE_OBJECTS}
	${AR} ${ARFLAGS} libhighlight.a ${CORE_OBJECTS} ${DILU_OBJECTS}

lib-shared libhighlight.so.1.0: ${CORE_OBJECTS}
	${CXX} -shared -Wl,-soname,libhighlight.so.${SO_VERSION} -o libhighlight.so.${SO_VERSION} -lc ${CORE_OBJECTS}

gui-qt: highlight-gui

highlight-gui: libhighlight.a ${GUI_OBJECTS}
	cd gui-qt && \
	${QMAKE} 'DEFINES+=DATA_DIR=\\\"${HL_DATA_DIR}\\\" CONFIG_DIR=\\\"${HL_CONFIG_DIR}\\\" DOC_DIR=\\\"${HL_DOC_DIR}\\\" ' && \
	$(MAKE)

$(OBJECTFILES) : makefile


datadir.o: ${CORE_DIR}datadir.cpp ${INCLUDE_DIR}datadir.h ${INCLUDE_DIR}platform_fs.h
	${CXX_COMPILE} ${CORE_DIR}datadir.cpp ${CXX_DIR}

platform_fs.o: ${CORE_DIR}platform_fs.cpp ${INCLUDE_DIR}platform_fs.h
	${CXX_COMPILE} ${CORE_DIR}platform_fs.cpp

themereader.o: ${CORE_DIR}themereader.cpp ${INCLUDE_DIR}themereader.h \
	${INCLUDE_DIR}stringtools.h ${INCLUDE_DIR}elementstyle.h ${INCLUDE_DIR}stylecolour.h ${DILU_OBJECTS}
	${CXX_COMPILE} ${CORE_DIR}themereader.cpp

elementstyle.o: ${CORE_DIR}elementstyle.cpp ${INCLUDE_DIR}elementstyle.h ${INCLUDE_DIR}stylecolour.h
	${CXX_COMPILE} ${CORE_DIR}elementstyle.cpp

syntaxreader.o: ${CORE_DIR}syntaxreader.cpp ${INCLUDE_DIR}syntaxreader.h ${INCLUDE_DIR}keystore.h \
	${INCLUDE_DIR}platform_fs.h ${INCLUDE_DIR}enums.h ${INCLUDE_DIR}stringtools.h
	${CXX_COMPILE} ${CORE_DIR}syntaxreader.cpp

codegenerator.o: ${CORE_DIR}codegenerator.cpp ${INCLUDE_DIR}codegenerator.h ${INCLUDE_DIR}syntaxreader.h \
	${INCLUDE_DIR}stringtools.h ${INCLUDE_DIR}enums.h ${INCLUDE_DIR}themereader.h ${INCLUDE_DIR}keystore.h \
	${INCLUDE_DIR}elementstyle.h ${INCLUDE_DIR}stylecolour.h ${INCLUDE_DIR}preformatter.h \
	${INCLUDE_DIR}htmlgenerator.h ${INCLUDE_DIR}version.h ${INCLUDE_DIR}charcodes.h ${INCLUDE_DIR}xhtmlgenerator.h ${INCLUDE_DIR}rtfgenerator.h \
	${INCLUDE_DIR}latexgenerator.h ${INCLUDE_DIR}texgenerator.h ${INCLUDE_DIR}ansigenerator.h
	${CXX_COMPILE} ${CORE_DIR}codegenerator.cpp

ansigenerator.o: ${CORE_DIR}ansigenerator.cpp ${INCLUDE_DIR}ansigenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}ansigenerator.cpp

htmlgenerator.o: ${CORE_DIR}htmlgenerator.cpp ${INCLUDE_DIR}htmlgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}htmlgenerator.cpp

latexgenerator.o: ${CORE_DIR}latexgenerator.cpp ${INCLUDE_DIR}latexgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}latexgenerator.cpp

bbcodegenerator.o: ${CORE_DIR}bbcodegenerator.cpp ${INCLUDE_DIR}bbcodegenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}bbcodegenerator.cpp

pangogenerator.o: ${CORE_DIR}pangogenerator.cpp ${INCLUDE_DIR}pangogenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}pangogenerator.cpp

odtgenerator.o: ${CORE_DIR}odtgenerator.cpp ${INCLUDE_DIR}odtgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}odtgenerator.cpp

rtfgenerator.o: ${CORE_DIR}rtfgenerator.cpp ${INCLUDE_DIR}rtfgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}rtfgenerator.cpp

texgenerator.o: ${CORE_DIR}texgenerator.cpp ${INCLUDE_DIR}texgenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}texgenerator.cpp

xhtmlgenerator.o: ${CORE_DIR}xhtmlgenerator.cpp ${INCLUDE_DIR}xhtmlgenerator.h ${INCLUDE_DIR}htmlgenerator.h \
	${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}xhtmlgenerator.cpp

svggenerator.o: ${CORE_DIR}svggenerator.cpp ${INCLUDE_DIR}svggenerator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}svggenerator.cpp

xterm256generator.o: ${CORE_DIR}xterm256generator.cpp ${INCLUDE_DIR}xterm256generator.h ${INCLUDE_DIR}codegenerator.h
	${CXX_COMPILE} ${CORE_DIR}xterm256generator.cpp

preformatter.o: ${CORE_DIR}preformatter.cpp ${INCLUDE_DIR}preformatter.h ${INCLUDE_DIR}stringtools.h
	${CXX_COMPILE} ${CORE_DIR}preformatter.cpp

stringtools.o: ${CORE_DIR}stringtools.cpp ${INCLUDE_DIR}stringtools.h
	${CXX_COMPILE} ${CORE_DIR}stringtools.cpp

stylecolour.o: ${CORE_DIR}stylecolour.cpp ${INCLUDE_DIR}stylecolour.h ${INCLUDE_DIR}enums.h ${INCLUDE_DIR}stringtools.h
	${CXX_COMPILE} ${CORE_DIR}stylecolour.cpp

keystore.o: ${CORE_DIR}keystore.cpp ${INCLUDE_DIR}keystore.h
	${CXX_COMPILE} ${CORE_DIR}keystore.cpp

# cli stuff
arg_parser.o: ${CLI_DIR}arg_parser.cc
	${CXX_COMPILE} ${CLI_DIR}arg_parser.cc

cmdlineoptions.o: ${CLI_DIR}cmdlineoptions.cpp ${CLI_DIR}cmdlineoptions.h
	${CXX_COMPILE} ${CLI_DIR}cmdlineoptions.cpp

help.o: ${CLI_DIR}help.cpp ${CLI_DIR}help.h
	${CXX_COMPILE} ${CLI_DIR}help.cpp

main.o: ${CLI_DIR}main.cpp ${CLI_DIR}main.h ${CLI_DIR}cmdlineoptions.h ${INCLUDE_DIR}platform_fs.h \
	${INCLUDE_DIR}datadir.h ${INCLUDE_DIR}enums.h ${INCLUDE_DIR}codegenerator.h \
	${INCLUDE_DIR}syntaxreader.h ${INCLUDE_DIR}themereader.h ${INCLUDE_DIR}elementstyle.h \
	${INCLUDE_DIR}stylecolour.h  ${INCLUDE_DIR}preformatter.h \
	${CLI_DIR}help.h ${INCLUDE_DIR}version.h
	${CXX_COMPILE} ${CLI_DIR}main.cpp ${CXX_DIR}


#3rd party libs

ASBeautifier.o: ${ASTYLE_DIR}ASBeautifier.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASBeautifier.cpp

ASFormatter.o: ${ASTYLE_DIR}ASFormatter.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASFormatter.cpp

ASResource.o: ${ASTYLE_DIR}ASResource.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASResource.cpp

ASEnhancer.o: ${ASTYLE_DIR}ASResource.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASEnhancer.cpp

ASStreamIterator.o: ${ASTYLE_DIR}ASStreamIterator.cpp
	${CXX_COMPILE} ${ASTYLE_DIR}ASStreamIterator.cpp

InternalUtils.o: ${DILU_DIR}InternalUtils.cpp
	${CXX_COMPILE}  ${DILU_DIR}InternalUtils.cpp
LuaExceptions.o: ${DILU_DIR}LuaExceptions.cpp
	${CXX_COMPILE}  ${DILU_DIR}LuaExceptions.cpp
LuaFunction.o: ${DILU_DIR}LuaFunction.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaFunction.cpp
LuaState.o: ${DILU_DIR}LuaState.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaState.cpp
LuaUserData.o: ${DILU_DIR}LuaUserData.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaUserData.cpp
LuaUtils.o: ${DILU_DIR}LuaUtils.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaUtils.cpp
LuaValue.o: ${DILU_DIR}LuaValue.cpp
	${CXX_COMPILE} ${CFLAGS_DILU} ${DILU_DIR}LuaValue.cpp
LuaVariable.o: ${DILU_DIR}LuaVariable.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaVariable.cpp
LuaWrappers.o: ${DILU_DIR}LuaWrappers.cpp
	${CXX_COMPILE} ${DILU_DIR}LuaWrappers.cpp

.PHONY: ${GUI_OBJECTS}

clean:
	@rm -f *.o
	@rm -f ./highlight
	@rm -f ./highlight-gui
	@rm -f ./libhighlight.a
	@rm -f ./libhighlight.so.*
	@rm -f ./.deps/*
	@rm -f gui-qt/*.o
	@rm -f gui-qt/Makefile*
	@rm -f gui-qt/object_script.*
	@rm -f gui-qt/ui_*.h gui-qt/qrc_*.cpp gui-qt/moc_*.cpp
	@rm -rf gui-qt/highlight-gui.gch/
	@rm -f gui-qt/.qmake.stash

# for SWIG makefile
clean-obj:
	@rm -f *.o
