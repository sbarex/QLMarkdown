.DEFAULT_GOAL := all

SPACE     := $(null) $(null)
CMARK_DIR := "${PROJECT_DIR}/cmark-gfm"
CURRENT_DIR := $(subst $(SPACE),"\\ ",$(CURDIR))

ifeq ($(BUILT_PRODUCTS_DIR),)
	BUILD_DIR=${CMARK_DIR}/build
else
	BUILD_DIR=${BUILT_PRODUCTS_DIR}/cmark
endif

ifeq ($(ONLY_ACTIVE_ARCH),)
	ONLY_ACTIVE_ARCH=NO
endif

CXX=clang++
CFLAGS=-Wall -D_FILE_OFFSET_BITS=64
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
headers = ${BUILD_DIR}/config.h ${BUILD_DIR}/cmark-gfm_export.h ${BUILD_DIR}/cmark-gfm_version.h

ifeq ($(NATIVE_ARCH),x86_64)
	libraries_shared += ${BUILD_DIR}/libcmark-gfm-x86_64.dylib
	libraries_static += ${BUILD_DIR}/libcmark-gfm-x86_64.a
else
	libraries_shared += ${BUILD_DIR}/libcmark-gfm-arm64.dylib
	libraries_static += ${BUILD_DIR}/libcmark-gfm-arm64.a
endif

ifeq ($(ONLY_ACTIVE_ARCH),NO)
ifeq ($(NATIVE_ARCH),x86_64)
		# build arm code
		libraries_shared += ${BUILD_DIR}/libcmark-gfm-arm64.dylib
		libraries_static += ${BUILD_DIR}/libcmark-gfm-arm64.a
else
		# build intel code
		libraries_shared += ${BUILD_DIR}/libcmark-gfm-x86_64.dylib
		libraries_static += ${BUILD_DIR}/libcmark-gfm-x86_64.a
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
	$(shell mkdir ${BUILD_DIR} 2> /dev/null)

cmark_arm: ${BUILD_DIR}/libcmark-gfm-arm64.a
cmark_intel: ${BUILD_DIR}/libcmark-gfm-x86_64.a
cmark: ${BUILD_DIR}/libcmark-gfm.a
headers: cmark

SPEC="${CMARK_DIR}/test/spec.txt"
SPECVERSION=$(shell perl -ne 'print $$1 if /^version: *([0-9.]+)/' "$(SPEC)")

@echo "SPECVERSION: ${SPECVERSION}"

${BUILD_DIR}/libcmark-gfm-x86_64.a:
	@echo "${bold}Building cmark for x86_64 platform...${normal}"
	@rm -rf "$(PROJECT_DIR)/cmark-x86_64" > /dev/null
	${MAKE} CMAKE_OSX_ARCHITECTURES=x86_64 CXX="${CXX}" MACOSX_DEPLOYMENT_TARGET=10.15 BUILDDIR="cmark-x86_64" CFLAGS="${CFLAGS} ${CFLAGS_x86_64}" CPPFLAGS="${CFLAGS} -std=c++11 ${CFLAGS_x86_64}" LDFLAGS="${LDFLAGS_x86_64}" -C $(CMARK_DIR) $(ACTION)
	cp cmark-x86_64/src/libcmark-gfm.a ${BUILD_DIR}/libcmark-gfm-x86_64.a
	cp cmark-x86_64/src/libcmark-gfm.${SPECVERSION}.0.gfm.11.dylib ${BUILD_DIR}/libcmark-gfm-x86_64.${SPECVERSION}.0.gfm.11.dylib
	@cp cmark-x86_64/src/cmark-gfm_export.h ${BUILD_DIR}/cmark-gfm_export.h
	@cp cmark-x86_64/src/cmark-gfm_version.h ${BUILD_DIR}/cmark-gfm_version.h
	@cp cmark-x86_64/src/config.h ${BUILD_DIR}/config.h
	@echo ""

