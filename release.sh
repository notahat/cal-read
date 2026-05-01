#!/bin/bash

# Usage: ./release.sh <version>
# e.g. ./release.sh 1.0.0
#
# Prerequisites — run once to store notarization credentials in your keychain:
# xcrun notarytool store-credentials "notarytool" \
#   --apple-id "pete@notahat.com" \
#   --team-id "EDZJE3T9P5" \
#   --password "xxxx-xxxx-xxxx-xxxx" # app-specific password from appleid.apple.com

set -euo pipefail

VERSION=${1:?"Usage: $0 <version>"}

TEAM_ID="EDZJE3T9P5"
BINARY_NAME="cal-read"
BUILD_PATH=".build/apple/Products/Release/$BINARY_NAME"
ZIP_PATH="build/$BINARY_NAME-$VERSION.zip"

echo "==> Cleaning build directory"
rm -rf build
mkdir -p build

echo "==> Building universal binary"
swift build -c release --arch arm64 --arch x86_64

echo "==> Signing"
codesign \
    --sign "Developer ID Application: Pete Yandell ($TEAM_ID)" \
    --options runtime \
    --timestamp \
    "$BUILD_PATH"

echo "==> Zipping"
zip -j "$ZIP_PATH" "$BUILD_PATH"

echo "==> Notarizing (this may take a minute)"
xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "notarytool" \
    --wait

echo "==> Tagging v$VERSION"
git tag "v$VERSION"
git push origin "v$VERSION"

echo "==> Creating GitHub release v$VERSION"
gh release create "v$VERSION" "$ZIP_PATH" \
    --title "v$VERSION" \
    --generate-notes

echo "==> Done! https://github.com/notahat/cal-read/releases/tag/v$VERSION"
