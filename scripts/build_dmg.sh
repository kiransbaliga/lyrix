#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

echo "🔨 Step 1: Building Lyrix executable..."
swift build -c release

BUILD_DIR="$DIR/.build/release"
APP_DIR="$DIR/dist/Lyrix.app"
DMG_OUTPUT="$DIR/dist/Lyrix-Installer.dmg"

rm -rf "$DIR/dist"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/lib"
mkdir -p "$APP_DIR/Contents/Frameworks"

echo "🎨 Step 2: Preparing assets (Black squircle icon & white text background)..."
python3 "$DIR/scripts/prepare_assets.py"

echo "📦 Step 3: Assembling Lyrix.app bundle..."
cp "$BUILD_DIR/Lyrix" "$APP_DIR/Contents/MacOS/Lyrix"
chmod +x "$APP_DIR/Contents/MacOS/Lyrix"

# Bundle full media-control runtime (script + helper framework + adapter) for 100% standalone operation
BREW_MC="/opt/homebrew/Cellar/media-control/0.7.6"
if [ -d "$BREW_MC" ]; then
    cp "$BREW_MC/bin/media-control" "$APP_DIR/Contents/MacOS/media-control"
    cp -R "$BREW_MC/lib/"* "$APP_DIR/Contents/lib/"
    cp -R "$BREW_MC/Frameworks/"* "$APP_DIR/Contents/Frameworks/"
    
    chmod +x "$APP_DIR/Contents/MacOS/media-control"
    chmod +x "$APP_DIR/Contents/lib/media-control/mediaremote-adapter.pl"
    chmod +x "$APP_DIR/Contents/lib/media-control/MediaRemoteAdapterTestClient"
    chmod +x "$APP_DIR/Contents/Frameworks/MediaRemoteAdapter.framework/MediaRemoteAdapter"
    echo "  ✅ Bundled full media-control framework runtime inside Lyrix.app"
fi

# Write Info.plist
cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Lyrix</string>
    <key>CFBundleIdentifier</key>
    <string>com.hobby.lyrix</string>
    <key>CFBundleName</key>
    <string>Lyrix</string>
    <key>CFBundleDisplayName</key>
    <string>Lyrix</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

echo "🚀 Step 4: Building precision DMG with dmgbuild..."
rm -f "$DMG_OUTPUT"
python3 -m dmgbuild -s "$DIR/scripts/dmgbuild_settings.py" "Lyrix Installer" "$DMG_OUTPUT"

rm -f "$DIR/dist/dmg_background.png" "$DIR/dist/dmg_background@2x.png" "$DIR/dist/master_icon.png"
rm -rf "$DIR/dist/AppIcon.iconset"

echo "✨ SUCCESS! Created standalone installer at:"
echo "👉 $DMG_OUTPUT"
ls -lh "$DMG_OUTPUT"
