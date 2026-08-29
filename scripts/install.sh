#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_ID="com.saifqawasmi.triplespacecomma"
LEGACY_BUNDLE_ID="com.codex.triplespacecomma"
SOURCE_APP="$ROOT_DIR/dist/Triple Space Comma.app"
APP_DIR="$HOME/Applications"
APP_PATH="$APP_DIR/Triple Space Comma.app"
AGENT_DIR="$HOME/Library/LaunchAgents"
AGENT_PLIST="$AGENT_DIR/$BUNDLE_ID.plist"
LEGACY_AGENT_PLIST="$AGENT_DIR/$LEGACY_BUNDLE_ID.plist"
LOG_DIR="$HOME/Library/Logs"
LOG_PATH="$LOG_DIR/Triple Space Comma.log"
SUPPORT_DIR="$HOME/Library/Application Support/Triple Space Comma"
USER_ID="$(id -u)"
SKIP_LAUNCH="${TRIPLE_SPACE_COMMA_SKIP_LAUNCH:-0}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Triple Space Comma supports macOS only." >&2
    exit 1
fi

if [[ "${TRIPLE_SPACE_COMMA_BUILD_FROM_SOURCE:-0}" == "1" || ! -d "$SOURCE_APP" ]]; then
    "$ROOT_DIR/scripts/build.sh"
fi

if [[ ! -d "$SOURCE_APP" ]]; then
    echo "Installer could not find a built app at: $SOURCE_APP" >&2
    exit 1
fi

SOURCE_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SOURCE_APP/Contents/Info.plist")"
if [[ "$SOURCE_BUNDLE_ID" != "$BUNDLE_ID" ]]; then
    echo "Unexpected app identity: $SOURCE_BUNDLE_ID" >&2
    exit 1
fi
codesign --verify --deep --strict "$SOURCE_APP"

if [[ "$SKIP_LAUNCH" != "1" ]]; then
    launchctl bootout "gui/$USER_ID" "$AGENT_PLIST" >/dev/null 2>&1 || true
    launchctl bootout "gui/$USER_ID" "$LEGACY_AGENT_PLIST" >/dev/null 2>&1 || true
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$SUPPORT_DIR/backups/$STAMP"
if [[ -e "$APP_PATH" || -e "$AGENT_PLIST" || -e "$LEGACY_AGENT_PLIST" ]]; then
    mkdir -p "$BACKUP_DIR"
    if [[ -e "$APP_PATH" ]]; then
        mv "$APP_PATH" "$BACKUP_DIR/Triple Space Comma.app"
    fi
    if [[ -e "$AGENT_PLIST" ]]; then
        mv "$AGENT_PLIST" "$BACKUP_DIR/$BUNDLE_ID.plist"
    fi
    if [[ -e "$LEGACY_AGENT_PLIST" ]]; then
        mv "$LEGACY_AGENT_PLIST" "$BACKUP_DIR/$LEGACY_BUNDLE_ID.plist"
    fi
fi

mkdir -p "$APP_DIR" "$AGENT_DIR" "$LOG_DIR" "$SUPPORT_DIR"
ditto "$SOURCE_APP" "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"

STAGE_PLIST="$(mktemp "$AGENT_DIR/.triple-space-comma.XXXXXX")"
trap 'rm -f "$STAGE_PLIST"' EXIT
cp "$ROOT_DIR/Resources/com.saifqawasmi.triplespacecomma.plist.template" "$STAGE_PLIST"
/usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $APP_PATH/Contents/MacOS/TripleSpaceComma" "$STAGE_PLIST"
/usr/libexec/PlistBuddy -c "Set :StandardErrorPath $LOG_PATH" "$STAGE_PLIST"
/usr/libexec/PlistBuddy -c "Set :StandardOutPath $LOG_PATH" "$STAGE_PLIST"
plutil -lint "$STAGE_PLIST" >/dev/null
chmod 644 "$STAGE_PLIST"
mv "$STAGE_PLIST" "$AGENT_PLIST"
trap - EXIT

if [[ "$SKIP_LAUNCH" != "1" ]]; then
    launchctl bootstrap "gui/$USER_ID" "$AGENT_PLIST"
    launchctl kickstart -k "gui/$USER_ID/$BUNDLE_ID"
    sleep 1
    launchctl print "gui/$USER_ID/$BUNDLE_ID" >/dev/null
fi

echo
echo "Triple Space Comma is installed and starts automatically at login."
echo "Allow Triple Space Comma in System Settings > Privacy & Security > Accessibility."
echo "Then type any word and press Space three times quickly."
echo
echo "App: $APP_PATH"
echo "Log: $LOG_PATH"
