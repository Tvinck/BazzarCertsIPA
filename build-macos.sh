#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
mkdir -p dist
xcrun --sdk iphoneos clang -arch arm64 -isysroot "$SDK" \
  -miphoneos-version-min=15.0 -fobjc-arc -fmodules -Wall -Wextra \
  -Wno-unused-parameter -dynamiclib -framework UIKit -framework Foundation \
  -install_name @rpath/BAZZARPanel.dylib BAZZARPanel.m -o dist/BAZZARPanel.dylib
cp BAZZARPanel.plist dist/BAZZARPanel.plist
xcrun --sdk iphoneos nm -gU dist/BAZZARPanel.dylib | grep _BAZZARPresentPanel
echo 'Built arm64 library. Integration, signing and device testing are still required.'
