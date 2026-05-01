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

echo "==> Updating Homebrew tap"
SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
TAP_DIR=$(mktemp -d)
git clone git@github.com:notahat/homebrew-tap.git "$TAP_DIR"
mkdir -p "$TAP_DIR/Formula"
cat > "$TAP_DIR/Formula/cal-read.rb" << EOF
class CalRead < Formula
  desc "Query events from Apple Calendar"
  homepage "https://github.com/notahat/cal-read"
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/notahat/cal-read/releases/download/v#{version}/cal-read-#{version}.zip"

  def install
    bin.install "cal-read"
  end
end
EOF
git -C "$TAP_DIR" add Formula/cal-read.rb
git -C "$TAP_DIR" commit -m "Update cal-read to v$VERSION"
git -C "$TAP_DIR" push
rm -rf "$TAP_DIR"

echo "==> Done! https://github.com/notahat/cal-read/releases/tag/v$VERSION"
