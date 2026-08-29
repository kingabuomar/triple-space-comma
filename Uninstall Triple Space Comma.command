#!/bin/bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
/bin/bash "$SCRIPT_DIR/scripts/uninstall.sh"
STATUS=$?
echo
if [[ $STATUS -eq 0 ]]; then
    echo "Uninstallation finished successfully."
else
    echo "Uninstallation failed with status $STATUS."
fi
if [[ -t 0 ]]; then
    read -r -p "Press Return to close this window."
fi
exit "$STATUS"
