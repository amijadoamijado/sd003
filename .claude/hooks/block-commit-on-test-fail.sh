#!/bin/bash
# block-commit-on-test-fail.sh - Block git commit when tests fail
# PreToolUse hook for Claude Code
#
# Allow: git commit (when npm test passes)
# Block: git commit (when npm test fails)
# Bypass: SD003_SKIP_PRECOMMIT_TEST=1

INPUT=$(cat)

# Extract command field from JSON
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Skip non git-commit commands
if ! echo "$COMMAND" | grep -qiE 'git\s+commit'; then
  exit 0
fi

# git commit --amend also gated (same as normal commit)
# git add, git status, git diff etc. already excluded above

# Emergency bypass
if [ "$SD003_SKIP_PRECOMMIT_TEST" = "1" ]; then
  exit 0
fi

# Skip if no package.json (no tests to run)
if [ ! -f "$CLAUDE_PROJECT_DIR/package.json" ]; then
  exit 0
fi

# Run npm test
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
TEST_OUTPUT=$(npm test 2>&1)
TEST_EXIT=$?

if [ $TEST_EXIT -ne 0 ]; then
  # Extract failed test summary (last 20 lines)
  FAIL_SUMMARY=$(echo "$TEST_OUTPUT" | tail -20 | sed 's/"/\\"/g' | tr '\n' ' ')
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Tests are failing. git commit is only allowed after all tests pass.\\nFailure summary: ${FAIL_SUMMARY}\\nBypass: SD003_SKIP_PRECOMMIT_TEST=1"
  }
}
EOF
  exit 0
fi

# Tests passed - allow commit
exit 0
