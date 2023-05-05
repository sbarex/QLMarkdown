.DEFAULT_GOAL := all

SPACE     := $(null) $(null)
CURRENT_DIR := $(subst $(SPACE),"\\ ",$(CURDIR))

LUA_DIR=lua-5.4.4
HIGHLIGHT_DIR=highlight
MAGIC_DIR=file-5.44

ifeq ($(BUILT_PRODUCTS_DIR),)
	BUILD_DIR=${CURRENT_DIR}/build
else
	BUILD_DIR=${BUILT_PRODUCTS_DIR}
endif

ifeq ($(ONLY_ACTIVE_ARCH),)
	ONLY_ACTIVE_ARCH=NO
endif

CXX=clang++
CFLAGS=-Wall -std=c++11 -D_FILE_OFFSET_BITS=64 \
       -I ${CURRENT_DIR}/${HIGHLIGHT_DIR}/src/include \
       -I ${CURRENT_DIR}/${LUA_DIR}/src \
       -I ${CURRENT_DIR}/${MAGIC_DIR}/src \
       -I ${CURRENT_DIR} \
       -I ${BUILD_DIR}
LDFLAGS=-L${BUILD_DIR}

CFLAGS_x86_64=-target x86_64-apple-macos10.15 -mmacosx-version-min=10.15
CFLAGS_arm64=-target arm64-apple-macos11 -mmacosx-version-min=11

LDFLAGS_x86_64=-target x86_64-apple-macos10.15 -mmacosx-version-min=10.15
LDFLAGS_arm64=-target arm64-apple-macos11 -mmacosx-version-min=11

ifeq ($(CONFIGURATION),Debug)
	CFLAGS_x86_64+= -g
	CFLAGS_arm64+= -g
else
	CFLAGS_x86_64+= -DNDEBUG
	CFLAGS_arm64+= -DNDEBUG
endif

bold := $(shell tput bold 2> /dev/null)
normal := $(shell tput sgr0 2> /dev/null)

ifndef NATIVE_ARCH
	NATIVE_ARCH := $(shell uname -m)
	# $(error NATIVE_ARCH is not set)
endif

VALID_ARCHS = x86_64 arm64

libraries_shared =
libraries_static =
lua_libraries =
magic_libraries =
goutils_libraries =

ifeq ($(NATIVE_ARCH),x86_64)
	lua_libraries    += ${BUILD_DIR}/liblua-x86_64.a
	magic_libraries  += ${BUILD_DIR}/libmagic-x86_64.a
	goutils_libraries  += ${BUILD_DIR}/libgoutils-x86_64.a
	highlight_libraries = ${BUILD_DIR}/libhighlight-x86_64.a
	libraries_shared += ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib
	libraries_static += ${BUILD_DIR}/libwrapper_highlight-x86_64.a
else
	lua_libraries    += ${BUILD_DIR}/liblua-arm64.a
	magic_libraries  += ${BUILD_DIR}/libmagic-arm64.a
	goutils_libraries  += ${BUILD_DIR}/libgoutils-arm64.a
	highlight_libraries = ${BUILD_DIR}/libhighlight_arm64.dylyb
	libraries_shared += ${BUILD_DIR}/libwrapper_highlight-arm64.dylib
	libraries_static += ${BUILD_DIR}/libwrapper_highlight-arm64.a
endif

ifeq ($(ONLY_ACTIVE_ARCH),NO)
ifeq ($(NATIVE_ARCH),x86_64)
		# build arm code
		lua_libraries    += ${BUILD_DIR}/liblua-arm64.a
		magic_libraries  += ${BUILD_DIR}/libmagic-arm64.a
		goutils_libraries  += ${BUILD_DIR}/libgoutils-arm64.a
		highlight_libraries += ${BUILD_DIR}/libhighlight-arm64.a
		libraries_shared += ${BUILD_DIR}/libwrapper_highlight-arm64.dylib
		libraries_static += ${BUILD_DIR}/libwrapper_highlight-arm64.a
