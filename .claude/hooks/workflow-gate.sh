#!/bin/bash
# workflow-gate.sh - Block git commit when pipeline review is pending
# PreToolUse hook for Claude Code (Bash)
#
# Only active when /workflow:impl has been executed (pipeline mode).
# Normal development (no pipeline) is completely unaffected.
#
# Allow: git commit when review_pending=false (default)
# Block: git commit when review_pending=true (pipeline active, review not done)
# Bypass: SD003_SKIP_REVIEW_GATE=1
#
# State file: .claude/hooks/.workflow-state.json (runtime, gitignored)

INPUT=$(cat)

# Extract command field from JSON
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only gate git commit commands
if ! echo "$COMMAND" | grep -qiE 'git\s+commit'; then
  exit 0
fi

# Emergency bypass
if [ "$SD003_SKIP_REVIEW_GATE" = "1" ]; then
  exit 0
fi

# State file location
STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/hooks/.workflow-state.json"

# Fail open: no state file = no pipeline active = allow
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read review_pending from state file
REVIEW_PENDING=$(sed -n 's/.*"review_pending"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p' "$STATE_FILE" 2>/dev/null || echo "false")

# Not pending = allow (normal development)
if [ "$REVIEW_PENDING" != "true" ]; then
  exit 0
fi

# review_pending=true: check for exempt commit patterns
# Allow session saves and .sd/ restore commits
# Search full INPUT (not COMMAND) to handle escaped quotes in JSON
if echo "$INPUT" | grep -qiE 'session:|fix: restore .sd'; then
  exit 0
fi

# Read last_impl for error message
LAST_IMPL=$(sed -n 's/.*"last_impl"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATE_FILE" 2>/dev/null || echo "unknown")

# Block: pipeline review is pending
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Pipeline review pending for ${LAST_IMPL}. Run /workflow:review before committing.\nBypass: SD003_SKIP_REVIEW_GATE=1"
  }
}
EOF
exit 0
