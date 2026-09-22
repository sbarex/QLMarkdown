.DEFAULT_GOAL := all

SPACE     := $(null) $(null)
CURRENT_DIR := $(subst $(SPACE),"\\ ",$(CURDIR))

LUA_DIR=lua-5.5.1
HIGHLIGHT_DIR=highlight

ifeq ($(BUILT_PRODUCTS_DIR),)
	BUILD_DIR=${CURRENT_DIR}/build
else
	BUILD_DIR=${BUILT_PRODUCTS_DIR}
endif

ifeq ($(ONLY_ACTIVE_ARCH),)
	ONLY_ACTIVE_ARCH=NO
endif

BUILD_DIR := $(BUILD_DIR)/highlight
BUILD_DIR_ESCAPED := $(subst $(SPACE),\ ,$(BUILD_DIR))
CURRENT_DIR_ESCAPED := $(subst $(SPACE),\ ,$(CURRENT_DIR))

CXX=clang++
CFLAGS= \
       -I ${CURRENT_DIR_ESCAPED}/${HIGHLIGHT_DIR}/src/include \
       -I ${CURRENT_DIR_ESCAPED}/${LUA_DIR}/src \
       -I ${CURRENT_DIR_ESCAPED} \
       -I ${BUILD_DIR_ESCAPED} \
       -Wno-deprecated-declarations -Wno-unknown-pragmas -Wc++17-extensions -Wc++17-attribute-extensions
CXXFLAGS += -std=c++17 -stdlib=libc++
LDFLAGS=-L${BUILD_DIR_ESCAPED}

CFLAGS_x86_64=-target x86_64-apple-macos12.0
CFLAGS_arm64=-target arm64-apple-macos12.0

LDFLAGS_x86_64=-target x86_64-apple-macos12.0
LDFLAGS_arm64=-target arm64-apple-macos12.0

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

ifeq ($(NATIVE_ARCH),x86_64)
	lua_libraries       += ${BUILD_DIR_ESCAPED}/liblua-x86_64.a
	
	highlight_libraries += ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a
	
	libraries_shared    += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib
	libraries_static    += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.a
else
	lua_libraries       += ${BUILD_DIR_ESCAPED}/liblua-arm64.a
	
	highlight_libraries += ${BUILD_DIR_ESCAPED}/libhighlight-arm64.a
	
	libraries_shared    += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib
	libraries_static    += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.a
endif

ifeq ($(ONLY_ACTIVE_ARCH),NO)
ifeq ($(NATIVE_ARCH),x86_64)
		# build arm code
		lua_libraries       += ${BUILD_DIR_ESCAPED}/liblua-arm64.a
		
		highlight_libraries += ${BUILD_DIR_ESCAPED}/libhighlight-arm64.a
		
		libraries_shared    += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib
		libraries_static    += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.a
else
		# build intel code
		lua_libraries       += ${BUILD_DIR_ESCAPED}/liblua-x86_64.a
		
		highlight_libraries += ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a
		
		libraries_shared    += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib
		libraries_static    += ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.a
endif
endif

check_arch:
# 	@echo NATIVE_ARCH IS $(NATIVE_ARCH)
ifeq ($(filter $(NATIVE_ARCH),$(VALID_ARCHS)),)
		$(error "Current arch ${NATIVE_ARCH} is not supported! Valid archs are: ${VALID_ARCHS}.")
endif
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}** BUILDING UNIVERSAL BINARY... ** ${normal}"
else
		@echo "\n${bold}** BUILDING $(NATIVE_ARCH) ARCHITECTURE... ** ${normal}"
endif
	@echo "Build dir: $(BUILD_DIR_ESCAPED)"
	@echo ""

build_dir:
	$(shell mkdir build 2> /dev/null)

# ################################
# LUA library
# ################################

lua_arm: ${BUILD_DIR_ESCAPED}/liblua-arm64.a
lua_intel: ${BUILD_DIR_ESCAPED}/liblua-x86_64.a
lua: ${BUILD_DIR_ESCAPED}/liblua.a

clean_lua:
	@echo "\n${bold}🗑️ CLEANING lua...${normal}"
	${MAKE} -C "${LUA_DIR}" clean
	@echo ""

${BUILD_DIR_ESCAPED}/liblua-arm64.a: | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING lua FOR arm64 PLATFORM...${normal}"
	${MAKE} -C "${LUA_DIR}" clean
	${MAKE} CC="gcc -std=gnu99 -target arm64-apple-macos12.0" MYCFLAGS="$(CFLAGS_arm64)" MYLDFLAGS="$(LDFLAGS_arm64)" -C "${LUA_DIR}"
	@mkdir -p "${BUILD_DIR}"
	mv "${LUA_DIR}/src/liblua.a" "$@"
	@echo ""