else
		# build intel code
		lua_libraries    += ${BUILD_DIR}/liblua-x86_64.a
		magic_libraries  += ${BUILD_DIR}/libmagic-x86_64.a
		goutils_libraries  += ${BUILD_DIR}/libgoutils-x86_64.a
		highlight_libraries += ${BUILD_DIR}/libhighlight-x86_64.a
		libraries_shared += ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib
		libraries_static += ${BUILD_DIR}/libwrapper_highlight-x86_64.a
endif
endif

check_arch:
# 	@echo NATIVE_ARCH IS $(NATIVE_ARCH)
ifeq ($(filter $(NATIVE_ARCH),$(VALID_ARCHS)),)
		$(error "Current arch ${NATIVE_ARCH} is not supported! Valid archs are: ${VALID_ARCHS}.")
endif
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "Building universal binary"
else
		@echo "Building $(NATIVE_ARCH) architecture"
endif
	@echo ""

build_dir:
	$(shell mkdir build 2> /dev/null)

# ################################
# LUA library
# ################################

lua_arm: ${BUILD_DIR}/liblua-arm64.a
lua_intel: ${BUILD_DIR}/liblua-x86_64.a
lua: ${BUILD_DIR}/liblua.a

clean_lua:
	@echo "${bold}Cleaning lua…${normal}"
	${MAKE} -C ${LUA_DIR} clean
	@echo ""

${BUILD_DIR}/liblua-arm64.a:
	@echo "${bold}Building lua for arm64 platform…${normal}"
	${MAKE} -C ${LUA_DIR} clean
	${MAKE} CC="gcc -std=gnu99 -target arm64-apple-macos11" MYCFLAGS="$(CFLAGS_arm64)" MYLDFLAGS="$(LDFLAGS_arm64)" -C ${LUA_DIR}
	mv ${LUA_DIR}/src/liblua.a ${BUILD_DIR}/liblua-arm64.a
	@echo ""

${BUILD_DIR}/liblua-x86_64.a:
	@echo "${bold}Building lua for x86_64 platform…${normal}"
	${MAKE} -C ${LUA_DIR} clean
	${MAKE} MYCFLAGS="$(CFLAGS_x86_64)" MYLDFLAGS="$(LDFLAGS_x86_64)" -C ${LUA_DIR}
	mv ${LUA_DIR}/src/liblua.a ${BUILD_DIR}/liblua-x86_64.a
	@echo ""

