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
    echo "  ./Scripts/notarize.sh rinturajc@gmail.com 53647RA5WL abcd-efgh-ijkl-mnop"
    echo ""
    echo "To generate an App-Specific Password:"
    echo "  1. Sign in to https://appleid.apple.com"
    echo "  2. Go to 'Sign-In and Security' -> 'App-Specific Passwords'"
    echo "  3. Generate a password for 'ezku.link'"
    echo "=========================================================="
    exit 1
fi

echo "🚀 [1/2] Submitting $DMG_PATH to Apple Notary Service..."
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$PASSWORD" \
    --wait

echo "📎 [2/2] Stapling notarization ticket to DMG..."
xcrun stapler staple "$DMG_PATH"

echo "✅ ezku.link DMG successfully notarized and stapled!"
echo "🎉 Users downloading this DMG will open it directly with ZERO Gatekeeper warnings."