${BUILD_DIR_ESCAPED}/liblua-x86_64.a: | $(BUILD_DIR_ESCAPED)
	@echo "\n${bold}🔨 BUILDING lua FOR x86_64 PLATFORM...${normal}"
	${MAKE} -C "${LUA_DIR}" clean
	${MAKE} MYCFLAGS="$(CFLAGS_x86_64)" MYLDFLAGS="$(LDFLAGS_x86_64)" -C "${LUA_DIR}"
	@mkdir -p "${BUILD_DIR}"
	mv "${LUA_DIR}/src/liblua.a" "$@"
	@echo ""

${BUILD_DIR_ESCAPED}/liblua.a: $(BUILD_DIR_ESCAPED) ${lua_libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}CREATING lua UNIVERSAL LIBRARY...${normal}"
		lipo \
			-create -output "$@" \
			${BUILD_DIR_ESCAPED}/liblua-x86_64.a \
			${BUILD_DIR_ESCAPED}/liblua-arm64.a
else
		@echo "\n${bold}CREATING lua LIBRARY FOR ${NATIVE_ARCH} PLATFORM...${normal}"
		@rm -f "$@" > /dev/null
		ln "${BUILD_DIR}/liblua-${NATIVE_ARCH}.a" "$@"
endif
	@echo ""



# ################################
# Highlight library
# ################################

highlight_arm: lua ${BUILD_DIR_ESCAPED}/libhighlight-arm64.a
highlight_intel: lua ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a
highlight: ${BUILD_DIR_ESCAPED}/libhighlight.a

clean_highlight:
	@echo "${bold}Cleaning highlight…${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	@${MAKE} -C ${HIGHLIGHT_DIR} -f makefile2.makefile clean
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a:
	@echo "\n${bold}🔨 BUILDING highlight FOR x86_64 PLATFORM...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	
	@if [ -f "${HIGHLIGHT_DIR}/src/htmlgenerator.o" ]; then \
		if ! lipo -archs "${HIGHLIGHT_DIR}/src/htmlgenerator.o" 2>/dev/null | grep -qw x86_64; then \
			echo "Clean…"; \
			${MAKE} \
				-C ${HIGHLIGHT_DIR} \
				-f makefile2.makefile \
				clean; \
		fi; \
	fi
	
	${MAKE} \
		BUILD_DIR=${BUILD_DIR_ESCAPED}/build_arm64-$(CONFIGURATION) \
		LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" \
		LUA_LIBS="-L$(BUILD_DIR_ESCAPED) -llua -lm" \
		CFLAGS="${CFLAGS} ${CFLAGS_x86_64}" \
		LDFLAGS="$(LDFLAGS) $(LDFLAGS_x86_64) -Wl,-rpath,'@loader_path/'" \
		-C ${HIGHLIGHT_DIR} \
		-f makefile2.makefile \
		lib-static install-lib-static
		
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/libhighlight-arm64.a:
	@echo "\n${bold}🔨 BUILDING highlight FOR arm64 PLATFORM...${normal}"
	@cp highlight_custom/makefile2.makefile highlight/makefile2.makefile
	@cp highlight_custom/src/makefile2.makefile highlight/src/makefile2.makefile
	
	@if [ -f "${HIGHLIGHT_DIR}/src/htmlgenerator.o" ]; then \
		if ! lipo -archs "${HIGHLIGHT_DIR}/src/htmlgenerator.o" 2>/dev/null | grep -qw arm64; then \
			echo "Clean…"; \
			${MAKE} \
				-C ${HIGHLIGHT_DIR} \
				-f makefile2.makefile \
				clean; \
		fi; \
	fi
	
	${MAKE} \
		BUILD_DIR=${BUILD_DIR_ESCAPED}/build_arm64-$(CONFIGURATION) \
		LUA_CFLAGS="-I$(CURRENT_DIR)/$(LUA_DIR)/src" \
		LUA_LIBS="-L$(BUILD_DIR_ESCAPED) -llua -lm" \
		CFLAGS="${CFLAGS} ${CFLAGS_arm64}" \
		LDFLAGS="$(LDFLAGS) $(LDFLAGS_arm64) -Wl,-rpath,'@loader_path/'" \
		-C ${HIGHLIGHT_DIR} \
		-f makefile2.makefile \
		lib-static install-lib-static
		
	@rm highlight/makefile2.makefile
	@rm highlight/src/makefile2.makefile
	@echo ""

