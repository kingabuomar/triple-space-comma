#!/bin/bash
set -euo pipefail

BUNDLE_ID="com.saifqawasmi.triplespacecomma"
LEGACY_BUNDLE_ID="com.codex.triplespacecomma"
APP_PATH="$HOME/Applications/Triple Space Comma.app"
AGENT_PLIST="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
LEGACY_AGENT_PLIST="$HOME/Library/LaunchAgents/$LEGACY_BUNDLE_ID.plist"
LOG_PATH="$HOME/Library/Logs/Triple Space Comma.log"
LEGACY_LOG_PATH="$HOME/Library/Logs/CodexTripleSpaceComma.log"
SUPPORT_DIR="$HOME/Library/Application Support/Triple Space Comma"
LEGACY_SUPPORT_DIR="$HOME/Library/Application Support/CodexTripleSpaceComma"
USER_ID="$(id -u)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TRASH_DIR="$HOME/.Trash/Triple Space Comma Uninstall $STAMP"
SKIP_LAUNCH="${TRIPLE_SPACE_COMMA_SKIP_LAUNCH:-0}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Triple Space Comma supports macOS only." >&2
    exit 1
fi

if [[ "$SKIP_LAUNCH" != "1" ]]; then
    launchctl bootout "gui/$USER_ID" "$AGENT_PLIST" >/dev/null 2>&1 || true
    launchctl bootout "gui/$USER_ID" "$LEGACY_AGENT_PLIST" >/dev/null 2>&1 || true
fi
mkdir -p "$TRASH_DIR"

move_if_present() {
    local source="$1"
    local name="$2"
    if [[ -e "$source" ]]; then
        mv "$source" "$TRASH_DIR/$name"
    fi
}

move_if_present "$APP_PATH" "Triple Space Comma.app"
move_if_present "$AGENT_PLIST" "$BUNDLE_ID.plist"
move_if_present "$LEGACY_AGENT_PLIST" "$LEGACY_BUNDLE_ID.plist"
move_if_present "$LOG_PATH" "Triple Space Comma.log"
move_if_present "$LEGACY_LOG_PATH" "CodexTripleSpaceComma.log"
move_if_present "$SUPPORT_DIR" "Application Support"
move_if_present "$LEGACY_SUPPORT_DIR" "Legacy Application Support"

if [[ "$SKIP_LAUNCH" != "1" ]]; then
    tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || true
    tccutil reset Accessibility "$LEGACY_BUNDLE_ID" >/dev/null 2>&1 || true
fi

if [[ "$SKIP_LAUNCH" != "1" ]] && launchctl print "gui/$USER_ID/$BUNDLE_ID" >/dev/null 2>&1; then
    echo "Uninstall verification failed." >&2
    exit 1
fi

if [[ -e "$APP_PATH" || -e "$AGENT_PLIST" ]]; then
    echo "Uninstall verification failed." >&2
    exit 1
fi

echo "Triple Space Comma was uninstalled. Recoverable files are in:"
echo "$TRASH_DIR"
