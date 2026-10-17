#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="ezku.link"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
FINAL_DMG="$BUILD_DIR/$APP_NAME.dmg"
TMP_DMG="$BUILD_DIR/pack_temp.dmg"
VOL_NAME="$APP_NAME"

echo "=========================================="
echo "💿 Packaging $APP_NAME as macOS .dmg"
echo "=========================================="

# 1. Check or build App Bundle
if [ "$1" == "--rebuild" ] || [ ! -d "$APP_BUNDLE" ]; then
    echo "🔨 Building $APP_NAME application bundle first..."
    "$PROJECT_DIR/Scripts/build_app.sh"
else
    echo "📦 Using existing App Bundle at: $APP_BUNDLE"
fi

# 2. Ensure DMG background graphic exists
BACKGROUND_IMAGE="$PROJECT_DIR/Resources/dmg_background.png"
if [ ! -f "$BACKGROUND_IMAGE" ]; then
    echo "🎨 Rendering custom DMG background artwork..."
    swift "$PROJECT_DIR/Scripts/generate_dmg_background.swift" "$BACKGROUND_IMAGE"
fi

# 3. Clean previous mounts and temporary artifacts
echo "🧹 Cleaning previous mounts and temporary files..."
for m in /Volumes/${VOL_NAME}*; do
    if [ -d "$m" ]; then
        echo "   Detaching existing volume: $m"
        hdiutil detach "$m" -force 2>/dev/null || true
    fi
done
rm -f "$TMP_DMG" "$FINAL_DMG"

# 4. Create blank read-write DMG
echo "💽 Creating read-write DMG container..."
hdiutil create -size 120m -fs HFS+ -volname "$VOL_NAME" "$TMP_DMG" -quiet

# 5. Mount temporary DMG and resolve true mount point
echo "📂 Mounting disk image container..."
ATTACH_INFO=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG")
DEVICE=$(echo "$ATTACH_INFO" | grep Apple_HFS | awk '{print $1}')
MOUNT_POINT=$(echo "$ATTACH_INFO" | sed -n "s/.*Apple_HFS[[:space:]]*//p")

if [ -z "$MOUNT_POINT" ] || [ ! -d "$MOUNT_POINT" ]; then
    echo "❌ Error: Failed to determine mount point."
    exit 1
fi

echo "   Mounted at: $MOUNT_POINT ($DEVICE)"

# 6. Copy Application and link /Applications
echo "📋 Copying $APP_NAME.app into disk image..."
cp -R "$APP_BUNDLE" "$MOUNT_POINT/"

echo "🔗 Creating /Applications symlink..."
ln -s /Applications "$MOUNT_POINT/Applications"

# 7. Add background artwork
echo "🎨 Applying custom background artwork..."
mkdir -p "$MOUNT_POINT/.background"
cp "$BACKGROUND_IMAGE" "$MOUNT_POINT/.background/background.png"

# 8. Configure Finder window styling via AppleScript
echo "📐 Configuring Finder window geometry and drag-and-drop layout..."
osascript << APPLESCRIPT || true
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- Bounds: {left, top, right, bottom} -> 660 width x 420 height
        set the bounds of container window to {400, 150, 1060, 570}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {175, 205}
        set position of item "Applications" of container window to {485, 205}
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

# 9. Set custom Volume Icon (applied after Finder closes so Finder does not remove it)
echo "🏷️  Setting custom DMG volume icon..."
APP_ICON="$PROJECT_DIR/Resources/AppIcon.icns"
if [ -f "$APP_ICON" ]; then
    cp "$APP_ICON" "$MOUNT_POINT/.VolumeIcon.icns"
    SetFile -c icnC "$MOUNT_POINT/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "$MOUNT_POINT" 2>/dev/null || true
fi

# 10. Sync filesystem and unmount
echo "🔒 Unmounting temporary disk image..."
sync
sleep 1
hdiutil detach "$DEVICE" -quiet || { sleep 2; hdiutil detach -force "$DEVICE" -quiet; }

# 11. Convert to highly-compressed read-only UDZO DMG
echo "🗜️  Compressing DMG (UDZO format)..."
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -ov -o "$FINAL_DMG" -quiet
rm -f "$TMP_DMG"

# 12. Code sign the DMG
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
    echo "🔏 Signing DMG with Identity: $SIGNING_IDENTITY..."
    codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$FINAL_DMG" 2>/dev/null || true
else
    echo "🔏 Applying Ad-Hoc Signature to DMG..."
    codesign --force --sign - "$FINAL_DMG" 2>/dev/null || true
fi

# Extract version for informational display
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || echo "1.0.0")
VERSIONED_DMG="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
cp "$FINAL_DMG" "$VERSIONED_DMG"

DMG_SIZE=$(ls -lh "$FINAL_DMG" | awk '{print $5}')

echo ""
echo "=========================================="
echo "🎉 DMG Package Build Complete!"
echo "=========================================="
echo "📦 DMG File: $FINAL_DMG ($DMG_SIZE)"
echo "🏷️  Version:  $VERSION ($VERSIONED_DMG)"
echo ""
echo "To test and open the installer:"
echo "open \"$FINAL_DMG\""
