#!/bin/bash
# SD003 Stop Hook - Endgame Phase
# Purpose: Track error patterns, escalate to /dialogue-resolution after 2nd occurrence
#
# Exit codes:
#   0 = Success (with JSON output)
#   2 = Block (escalate to dialogue-resolution)

set -e

# Error tracking file
ERROR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/.error-patterns.log"

# Read JSON input from stdin
INPUT=$(cat)

# Extract transcript/context from input
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript // empty' 2>/dev/null || echo "")

# Check for test success - approve stopping
if echo "$TRANSCRIPT" | grep -qE "(All tests pass|Tests:.*passing|0 failing|ALL_TESTS_PASS)"; then
    # Clear error log on success
    rm -f "$ERROR_LOG" 2>/dev/null || true
    echo '{"decision": "approve", "reason": "All tests passed"}'
    exit 0
fi

# Extract error signature (first error line)
ERROR_SIG=$(echo "$TRANSCRIPT" | grep -oE "(Error:.*|FAIL.*|TypeError.*|ReferenceError.*)" | head -1 | tr -d '\n' | cut -c1-100)

if [ -z "$ERROR_SIG" ]; then
    echo '{"decision": "approve", "reason": "No error pattern detected"}'
    exit 0
fi

# Create error log if not exists
touch "$ERROR_LOG"

# Count occurrences of this error pattern
ERROR_COUNT=$(grep -cF "$ERROR_SIG" "$ERROR_LOG" 2>/dev/null || echo "0")

# Log this occurrence
echo "$ERROR_SIG" >> "$ERROR_LOG"

if [ "$ERROR_COUNT" -ge 1 ]; then
    # 2nd occurrence - escalate
    echo "Same error pattern detected ${ERROR_COUNT} times. Escalating to /dialogue-resolution" >&2
    cat << 'EOF'
{
  "decision": "block",
  "reason": "Same error pattern repeated. Escalate to /dialogue-resolution for structured problem solving.",
  "systemMessage": "ESCALATION: Same error occurred 2+ times. Use /dialogue-resolution to diagnose the root cause through structured dialogue."
}
EOF
    exit 0
else
    # 1st occurrence - allow one more attempt
    cat << EOF
{
  "decision": "block",
  "reason": "Error detected (1st occurrence). One more auto-fix attempt allowed.",
  "systemMessage": "Error pattern logged. If this error repeats, will escalate to /dialogue-resolution."
}
EOF
    exit 0
fi
