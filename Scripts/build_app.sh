#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "⚡ [1/4] Compiling ezku.link (Release mode - Apple Silicon / Native Swift)..."
swift build -c release

BIN_NAME="EzkuLink"
APP_DISPLAY_NAME="ezku.link"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_DISPLAY_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 [2/4] Assembling macOS App Bundle ($APP_BUNDLE)..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/$BIN_NAME" "$MACOS_DIR/$BIN_NAME"
chmod +x "$MACOS_DIR/$BIN_NAME"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy custom AppIcon
echo "🎨 [3/4] Copying custom App Icon..."
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
if [ -f "Resources/AppIcon.png" ]; then
    cp "Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"
fi
if [ -f "Resources/MenuBarIcon.png" ]; then
    cp "Resources/MenuBarIcon.png" "$RESOURCES_DIR/MenuBarIcon.png"
fi
if [ -f "Resources/MenuBarIcon@2x.png" ]; then
    cp "Resources/MenuBarIcon@2x.png" "$RESOURCES_DIR/MenuBarIcon@2x.png"
fi

echo "🔏 [4/4] Applying Ad-Hoc Code Signature..."
codesign --force --deep --sign - --identifier "link.ezku.mac" --entitlements "Resources/EzkuLink.entitlements" "$APP_BUNDLE"

echo "✅ Build Complete! App available at:"
echo "👉 $APP_BUNDLE"
echo ""
echo "To run the app directly in your toolbar:"
echo "open \"$APP_BUNDLE\""
