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

# 4. Code Signing
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
if [ -z "$SIGNING_IDENTITY" ]; then
    DEV_ID=$(security find-identity -p codesigning -v 2>/dev/null | grep "Developer ID Application" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
    if [ -n "$DEV_ID" ]; then
        SIGNING_IDENTITY="$DEV_ID"
    else
        APP_DEV=$(security find-identity -p codesigning -v 2>/dev/null | grep "Apple Development" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
        if [ -n "$APP_DEV" ]; then
            SIGNING_IDENTITY="$APP_DEV"
        else
            SIGNING_IDENTITY="-"
        fi
    fi
fi

if [ "$SIGNING_IDENTITY" != "-" ]; then
    echo "🔏 [4/4] Signing with Identity: $SIGNING_IDENTITY (Hardened Runtime + Timestamp)..."
    codesign --force --deep --options runtime --timestamp --sign "$SIGNING_IDENTITY" --identifier "link.ezku.mac" --entitlements "Resources/EzkuLink.entitlements" "$APP_BUNDLE"
else
    echo "🔏 [4/4] Applying Ad-Hoc Code Signature..."
    codesign --force --deep --sign - --identifier "link.ezku.mac" --entitlements "Resources/EzkuLink.entitlements" "$APP_BUNDLE"
fi

echo "✅ Build Complete! App available at:"
echo "👉 $APP_BUNDLE"
echo ""
echo "To run the app directly in your toolbar:"
echo "open \"$APP_BUNDLE\""
