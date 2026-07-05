#!/bin/bash
# SD003 Phase Switcher
# Usage: ./switch-phase.sh [midpoint|endgame]
#
# 2026-07-05 B18 fix: this script used to require jq to rewrite settings.json.
# Git Bash for Windows may not have jq, in which case the swap silently failed
# ("Error: jq is required") and settings.json was left untouched. It now uses
# switch-phase-update.py (stdlib json, same convention as the other sd003
# hooks) so the phase switch works without jq. Separately (also B18): the
# bash Stop hooks this script swaps in (sd003-stop-hook.sh /
# sd003-stop-hook-endgame.sh) no longer depend on jq themselves (see B2 fix in
# lib_transcript.py), so the swapped-in hook is fully functional on Windows
# even without jq installed.

SETTINGS_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/settings.json"
HOOK_DIR="$(dirname "$0")"

case "$1" in
    midpoint)
        HOOK_FILE="sd003-stop-hook.sh"
        echo "Switching to MIDPOINT phase (loop until tests pass)"
        ;;
    endgame)
        HOOK_FILE="sd003-stop-hook-endgame.sh"
        echo "Switching to ENDGAME phase (escalate after 2 same errors)"
        ;;
    *)
        echo "Usage: $0 [midpoint|endgame]"
        echo ""
        echo "  midpoint - Loop until all tests pass (max 20 iterations)"
        echo "  endgame  - Track errors, escalate to /dialogue-resolution after 2nd occurrence"
        exit 1
        ;;
esac

# Update settings.json (Python - works without jq)
PY_BIN=""
if command -v python >/dev/null 2>&1; then
    PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
    PY_BIN="python3"
fi

if [ -z "$PY_BIN" ]; then
    echo "Error: python (or python3) is required for this script"
    echo "Manual update required in $SETTINGS_FILE"
    exit 1
fi

if "$PY_BIN" "$HOOK_DIR/switch-phase-update.py" "$SETTINGS_FILE" "$HOOK_FILE"; then
    echo "Updated: $SETTINGS_FILE"
    echo "Hook: $HOOK_FILE"
else
    echo "Error: failed to update $SETTINGS_FILE (see message above). Left unchanged."
    exit 1
fi
