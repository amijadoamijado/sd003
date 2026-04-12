#!/bin/bash
# workflow-state-tracker.sh - Track pipeline workflow state transitions
# PostToolUse hook for Claude Code (Bash)
#
# Detects /workflow:impl and /workflow:review execution to maintain
# pipeline state for the workflow-gate.sh PreToolUse hook.
#
# Only activates on pipeline commands. Normal development is unaffected.
#
# State file: .claude/hooks/.workflow-state.json (runtime, gitignored)

INPUT=$(cat)

# Extract command field from JSON
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/hooks/.workflow-state.json"

# Detect impl completion: gemini execution with IMPLEMENT_REQUEST
if echo "$COMMAND" | grep -qiE 'gemini.*IMPLEMENT_REQUEST|IMPLEMENT_REQUEST.*gemini'; then
  # Extract project/task ID from command if possible
  IMPL_ID=$(echo "$COMMAND" | grep -oE '[0-9]{8}-[0-9]{3}-[a-zA-Z0-9_-]+' | head -1)
  if [ -z "$IMPL_ID" ]; then
    IMPL_ID="unknown"
  fi
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$STATE_FILE" <<STATEEOF
{
  "review_pending": true,
  "last_impl": "${IMPL_ID}",
  "last_impl_timestamp": "${TIMESTAMP}",
  "commits_since_impl": 0
}
STATEEOF
  echo "WORKFLOW_STATE: review_pending=true (impl: ${IMPL_ID})" >&2
  exit 0
fi

# Detect review completion: codex review command
if echo "$COMMAND" | grep -qiE 'codex\s+review|workflow:review'; then
  if [ -f "$STATE_FILE" ]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat > "$STATE_FILE" <<STATEEOF
{
  "review_pending": false,
  "last_impl": null,
  "last_impl_timestamp": null,
  "commits_since_impl": 0
}
STATEEOF
    echo "WORKFLOW_STATE: review_pending=false (review completed)" >&2
  fi
  exit 0
fi

# Track commits during pending review (warning counter)
if echo "$COMMAND" | grep -qiE 'git\s+commit'; then
  if [ -f "$STATE_FILE" ]; then
    REVIEW_PENDING=$(sed -n 's/.*"review_pending"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p' "$STATE_FILE" 2>/dev/null || echo "false")
    if [ "$REVIEW_PENDING" = "true" ]; then
      CURRENT_COUNT=$(sed -n 's/.*"commits_since_impl"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$STATE_FILE" 2>/dev/null || echo "0")
      NEW_COUNT=$((CURRENT_COUNT + 1))
      sed -i "s/\"commits_since_impl\"[[:space:]]*:[[:space:]]*[0-9]*/\"commits_since_impl\": ${NEW_COUNT}/" "$STATE_FILE" 2>/dev/null
    fi
  fi
fi

exit 0
