#!/bin/bash

# Exit on error
set -e

echo "🚀 Building Writely..."

echo "🚀 Building Writely (Apple Silicon)..."

# Build for arm64
echo "🏗️  Building for arm64..."
swift build -c release --triple arm64-apple-macosx

# Find the binary
BINARY_PATH=".build/arm64-apple-macosx/release/Writely"

# Create .app structure
APP_NAME="Writely.app"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

# Copy and process icon
if [ -f "icon.png" ]; then
    echo "🎨 Generating AppIcon.icns..."
    mkdir -p AppIcon.iconset
    sips -z 16 16     icon.png -s format png --out AppIcon.iconset/icon_16x16.png
    sips -z 32 32     icon.png -s format png --out AppIcon.iconset/icon_16x16@2x.png
    sips -z 32 32     icon.png -s format png --out AppIcon.iconset/icon_32x32.png
    sips -z 64 64     icon.png -s format png --out AppIcon.iconset/icon_32x32@2x.png
    sips -z 128 128   icon.png -s format png --out AppIcon.iconset/icon_128x128.png
    sips -z 256 256   icon.png -s format png --out AppIcon.iconset/icon_128x128@2x.png
    sips -z 256 256   icon.png -s format png --out AppIcon.iconset/icon_256x256.png
    sips -z 512 512   icon.png -s format png --out AppIcon.iconset/icon_256x256@2x.png
    sips -z 512 512   icon.png -s format png --out AppIcon.iconset/icon_512x512.png
    sips -z 1024 1024 icon.png -s format png --out AppIcon.iconset/icon_512x512@2x.png
    iconutil -c icns AppIcon.iconset
    cp AppIcon.icns "$APP_NAME/Contents/Resources/"
    rm -rf AppIcon.iconset AppIcon.icns
fi

# Copy binary and plist
cp "$BINARY_PATH" "$APP_NAME/Contents/MacOS/Writely"
cp Info.plist "$APP_NAME/Contents/Info.plist"

echo "✅ App Bundle created: $APP_NAME"
echo ""
echo "To install, move $APP_NAME to your /Applications folder:"
echo "  mv $APP_NAME /Applications/"
echo ""
echo "Note: When you run it for the first time, ensure it is enabled in System Settings > Accessibility."