${BUILD_DIR}/libcmark-gfm-arm64.a:
	@echo "${bold}Building cmark for arm64 platform...${normal}"
	@rm -rf "$(PROJECT_DIR)/cmark-arm64" > /dev/null
	${MAKE} CMAKE_OSX_ARCHITECTURES=arm64 CXX="${CXX}" MACOSX_DEPLOYMENT_TARGET=11 BUILDDIR="cmark-arm64" CFLAGS="${CFLAGS} ${CFLAGS_arm64}" CPPFLAGS="${CFLAGS} -std=c++11 ${CFLAGS_arm64}" LDFLAGS="${LDFLAGS_arm64}" -C $(CMARK_DIR) $(ACTION)
	@cp cmark-arm64/src/libcmark-gfm.a ${BUILD_DIR}/libcmark-gfm-arm64.a
	@cp cmark-arm64/src/libcmark-gfm.${SPECVERSION}.0.gfm.11.dylib ${BUILD_DIR}/libcmark-gfm-arm64.${SPECVERSION}.0.gfm.11.dylib
	@cp cmark-arm64/src/cmark-gfm_export.h ${BUILD_DIR}/cmark-gfm_export.h
	@cp cmark-arm64/src/cmark-gfm_version.h ${BUILD_DIR}/cmark-gfm_version.h
	@cp cmark-arm64/src/config.h ${BUILD_DIR}/config.h
	@echo ""

${BUILD_DIR}/libcmark-gfm.a: ${libraries_static}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
		@echo "${bold}Creating cmark universal library...${normal}"
		lipo -create -output ${BUILD_DIR}/libcmark-gfm.a ${BUILD_DIR}/libcmark-gfm-x86_64.a ${BUILD_DIR}/libcmark-gfm-arm64.a
		lipo -create -output ${BUILD_DIR}/libcmark-gfm.${SPECVERSION}.0.gfm.11.dylib ${BUILD_DIR}/libcmark-gfm-x86_64.${SPECVERSION}.0.gfm.11.dylib ${BUILD_DIR}/libcmark-gfm-arm64.${SPECVERSION}.0.gfm.11.dylib
else
		@echo "${bold}Creating cmark library for ${NATIVE_ARCH}...${normal}"
		@rm -f ${BUILD_DIR}/libcmark-gfm.a > /dev/null
		ln ${BUILD_DIR}/libcmark-gfm-${NATIVE_ARCH}.a ${BUILD_DIR}/libcmark-gfm.a
		ln ${BUILD_DIR}/libcmark-gfm-${NATIVE_ARCH}.${SPECVERSION}.0.gfm.11.dylib ${BUILD_DIR}/libcmark-gfm.${SPECVERSION}.0.gfm.11.dylib
endif
	ln -f ${BUILD_DIR}/libcmark-gfm.${SPECVERSION}.0.gfm.11.dylib ${BUILD_DIR}/libcmark-gfm.dylib
	@echo ""

all: check_arch build_dir cmark

clean:
	@rm ${BUILD_DIR}/libcmark-gfm.${SPECVERSION}.0.gfm.11.dylib 2> /dev/null
	@rm ${BUILD_DIR}/libcmark-gfm-x86_64.${SPECVERSION}.0.gfm.11.dylib 2> /dev/null
	@rm ${BUILD_DIR}/libcmark-gfm-arm64.${SPECVERSION}.0.gfm.11.dylib 2> /dev/null
	
	@rm ${BUILD_DIR}/libcmark-gfm.a 2> /dev/null
	@rm ${BUILD_DIR}/libcmark-gfm-x86_64.a 2> /dev/null
	@rm ${BUILD_DIR}/libcmark-gfm-arm64.a 2> /dev/null
	
	@rm -rf "$(PROJECT_DIR)/cmark-x86_64" > /dev/null
	@rm -rf "$(PROJECT_DIR)/cmark-arm64" > /dev/null
