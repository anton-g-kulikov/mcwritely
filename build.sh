#!/bin/bash

# Exit on error
set -e

echo "🚀 Building McWritely..."

echo "🚀 Building McWritely (Apple Silicon)..."

# SwiftPM/Clang caches in $HOME may be blocked in sandboxed environments.
export SWIFTPM_DISABLE_SANDBOX=1
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/tmp/clang-module-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"

# Build for arm64
echo "🏗️  Building for arm64..."
swift build -c release --triple arm64-apple-macosx --disable-sandbox

# Find the binary
BINARY_PATH=".build/arm64-apple-macosx/release/McWritely"

# Create .app structure
APP_NAME="McWritely.app"
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
    cat > AppIcon.iconset/Contents.json <<'JSON'
{
  "images": [
    { "size": "16x16", "idiom": "mac", "filename": "icon_16x16.png", "scale": "1x" },
    { "size": "16x16", "idiom": "mac", "filename": "icon_16x16@2x.png", "scale": "2x" },
    { "size": "32x32", "idiom": "mac", "filename": "icon_32x32.png", "scale": "1x" },
    { "size": "32x32", "idiom": "mac", "filename": "icon_32x32@2x.png", "scale": "2x" },
    { "size": "128x128", "idiom": "mac", "filename": "icon_128x128.png", "scale": "1x" },
    { "size": "128x128", "idiom": "mac", "filename": "icon_128x128@2x.png", "scale": "2x" },
    { "size": "256x256", "idiom": "mac", "filename": "icon_256x256.png", "scale": "1x" },
    { "size": "256x256", "idiom": "mac", "filename": "icon_256x256@2x.png", "scale": "2x" },
    { "size": "512x512", "idiom": "mac", "filename": "icon_512x512.png", "scale": "1x" },
    { "size": "512x512", "idiom": "mac", "filename": "icon_512x512@2x.png", "scale": "2x" }
  ],
  "info": { "version": 1, "author": "xcode" }
}
JSON
    if iconutil -c icns AppIcon.iconset -o AppIcon.icns; then
        cp AppIcon.icns "$APP_NAME/Contents/Resources/"
    else
        echo "⚠️  Warning: iconutil failed; continuing without a custom app icon."
    fi
    rm -rf AppIcon.iconset AppIcon.icns
fi

# Copy binary and plist
cp "$BINARY_PATH" "$APP_NAME/Contents/MacOS/McWritely"
cp Info.plist "$APP_NAME/Contents/Info.plist"

echo "✅ App Bundle created: $APP_NAME"
echo ""
echo "To install, move $APP_NAME to your /Applications folder:"
echo "  mv $APP_NAME /Applications/"
echo ""
echo "Note: When you run it for the first time, ensure it is enabled in System Settings > Accessibility."
