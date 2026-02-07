#!/bin/bash
set -euo pipefail

APP_NAME="McWritely"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"
VOLUME_NAME="$APP_NAME Installer"

echo "📦 Packaging $APP_NAME..."

# 1. Build the app using existing build script
./build.sh

# 2. Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: $APP_BUNDLE not found. Build failed?"
    exit 1
fi

# 3. Create a temporary directory for the DMG content
rm -rf "dist"
mkdir -p "dist"
cp -R "$APP_BUNDLE" "dist/"
ln -s /Applications "dist/Applications"

if [ ! -e "dist/Applications" ]; then
    echo "❌ Error: dist/Applications link was not created."
    exit 1
fi

# 4. Create DMG
echo "💿 Creating DMG..."
rm -f "$DMG_NAME"
if ! hdiutil create -volname "$VOLUME_NAME" -srcfolder "dist" -ov -format UDZO "$DMG_NAME"; then
    # Intermittently, hdiutil can return "Device not configured" from sandboxed/non-interactive environments.
    # Retry once.
    sleep 1
    hdiutil create -volname "$VOLUME_NAME" -srcfolder "dist" -ov -format UDZO "$DMG_NAME"
fi

# 5. Cleanup
rm -rf "dist"

echo "✅ DMG created: $DMG_NAME"
echo ""
echo "Next steps for official distribution:"
echo "1. Sign the app: codesign --force --options runtime --sign \"Developer ID Application: Your Name\" \"$APP_BUNDLE\""
echo "2. Notarize: xcrun notarytool submit \"$DMG_NAME\" --apple-id \"...\" --password \"...\" --team-id \"...\" --wait"
echo "3. Staple: xcrun stapler staple \"$DMG_NAME\""
