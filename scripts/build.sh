#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/Triple Space Comma.app"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Triple Space Comma can only be built on macOS." >&2
    exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
    echo "Swift is required. Install Apple's Command Line Tools with: xcode-select --install" >&2
    exit 1
fi

cd "$ROOT_DIR"
UNIVERSAL="${BUILD_UNIVERSAL:-1}"
if [[ "$UNIVERSAL" == "1" ]]; then
    swift build -c release --product TripleSpaceComma --arch arm64
    ARM_BIN="$(swift build -c release --show-bin-path --arch arm64)/TripleSpaceComma"
    swift build -c release --product TripleSpaceComma --arch x86_64
    X86_BIN="$(swift build -c release --show-bin-path --arch x86_64)/TripleSpaceComma"
    if [[ ! -x "$ARM_BIN" || ! -x "$X86_BIN" ]]; then
        echo "Build completed without both architecture executables." >&2
        exit 1
    fi
else
    CURRENT_ARCH="$(uname -m)"
    swift build -c release --product TripleSpaceComma --arch "$CURRENT_ARCH"
    BINARY="$(swift build -c release --show-bin-path --arch "$CURRENT_ARCH")/TripleSpaceComma"
    if [[ ! -x "$BINARY" ]]; then
        echo "Build completed without the expected executable: $BINARY" >&2
        exit 1
    fi
fi

mkdir -p "$DIST_DIR"
STAGE_DIR="$(mktemp -d "$DIST_DIR/.stage.XXXXXX")"
trap 'rm -rf "$STAGE_DIR"' EXIT
STAGE_APP="$STAGE_DIR/Triple Space Comma.app"

mkdir -p "$STAGE_APP/Contents/MacOS" "$STAGE_APP/Contents/Resources"
if [[ "$UNIVERSAL" == "1" ]]; then
    lipo -create "$ARM_BIN" "$X86_BIN" -output "$STAGE_APP/Contents/MacOS/TripleSpaceComma"
else
    cp "$BINARY" "$STAGE_APP/Contents/MacOS/TripleSpaceComma"
fi
cp "$ROOT_DIR/Resources/Info.plist" "$STAGE_APP/Contents/Info.plist"
cp "$ROOT_DIR/assets/AppIcon.icns" "$STAGE_APP/Contents/Resources/AppIcon.icns"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$STAGE_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$STAGE_APP/Contents/Info.plist"
plutil -lint "$STAGE_APP/Contents/Info.plist" >/dev/null
chmod 755 "$STAGE_APP/Contents/MacOS/TripleSpaceComma"
codesign --force --deep --sign - "$STAGE_APP"
codesign --verify --deep --strict "$STAGE_APP"
"$STAGE_APP/Contents/MacOS/TripleSpaceComma" --self-test

rm -rf "$APP_PATH"
mv "$STAGE_APP" "$APP_PATH"

echo "Built $APP_PATH"
lipo -info "$APP_PATH/Contents/MacOS/TripleSpaceComma"