${BUILD_DIR}/liblua.a: ${lua_libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating lua universal library...${normal}"
		lipo -create -output ${BUILD_DIR}/liblua.a ${BUILD_DIR}/liblua-x86_64.a ${BUILD_DIR}/liblua-arm64.a
else
		@echo "${bold}Creating lua library for ${NATIVE_ARCH}...${normal}"
		@rm -f ${BUILD_DIR}/liblua.a > /dev/null
		ln ${BUILD_DIR}/liblua-${NATIVE_ARCH}.a ${BUILD_DIR}/liblua.a
endif
	@echo ""



# ################################
# Highlight library
# ################################

highlight_arm: lua ${BUILD_DIR}/libhighlight-arm64.a
highlight_intel: lua ${BUILD_DIR}/libhighlight-x86_64.a
highlight: ${BUILD_DIR}/libhighlight.a

clean_highlight:
	@echo "${bold}Cleaning highlight…${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	@${MAKE} -C ${HIGHLIGHT_DIR} -f makefile2.makefile clean
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/libhighlight-x86_64.a:
	@echo "${bold}Building highlight for x86_64 platform...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	@${MAKE} -C ${HIGHLIGHT_DIR} -f makefile2.makefile clean
	${MAKE} LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" LUA_LIBS="-L$(CURRENT_DIR)/build -llua -lm" MYCFLAGS="${CFLAGS_x86_64} -I$(CURRENT_DIR)/" -C ${HIGHLIGHT_DIR} -f makefile2.makefile lib-static
	mv ${HIGHLIGHT_DIR}/src/libhighlight.a ${BUILD_DIR}/libhighlight-x86_64.a
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/libhighlight-arm64.a:
	@echo "${bold}Building highlight for arm64 platform...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	@${MAKE} -C ${HIGHLIGHT_DIR} -f makefile2.makefile clean
	${MAKE} LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" LUA_LIBS="-L$(CURRENT_DIR)/build -llua -lm" MYCFLAGS="${CFLAGS_arm64} -I$(CURRENT_DIR)/" MYLDFLAGS="$(LDFLAGS_arm64)" -C ${HIGHLIGHT_DIR} -f makefile2.makefile lib-static
	mv ${HIGHLIGHT_DIR}/src/libhighlight.a ${BUILD_DIR}/libhighlight-arm64.a
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR}/libhighlight.a: ${highlight_libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating highlight universal library...${normal}"
		lipo -create -output ${BUILD_DIR}/libhighlight.a ${BUILD_DIR}/libhighlight-x86_64.a ${BUILD_DIR}/libhighlight-arm64.a
else
		@echo "${bold}Creating highlight library for ${NATIVE_ARCH}...${normal}"
		@rm -f ${BUILD_DIR}/libhighlight.a > /dev/null
		ln ${BUILD_DIR}/libhighlight-${NATIVE_ARCH}.a ${BUILD_DIR}/libhighlight.a
endif
	@echo ""


# ################################
# Magic library
# ################################

magic_arm: ${BUILD_DIR}/libmagic-arm64.a
magic_intel: ${BUILD_DIR}/libmagic-x86_64.a
magic: ${BUILD_DIR}/libmagic.a
magic_db: ${BUILD_DIR}/magic.mgc

clean_magic:
	@echo "${bold}Cleaning magic…${normal}"
ifneq ("$(wildcard $(MAGIC_DIR)/Makefile)","")
	@${MAKE} -C ${MAGIC_DIR} clean
endif
	@echo ""

${BUILD_DIR}/libmagic-x86_64.a:
	@echo "${bold}Building magic for x86_64 platform...${normal}"
ifneq ("$(wildcard $(MAGIC_DIR)/Makefile)","")
	@${MAKE} -C ${MAGIC_DIR} clean
endif
	cd $(MAGIC_DIR) && CFLAGS="${CFLAGS_x86_64}" ./configure --host=x86_64-apple --enable-static --disable-zlib --disable-bzlib --disable-xzlib
ifneq ($(NATIVE_ARCH),x86_64)
# Change the path of the native `file`.
	/usr/bin/sed -i.bak -E 's/^FILE_COMPILE.*$$/FILE_COMPILE = $$\{BUILD_DIR\}\/file-$$\{NATIVE_ARCH\}/g' $(MAGIC_DIR)/magic/Makefile
endif
	${MAKE} -C ${MAGIC_DIR}
	mv ${MAGIC_DIR}/src/.libs/libmagic.a ${BUILD_DIR}/libmagic-x86_64.a
	mv ${MAGIC_DIR}/src/file ${BUILD_DIR}/file-x86_64
	@echo ""

${BUILD_DIR}/libmagic-arm64.a:
	@echo "${bold}Building magic for arm64 platform...${normal}"
ifneq ("$(wildcard $(MAGIC_DIR)/Makefile)","")
	@${MAKE} -C ${MAGIC_DIR} clean
endif
	cd $(MAGIC_DIR) && CFLAGS="${CFLAGS_arm64}" ./configure --host=arm-apple --enable-static --disable-zlib --disable-bzlib --disable-xzlib
ifneq ($(NATIVE_ARCH),arm64)
# Change the path of the native `file`.
	/usr/bin/sed -i.bak -E 's/^FILE_COMPILE.*$$/FILE_COMPILE = $$\{BUILD_DIR\}\/file-$$\{NATIVE_ARCH\}/g' $(MAGIC_DIR)/magic/Makefile
endif
	${MAKE} -C ${MAGIC_DIR}
	mv ${MAGIC_DIR}/src/.libs/libmagic.a ${BUILD_DIR}/libmagic-arm64.a
	mv ${MAGIC_DIR}/src/file ${BUILD_DIR}/file-arm64
	@echo ""

${BUILD_DIR}/libmagic.a: ${magic_libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating magic universal library...${normal}"
		lipo -create -output ${BUILD_DIR}/libmagic.a ${BUILD_DIR}/libmagic-x86_64.a ${BUILD_DIR}/libmagic-arm64.a
		lipo -create -output ${BUILD_DIR}/file ${BUILD_DIR}/file-x86_64 ${BUILD_DIR}/file-arm64
else
		@echo "${bold}Creating magic library for ${NATIVE_ARCH}...${normal}"
		@rm -f ${BUILD_DIR}/libmagic.a > /dev/null
		ln ${BUILD_DIR}/libmagic-${NATIVE_ARCH}.a ${BUILD_DIR}/libmagic.a
		@rm -f ${BUILD_DIR}/file > /dev/null
		ln ${BUILD_DIR}/file-${NATIVE_ARCH} ${BUILD_DIR}/file
endif
	@echo ""

${BUILD_DIR}/magic.mgc:
	@echo "${bold}Coping magic.mgc...${normal}"
	#${BUILD_DIR}/file -C -m ${CURRENT_DIR}/${MAGIC_DIR}/magic
	#mv ${CURRENT_DIR}/${MAGIC_DIR}/magic.mgc ${BUILD_DIR}/
	cp ${CURRENT_DIR}/${MAGIC_DIR}/magic/magic.mgc ${BUILD_DIR}/magic.mgc


# ################################
# GOUtils
# ################################

goutils_intel: ${BUILD_DIR}/libgoutils-x86_64.a
goutils_arm: ${BUILD_DIR}/libgoutils-arm64.a
goutils: ${BUILD_DIR}/libgoutils.a

clean_goutils:
	@echo "${bold}Cleaning goutils…${normal}"
	@${MAKE} -C GoUtils clean
	@echo ""

${BUILD_DIR}/libgoutils-x86_64.a:
	@echo "${bold}Building goutils for x86_64 platform...${normal}"
	${MAKE} BUILT_PRODUCTS_DIR=${BUILD_DIR} -C GoUtils static_intel
	@echo ""

${BUILD_DIR}/libgoutils-arm64.a:
	@echo "${bold}Building magic for arm64 platform...${normal}"
	${MAKE} BUILT_PRODUCTS_DIR=${BUILD_DIR} -C GoUtils static_arm
	@echo ""

${BUILD_DIR}/libgoutils.a: ${goutils_libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating magic universal library...${normal}"
		lipo -create -output ${BUILD_DIR}/libgoutils.a ${BUILD_DIR}/libgoutils-x86_64.a ${BUILD_DIR}/libgoutils-arm64.a
else
		@echo "${bold}Creating magic library for ${NATIVE_ARCH}...${normal}"
		@rm -f ${BUILD_DIR}/libgoutils.a > /dev/null
		ln ${BUILD_DIR}/libgoutils-${NATIVE_ARCH}.a ${BUILD_DIR}/libgoutils.a
endif
	@echo ""

# ################################
# Highlight wrapper
# ################################

highlight-wrapper_intel: ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib
highlight-wrapper_arm: ${BUILD_DIR}/libwrapper_highlight-arm64.dylib
highlight-wrapper: ${BUILD_DIR}/libwrapper_highlight.dylib

clean_highlight-wrapper:
	@echo "${bold}Cleaning highlight wrapper…${normal}"
	@rm -f ${BUILD_DIR}/wrapper_highlight-x86_64.o
	@rm -f ${BUILD_DIR}/wrapper_highlight-arm64.o
	@echo ""

${BUILD_DIR}/libwrapper_highlight-x86_64.dylib: ${BUILD_DIR}/liblua.a ${BUILD_DIR}/libhighlight.a ${BUILD_DIR}/libmagic.a ${BUILD_DIR}/libgoutils.a wrapper_highlight.cpp
	@echo "${bold}Compiling highlight wrapper for x86_64 platform...${normal}"
	@echo "current dir: ${CURRENT_DIR}"
	MACOSX_DEPLOYMENT_TARGET=10.15 ${CXX} ${CFLAGS} ${CFLAGS_x86_64} ${LDFLAGS} ${LDFLAGS_x86_64} \
-static \
-c wrapper_highlight.cpp -o ${BUILD_DIR}/wrapper_highlight-x86_64.o
	@echo ""

	@echo "${bold}Creating highlight wrapper shared library for x86_64 platform...${normal}"
	${CXX} ${CFLAGS} ${CFLAGS_x86_64} ${LDFLAGS} ${LDFLAGS_x86_64} \
-ldl -lhighlight -lmagic -llua -lgoutils \
-dynamiclib \
-install_name @rpath/libwrapper_highlight.dylib \
-o ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib ${BUILD_DIR}/wrapper_highlight-x86_64.o
	@echo ""

${BUILD_DIR}/libwrapper_highlight-arm64.dylib: ${BUILD_DIR}/liblua.a ${BUILD_DIR}/libhighlight.a ${BUILD_DIR}/libmagic.a ${BUILD_DIR}/libgoutils.a wrapper_highlight.cpp
	@echo "${bold}Compiling highlight wrapper for arm64 platform...${normal}"
	MACOSX_DEPLOYMENT_TARGET=11 ${CXX} ${CFLAGS} ${CFLAGS_arm64} \
-static \
-c wrapper_highlight.cpp -o ${BUILD_DIR}/wrapper_highlight-arm64.o
	@echo ""
	@echo "${bold}Creating highlight wrapper shared library for arm64 platform...${normal}"
	${CXX} ${CFLAGS} ${CFLAGS_arm64} ${LDFLAGS} ${LDFLAGS_arm64} \
-ldl -lhighlight -lmagic -llua -lgoutils -framework CoreFoundation \
-dynamiclib \
-install_name @rpath/libwrapper_highlight.dylib \
-o ${BUILD_DIR}/libwrapper_highlight-arm64.dylib ${BUILD_DIR}/wrapper_highlight-arm64.o
	@echo ""

${BUILD_DIR}/libwrapper_highlight.dylib: ${libraries_shared} wrapper_highlight.cpp
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating highlight wrapper universal shared library...${normal}"
		lipo -create -output ${BUILD_DIR}/libwrapper_highlight.dylib ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib ${BUILD_DIR}/libwrapper_highlight-arm64.dylib
		@echo ""
else
		@echo "${bold}Creating highlight wrapper library for ${NATIVE_ARCH}...${normal}"
		cp ${BUILD_DIR}/libwrapper_highlight-${NATIVE_ARCH}.dylib ${BUILD_DIR}/libwrapper_highlight.dylib
endif

all: check_arch build_dir magic magic_db lua highlight goutils highlight-wrapper
install: check_arch build_dir magic magic_db lua highlight goutils highlight-wrapper

clean_intermediate: clean_lua clean_highlight clean_magic clean_goutils clean_highlight-wrapper

clean: clean_intermediate
	@rm ${BUILD_DIR}/libwrapper_highlight.dylib 2> /dev/null
	@rm ${BUILD_DIR}/libwrapper_highlight-x86_64.dylib 2> /dev/null
	@rm ${BUILD_DIR}/libwrapper_highlight-arm64.dylib 2> /dev/null
	@rm ${BUILD_DIR}/libhighlight.a 2> /dev/null
	@rm ${BUILD_DIR}/libhighlight-x86_64.a 2> /dev/null
	@rm ${BUILD_DIR}/libhighlight-arm64.a 2> /dev/null
	@rm ${BUILD_DIR}/libmagic.a 2> /dev/null
	@rm ${BUILD_DIR}/libmagic-x86_64.a 2> /dev/null
	@rm ${BUILD_DIR}/libmagic-arm64.a 2> /dev/null
	@rm ${BUILD_DIR}/liblua.a 2> /dev/null
	@rm ${BUILD_DIR}/liblua-x86_64.a 2> /dev/null
	@rm ${BUILD_DIR}/liblua-arm64.a 2> /dev/null
	@rm ${BUILD_DIR}/libgoutils.a 2> /dev/null
	@rm ${BUILD_DIR}/libgoutils-x86_64.a 2> /dev/null
	@rm ${BUILD_DIR}/libgoutils-arm64.a 2> /dev/null
