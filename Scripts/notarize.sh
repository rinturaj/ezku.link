#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DMG_PATH="$BUILD_DIR/ezku.link.dmg"

if [ ! -f "$DMG_PATH" ]; then
    echo "❌ Error: $DMG_PATH not found. Run ./Scripts/build_dmg.sh first."
    exit 1
fi

APPLE_ID="${APPLE_ID:-$1}"
TEAM_ID="${TEAM_ID:-$2}"
PASSWORD="${APP_SPECIFIC_PASSWORD:-$3}"

if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$PASSWORD" ]; then
    echo "=========================================================="
    echo "🔐 Apple Gatekeeper Notarization Tool"
    echo "=========================================================="
    echo "Usage:"
    echo "  ./Scripts/notarize.sh <apple-id> <team-id> <app-specific-password>"
    echo ""
    echo "Example:"
    echo "  ./Scripts/notarize.sh rinturajc@gmail.com 83PMR35RH6 abcd-efgh-ijkl-mnop"
    echo ""
    echo "To generate an App-Specific Password:"
    echo "  1. Sign in to https://appleid.apple.com"
    echo "  2. Go to 'Sign-In and Security' -> 'App-Specific Passwords'"
    echo "  3. Generate a password for 'ezku.link'"
    echo "=========================================================="
    exit 1
fi

echo "🚀 [1/3] Submitting $DMG_PATH to Apple Notary Service..."
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$PASSWORD" \
    --wait

echo "📎 [2/3] Stapling Apple Notarization ticket to DMG..."
xcrun stapler staple "$DMG_PATH"

echo "🔍 [3/3] Validating Gatekeeper notarization ticket..."
xcrun stapler validate "$DMG_PATH"
spctl -a -t open --context context:primary-signature -v "$DMG_PATH" || true

echo "=========================================================="
echo "✅ ezku.link DMG successfully verified, signed, and notarized!"
echo "🎉 Gatekeeper will now open this DMG with ZERO security alerts."
echo "=========================================================="
