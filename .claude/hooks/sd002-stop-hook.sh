#!/bin/bash
# SD002 Stop Hook - Midpoint Phase
# Purpose: Loop until all tests pass (max 20 iterations)
#
# Exit codes:
#   0 = Success (stop approved)
#   2 = Block (continue looping)

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract transcript/context from input
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript // empty' 2>/dev/null || echo "")

# Check for test success markers
if echo "$TRANSCRIPT" | grep -qE "(All tests pass|Tests:.*passing|0 failing|ALL_TESTS_PASS)"; then
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
