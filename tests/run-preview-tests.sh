#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
test_build_dir=$(mktemp -d)
trap 'rm -rf "$test_build_dir"' EXIT
xcrun swiftc -target "$(uname -m)-apple-macos12.0" -application-extension tests/PreviewSettingsStub.swift QLExtension/PreviewProvider.swift tests/PreviewNavigationTests.swift -o "$test_build_dir/preview-tests"
"$test_build_dir/preview-tests"
