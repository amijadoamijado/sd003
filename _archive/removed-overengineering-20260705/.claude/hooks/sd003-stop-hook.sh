#!/bin/bash
# SD003 Stop Hook - Midpoint Phase
# Purpose: Loop until all tests pass (max 20 iterations)
#
# Exit codes:
#   0 = Success (stop approved)
#   2 = Block (continue looping)
#
# 2026-07-05 B2 fix: the Stop-hook stdin JSON has no `transcript` field -- only
# `transcript_path` (a path to the JSONL transcript file). This hook used to read
# `.transcript` via jq, which is always empty (wrong field) AND requires jq
# (absent on some Git Bash for Windows installs) -> permanent no-op. Now it
# resolves transcript_path and extracts text via lib_transcript.py (stdlib json,
# no jq dependency; see .claude/hooks/claim_evidence_detect.py for the same
# pattern already used elsewhere in this repo). See also B18 (switch-phase.sh).

set -e

HOOK_DIR="$(dirname "$0")"

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

# Check for test success markers
if echo "$TRANSCRIPT" | grep -qE "(All tests pass|Tests:.*passing|0 failing|ALL_TESTS_PASS)"; then
    # Validate test data quality before approving
    VTD_SCRIPT="$HOOK_DIR/../../scripts/validate-test-data.sh"
    if [ -f "$VTD_SCRIPT" ]; then
        VTD_RESULT=$(bash "$VTD_SCRIPT" 2>&1) || {
            echo '{"decision": "block", "reason": "Tests pass but test data quality validation failed. Fix VTD violations before proceeding."}'
            exit 0
        }
    fi
    echo '{"decision": "approve", "reason": "All tests passed - stopping loop"}'
    exit 0
fi

# Check for explicit completion markers
if echo "$TRANSCRIPT" | grep -qE "(BUILD SUCCESS|Compilation successful|No errors)"; then
    echo '{"decision": "approve", "reason": "Build/compilation successful"}'
    exit 0
fi

# Check for test failures - continue looping
if echo "$TRANSCRIPT" | grep -qE "(FAIL|failing|failed|Error:|error:)"; then
    echo '{"decision": "block", "reason": "Tests still failing - continue loop"}'
    exit 0
fi

# Default: approve stopping (no clear test context)
echo '{"decision": "approve", "reason": "No test context detected"}'
exit 0
