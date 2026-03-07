#!/bin/bash
# SD003 Phase Switcher
# Usage: ./switch-phase.sh [midpoint|endgame]

SETTINGS_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/settings.json"

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

# Update settings.json
if command -v jq &> /dev/null; then
    jq --arg hook "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/$HOOK_FILE\"" \
       '.hooks.Stop[0].hooks[0].command = $hook' \
       "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && \
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    echo "Updated: $SETTINGS_FILE"
    echo "Hook: $HOOK_FILE"
else
    echo "Error: jq is required for this script"
    echo "Manual update required in $SETTINGS_FILE"
    exit 1
fi
