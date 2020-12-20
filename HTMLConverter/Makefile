
htmlconverter.a: htmlconverter.go
	go build --buildmode=c-archive -ldflags "-s -w" -o ./htmlconverter_x86_64.a
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CGO_CFLAGS="-target arm64-apple-macos11" CGO_LDFLAGS="-target arm64-apple-macos11" go build --buildmode=c-archive -ldflags "-s -w" -o ./htmlconverter_arm64.a
	lipo -create -output htmlconverter.a htmlconverter_x86_64.a htmlconverter_arm64.a
	mv htmlconverter_x86_64.h htmlconverter.h
	rm -f ./htmlconverter_arm64.h
	
clean:
	rm -f ./htmlconverter.a
	rm -f ./htmlconverter.h

	rm -f ./htmlconverter_x86_64.a
	rm -f ./htmlconverter_x86_64.h
	rm -f ./htmlconverter_arm64.a
	rm -f ./htmlconverter_arm64.h