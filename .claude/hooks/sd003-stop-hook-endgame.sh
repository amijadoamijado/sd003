#!/bin/bash
# SD003 Stop Hook - Endgame Phase
# Purpose: Track error patterns, escalate to /dialogue-resolution after 2nd occurrence
#
# Exit codes:
#   0 = Success (with JSON output)
#   2 = Block (escalate to dialogue-resolution)
#
# 2026-07-05 B2 fix: the Stop-hook stdin JSON has no `transcript` field -- only
# `transcript_path` (a path to the JSONL transcript file). This hook used to read
# `.transcript` via jq, which is always empty (wrong field) AND requires jq
# (absent on some Git Bash for Windows installs) -> permanent no-op (same-error
# escalation never fired). Now it resolves transcript_path and extracts text via
# lib_transcript.py (stdlib json, no jq dependency; see
# .claude/hooks/claim_evidence_detect.py for the same pattern already used
# elsewhere in this repo). See also B18 (switch-phase.sh).

set -e

HOOK_DIR="$(dirname "$0")"

# Error tracking file
ERROR_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/.error-patterns.log"

# Read JSON input from stdin
INPUT=$(cat)

# Resolve python (Windows: python; Linux/Mac: python3)
PY_BIN=""
if command -v python >/dev/null 2>&1; then
    PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
    PY_BIN="python3"
fi

# Extract transcript text (transcript_path -> JSONL -> plain text). Fail-open to
# empty string if python is unavailable or the file can't be read.
if [ -n "$PY_BIN" ]; then
    TRANSCRIPT=$(printf '%s' "$INPUT" | "$PY_BIN" "$HOOK_DIR/lib_transcript.py" stdin-to-text 2>/dev/null || echo "")
else
    TRANSCRIPT=""
fi

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
