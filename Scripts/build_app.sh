#!/bin/bash
# Builds KeyClick.app without Xcode (uses the Command Line Tools swiftc).
# Output: build/KeyClick.app
set -euo pipefail

cd "$(dirname "$0")/.."
APP=build/KeyClick.app

echo "==> Compiling Swift sources"
mkdir -p build
swiftc -O -parse-as-library \
    -sdk "$(xcrun --show-sdk-path)" \
    -module-cache-path build/ModuleCache \
    -target arm64-apple-macos13.0 \
    App/*.swift Audio/*.swift KeyListener/*.swift Models/*.swift UI/*.swift \
    -o build/KeyClick

echo "==> Assembling app bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp build/KeyClick "$APP/Contents/MacOS/KeyClick"
cp App/Info.plist "$APP/Contents/Info.plist"
# Info.plist in the repo omits CFBundleExecutable; the bundle needs it.
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string KeyClick" "$APP/Contents/Info.plist" 2>/dev/null || true
cp -R Resources/Sounds "$APP/Contents/Resources/Sounds"

echo "==> Code signing (ad-hoc)"
codesign --force --deep --sign - "$APP"

echo "==> Done: $APP"
