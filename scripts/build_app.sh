#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-debug}"
case "$CONFIGURATION" in
  debug|release) ;;
  *)
    echo "Usage: scripts/build_app.sh [debug|release]" >&2
    exit 2
    ;;
esac

if [[ "$CONFIGURATION" == "release" ]]; then
  swift build -c release
  BUILD_DIR=".build/release"
else
  swift build
  BUILD_DIR=".build/debug"
fi

APP_NAME="Arkiv"
APP_DIR="dist/${APP_NAME}.app"
EXECUTABLE="${BUILD_DIR}/ArkivMac"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/${APP_NAME}"
chmod +x "$APP_DIR/Contents/MacOS/${APP_NAME}"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>Arkiv</string>
  <key>CFBundleIdentifier</key>
  <string>com.tangfy97.arkiv</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Arkiv</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "Built ${APP_DIR}"
echo "Open it from Finder, or run: open '${APP_DIR}'"