${BUILD_DIR_ESCAPED}/libhighlight.a: ${highlight_libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "\n${bold}CREATING UNIVERSAL highlight library...${normal}"
		lipo -create -output "$@" \
			"${BUILD_DIR_ESCAPED}/build_x86_64-$(CONFIGURATION)/lib/libhighlight.a" \
			"${BUILD_DIR_ESCAPED}/build_arm64-$(CONFIGURATION)/lib/libhighlight.a"
else
		@echo "\n${bold}CREATING ${NATIVE_ARCH} highlight library...${normal}"
		@rm -f "$@" > /dev/null
		@rm -f "${BUILD_DIR_ESCAPED}/libhighlight.a" > /dev/null
		ln "${BUILD_DIR_ESCAPED}/build_${NATIVE_ARCH}-$(CONFIGURATION)/lib/libhighlight.a" "$@"
endif
	@echo ""

# ################################
# Highlight wrapper
# ################################

highlight-wrapper_intel: ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib
highlight-wrapper_arm: ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib
highlight-wrapper: ${BUILD_DIR_ESCAPED}/libwrapper_highlight.dylib

clean_highlight-wrapper:
	@echo "${bold}Cleaning highlight wrapper…${normal}"
	@rm -f ${BUILD_DIR_ESCAPED}/wrapper_highlight-x86_64.o
	@rm -f ${BUILD_DIR_ESCAPED}/wrapper_highlight-arm64.o
	@echo ""

${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib: ${BUILD_DIR_ESCAPED}/liblua.a ${BUILD_DIR_ESCAPED}/libhighlight.a wrapper_highlight.cpp
	@echo "${bold}Compiling highlight wrapper for x86_64 platform...${normal}"
	@echo "current dir: ${CURRENT_DIR}"
	${CXX} \
		${CFLAGS} ${CFLAGS_x86_64} ${CXXFLAGS} \
		${LDFLAGS} ${LDFLAGS_x86_64} \
		-static \
		-c wrapper_highlight.cpp \
		-o ${BUILD_DIR_ESCAPED}/wrapper_highlight-x86_64.o
	@echo ""

	@echo "${bold}Creating highlight wrapper shared library for x86_64 platform...${normal}"
	${CXX} \
		${CFLAGS} ${CFLAGS_x86_64} ${CXXFLAGS} \
		${LDFLAGS} ${LDFLAGS_x86_64} \
		-ldl -lhighlight -llua \
		-dynamiclib \
		-install_name @rpath/libwrapper_highlight.dylib \
		-o "$@" ${BUILD_DIR_ESCAPED}/wrapper_highlight-x86_64.o
	@echo ""

${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib: ${BUILD_DIR_ESCAPED}/liblua.a ${BUILD_DIR_ESCAPED}/libhighlight.a wrapper_highlight.cpp
	@echo "${bold}Compiling highlight wrapper for arm64 platform...${normal}"
	MACOSX_DEPLOYMENT_TARGET=12 \
	${CXX} \
		${CFLAGS} ${CFLAGS_arm64} ${CXXFLAGS} \
		-static \
		-c wrapper_highlight.cpp \
		-o ${BUILD_DIR_ESCAPED}/wrapper_highlight-arm64.o
	@echo ""
	@echo "${bold}Creating highlight wrapper shared library for arm64 platform...${normal}"
	${CXX} \
		${CFLAGS} ${CFLAGS_arm64} ${CXXFLAGS} \
		${LDFLAGS} ${LDFLAGS_arm64} \
		-ldl -lhighlight -llua -framework CoreFoundation \
		-dynamiclib \
		-install_name @rpath/libwrapper_highlight.dylib \
		-o "$@" ${BUILD_DIR_ESCAPED}/wrapper_highlight-arm64.o
	@echo ""

${BUILD_DIR_ESCAPED}/libwrapper_highlight.dylib: ${libraries_shared} wrapper_highlight.cpp
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating highlight wrapper universal shared library...${normal}"
		lipo -create -output "$@" \
			${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib \
			${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib
		@echo ""
else
		@echo "${bold}Creating highlight wrapper library for ${NATIVE_ARCH}...${normal}"
		cp ${BUILD_DIR_ESCAPED}/libwrapper_highlight-${NATIVE_ARCH}.dylib "$@"
endif

all: check_arch build_dir lua highlight highlight-wrapper
install: check_arch build_dir lua highlight highlight-wrapper

clean_intermediate: clean_lua clean_highlight clean_highlight-wrapper

clean: clean_intermediate
	@rm ${BUILD_DIR_ESCAPED}/libwrapper_highlight.dylib 2> /dev/null
	@rm ${BUILD_DIR_ESCAPED}/libwrapper_highlight-x86_64.dylib 2> /dev/null
	@rm ${BUILD_DIR_ESCAPED}/libwrapper_highlight-arm64.dylib 2> /dev/null
	@rm ${BUILD_DIR_ESCAPED}/libhighlight.a 2> /dev/null
	@rm ${BUILD_DIR_ESCAPED}/libhighlight-x86_64.a 2> /dev/null
	@rm ${BUILD_DIR_ESCAPED}/libhighlight-arm64.a 2> /dev/null
	@rm ${BUILD_DIR_ESCAPED}/liblua.a 2> /dev/null
	@rm ${BUILD_DIR_ESCAPED}/liblua-x86_64.a 2> /dev/null
	@rm ${BUILD_DIR_ESCAPED}/liblua-arm64.a 2> /dev/null
	
