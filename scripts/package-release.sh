#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-1.0.0}"
RELEASE_DIR="$ROOT_DIR/release"
PACKAGE_NAME="Triple Space Comma v$VERSION"
ARCHIVE_NAME="Triple-Space-Comma-v$VERSION.zip"

cd "$ROOT_DIR"
bash "$ROOT_DIR/scripts/test.sh"
VERSION="$VERSION" BUILD_UNIVERSAL=1 bash "$ROOT_DIR/scripts/build.sh"

mkdir -p "$RELEASE_DIR"
STAGE_DIR="$(mktemp -d "$RELEASE_DIR/.stage.XXXXXX")"
trap 'rm -rf "$STAGE_DIR"' EXIT
PACKAGE_DIR="$STAGE_DIR/$PACKAGE_NAME"
mkdir -p "$PACKAGE_DIR"

git archive HEAD | tar -x -C "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/dist"
ditto "$ROOT_DIR/dist/Triple Space Comma.app" "$PACKAGE_DIR/dist/Triple Space Comma.app"

rm -f "$RELEASE_DIR/$ARCHIVE_NAME" "$RELEASE_DIR/SHA256SUMS.txt"
(
    cd "$STAGE_DIR"
    ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_NAME" "$RELEASE_DIR/$ARCHIVE_NAME"
)

(
    cd "$RELEASE_DIR"
    shasum -a 256 "$ARCHIVE_NAME" > SHA256SUMS.txt
)

echo "Created $RELEASE_DIR/$ARCHIVE_NAME"
echo "Created $RELEASE_DIR/SHA256SUMS.txt"
