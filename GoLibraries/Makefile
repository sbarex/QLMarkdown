.PHONY: static

LDFLAGS=-s
GCFLAGS=

libraries = libgoutils_x86_64.a
libraries_shared = libgoutils_x86_64.dylib

ifneq ($(CONFIGURATION),Debug)
	# strip debug symbols
	LDFLAGS += -w
endif

ifneq ($(ONLY_ACTIVE_ARCH),NO)
	# build arm code
	libraries += libgoutils_arm64.a
	libraries_shared += libgoutils_arm64.dylib
endif

static: libgoutils.a
shared: libgoutils.dylib

libgoutils.a: ${libraries}
ifneq ($(ONLY_ACTIVE_ARCH),NO)
	@echo "Creating universal static library…"
	@lipo -create -output libgoutils.a ${libraries}
else
	@cp libgoutils_x86_64.a libgoutils.a
endif

libgoutils_x86_64.a: goutils.go
	@echo "Compiling x86_64 static library…"
	@go build --buildmode=c-archive -gcflags "${GCFLAGS}" -ldflags "${LDFLAGS}" -o ./libgoutils_x86_64.a
	@cp libgoutils_x86_64.h goutils.h

libgoutils_arm64.a: goutils.go
	@echo "Compiling arm64 static library…"
	@GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CGO_CFLAGS="-target arm64-apple-macos11" CGO_LDFLAGS="-target arm64-apple-macos11" go build --buildmode=c-archive -ldflags "${LDFLAGS}" -o ./libgoutils_arm64.a
	@cp libgoutils_arm64.h goutils.h


goutils.dylib: ${libraries_shared}
ifeq ($(CONFIGURATION),Debug)
	@cp -R libgoutils_x86_64.dylib libgoutils.dylib
else
	@echo "Creating the universal shared library…"
	@lipo -create -output libgoutils.dylib ${libraries_shared}
endif

libgoutils_x86_64.dylib: libgoutils.go
	@echo "Compiling x86_64 shared library…"
	@go build --buildmode=c-shared -ldflags "${LDFLAGS}" -o ./libgoutils_x86_64.dylib
	@cp libgoutils_x86_64.h goutils.h

libgoutils_arm64.dylib: libgoutils.go
	@echo "Compiling shared arm64 library"
	@GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CGO_CFLAGS="-target arm64-apple-macos11" CGO_LDFLAGS="-target arm64-apple-macos11" go build --buildmode=c-shared -ldflags "${LDFLAGS}" -o ./libgoutils_arm64.dylib
	@cp libgoutils_arm64.h goutils.h

#    go build --buildmode=c-archive -ldflags "${CGO_LDFLAGS}" -o ./goutils_x86_64.a
#	GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CGO_CFLAGS="-target arm64-apple-macos11" go build --buildmode=c-archive -ldflags "-target arm64-apple-macos11 ${CGO_LDFLAGS}" -o ./goutils_arm64.a
#	lipo -create -output goutils.a goutils_x86_64.a goutils_arm64.a
#	mv goutils_x86_64.h goutils.h
#	rm -f ./goutils_arm64.h
clean:
	@rm -f ./libgoutils.a
	@rm -f ./libgoutils.dylib
	@rm -f ./libgoutils.h

	@rm -f ./libgoutils_x86_64.a
	@rm -f ./libgoutils_x86_64.dylib
	@rm -f ./libgoutils_x86_64.h
	@rm -f ./libgoutils_arm64.a
	@rm -f ./libgoutils_arm64.dylib
	@rm -f ./libgoutils_arm64.h
