.PHONY: static

LDFLAGS=-s
GCFLAGS=

ifeq ($(ONLY_ACTIVE_ARCH),)
	ONLY_ACTIVE_ARCH=YES
endif

ifndef NATIVE_ARCH
	NATIVE_ARCH := $(shell uname -m)
	# $(error NATIVE_ARCH is not set)
endif

ifeq ($(BUILT_PRODUCTS_DIR),)
	BUILD_DIR=build
else
	BUILD_DIR=${BUILT_PRODUCTS_DIR}
endif

libraries = ${BUILD_DIR}/libgoutils-${NATIVE_ARCH}.a
libraries_shared = ${BUILD_DIR}/libgoutils-${NATIVE_ARCH}.dylib

ifeq ($(ONLY_ACTIVE_ARCH),NO)
ifeq ($(NATIVE_ARCH),x86_64)
	# build arm code
	libraries += ${BUILD_DIR}/libgoutils-arm64.a
	libraries_shared += ${BUILD_DIR}/libgoutils-arm64.dylib
else
	# build intel code
	libraries += ${BUILD_DIR}/libgoutils-x86_64.a
	libraries_shared += ${BUILD_DIR}/libgoutils-x86_64.dylib
endif
endif

ifneq ($(CONFIGURATION),Debug)
	# strip debug symbols
	LDFLAGS += -w
endif

static: ${BUILD_DIR}/libgoutils.a
shared: ${BUILD_DIR}/libgoutils.dylib

${BUILD_DIR}/libgoutils.a: ${libraries}
ifeq ($(ONLY_ACTIVE_ARCH),NO)
	@echo "Creating universal static library…"
	@lipo -create -output ${BUILD_DIR}/libgoutils.a ${libraries}
else
	@echo "Creating ${NATIVE_ARCH} static library…"
	@ln ${BUILD_DIR}/libgoutils-${NATIVE_ARCH}.a ${BUILD_DIR}/libgoutils.a
endif

${BUILD_DIR}/libgoutils-x86_64.a: goutils.go
	@echo "Compiling x86_64 static library…"
	@CGO_CFLAGS="-mmacosx-version-min=10.15" go build --buildmode=c-archive -gcflags "${GCFLAGS}" -ldflags "${LDFLAGS}" -o ${BUILD_DIR}/libgoutils-x86_64.a
	@cp ${BUILD_DIR}/libgoutils-x86_64.h ${BUILD_DIR}/goutils.h

${BUILD_DIR}/libgoutils-arm64.a: goutils.go
	@echo "Compiling arm64 static library…"
	@GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CGO_CFLAGS="-target arm64-apple-macos11" CGO_LDFLAGS="-target arm64-apple-macos11" go build --buildmode=c-archive -ldflags "${LDFLAGS}" -o ${BUILD_DIR}/libgoutils-arm64.a
	@cp ${BUILD_DIR}/libgoutils-arm64.h ${BUILD_DIR}/goutils.h

${BUILD_DIR}/goutils.dylib: ${libraries_shared}
ifeq ($(ONLY_ACTIVE_ARCH),YES)
		@echo "Creating the ${NATIVE_ARCH} shared library…"
	@ln -R ${BUILD_DIR}/libgoutils-${NATIVE_ARCH}.dylib ${BUILD_DIR}/libgoutils.dylib
else
	@echo "Creating the universal shared library…"
	@lipo -create -output ${BUILD_DIR}/libgoutils.dylib ${libraries_shared}
endif

${BUILD_DIR}/libgoutils-x86_64.dylib: goutils.go
	@echo "Compiling x86_64 shared library…"
	@CGO_CFLAGS="-mmacosx-version-min=10.15" go build --buildmode=c-shared -ldflags "${LDFLAGS}" -o ${BUILD_DIR}/libgoutils-x86_64.dylib
	@cp ${BUILD_DIR}/libgoutils-x86_64.h ${BUILD_DIR}/goutils.h

${BUILD_DIR}/libgoutils-arm64.dylib: goutils.go
	@echo "Compiling shared arm64 library"
	@GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CGO_CFLAGS="-target arm64-apple-macos11" CGO_LDFLAGS="-target arm64-apple-macos11" go build --buildmode=c-shared -ldflags "${LDFLAGS}" -o ${BUILD_DIR}/libgoutils-arm64.dylib
	@cp ${BUILD_DIR}/libgoutils-arm64.h ${BUILD_DIR}/goutils.h

#    go build --buildmode=c-archive -ldflags "${CGO_LDFLAGS}" -o ./goutils-x86_64.a
#	GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CGO_CFLAGS="-target arm64-apple-macos11" go build --buildmode=c-archive -ldflags "-target arm64-apple-macos11 ${CGO_LDFLAGS}" -o ./goutils_arm64.a
#	lipo -create -output goutils.a goutils-x86_64.a goutils_arm64.a
#	mv goutils-x86_64.h goutils.h
#	rm -f ./goutils_arm64.h
clean:
	@rm -f ${BUILD_DIR}/libgoutils.a
	@rm -f ${BUILD_DIR}/libgoutils.dylib
	@rm -f ${BUILD_DIR}/libgoutils.h

	@rm -f ${BUILD_DIR}/libgoutils-x86_64.a
	@rm -f ${BUILD_DIR}/libgoutils-x86_64.dylib
	@rm -f ${BUILD_DIR}/libgoutils-x86_64.h
	@rm -f ${BUILD_DIR}/libgoutils-arm64.a
	@rm -f ${BUILD_DIR}/libgoutils-arm64.dylib
	@rm -f ${BUILD_DIR}/libgoutils-arm64.h
