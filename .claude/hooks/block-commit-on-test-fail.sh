#!/bin/bash
# block-commit-on-test-fail.sh - Block git commit when tests fail
# PreToolUse hook for Claude Code
#
# Allow: git commit (when npm test passes)
# Block: git commit (when npm test fails)
# Bypass: SD003_SKIP_PRECOMMIT_TEST=1

INPUT=$(cat)

# --- Robust JSON field extraction (Python) --- (B1 fix, see block-sd-destructive.sh)
PY_BIN=""
if command -v python >/dev/null 2>&1; then
  PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
fi

extract_field() {
  if [ -z "$PY_BIN" ]; then
    printf ''
    return
  fi
  SD003_INPUT_JSON="$INPUT" SD003_FIELD="$1" "$PY_BIN" <<'PYEOF'
import os, json
try:
    data = json.loads(os.environ.get('SD003_INPUT_JSON', '') or '{}')
except Exception:
    data = {}
ti = data.get('tool_input', {})
if not isinstance(ti, dict):
    ti = {}
field = os.environ.get('SD003_FIELD', '')
v = ti.get(field)
if v is None:
    v = data.get(field, '')
if v is None:
    v = ''
if not isinstance(v, str):
    try:
        v = json.dumps(v, ensure_ascii=False)
    except Exception:
        v = str(v)
print(v)
PYEOF
}

COMMAND=$(extract_field command)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- B20 fix: precise trigger detection ---
# Old check `grep -qiE 'git\s+commit'` matched the substring ANYWHERE in the
# command, so `echo "git commit"` (just printing the phrase) triggered a full
# `npm test` run. Now: require "git commit" to appear as an actual command
# (start of string, or right after a command separator ; & | ` newline),
# not merely appear inside a quoted string argument to some other command.
is_real_git_commit() {
  if [ -n "$PY_BIN" ]; then
    SD003_CMD="$1" "$PY_BIN" <<'PYEOF'
import os, re, sys
cmd = os.environ.get('SD003_CMD', '')
pattern = re.compile(r'git\s+commit\b', re.IGNORECASE)
for m in pattern.finditer(cmd):
    pre = cmd[:m.start()].rstrip()
    if pre == '' or pre[-1] in ';&|`\n':
        sys.exit(0)
sys.exit(1)
PYEOF
    return $?
  fi
  # No python: coarser fallback, still requires start-of-string or a
  # preceding command separator (not full quote-awareness).
  echo "$1" | grep -qiE '(^|[;&|`])[[:space:]]*git[[:space:]]+commit\b'
}

# Skip non git-commit commands (or "git commit" appearing only as text/args)
if ! is_real_git_commit "$COMMAND"; then
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
  # --- B8 fix: build the deny JSON with a real JSON encoder ---
  # Old code only escaped literal `"` via sed, so a FAIL_SUMMARY containing
  # backslashes (e.g. Windows paths like D:\a\b) or other control chars
  # produced INVALID JSON. Claude Code then silently dropped the deny
  # decision (fail-open) exactly when a test failure should have blocked
  # the commit. Now: last 20 lines are passed to Python and the whole
  # hookSpecificOutput object is built with json.dumps (safe for any input).
  FAIL_SUMMARY=$(echo "$TEST_OUTPUT" | tail -20)
  if [ -n "$PY_BIN" ]; then
    SD003_FAIL_SUMMARY="$FAIL_SUMMARY" "$PY_BIN" <<'PYEOF'
import os, json
summary = os.environ.get('SD003_FAIL_SUMMARY', '')
reason = (
    "BLOCKED: Tests are failing. git commit is only allowed after all tests pass.\n"
    "Failure summary: " + summary + "\n"
    "Bypass: SD003_SKIP_PRECOMMIT_TEST=1"
)
out = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason
    }
}
print(json.dumps(out, ensure_ascii=False))
PYEOF
  else
    # No python: emit a minimal, always-valid JSON without embedding raw
    # (potentially unsafe) test output.
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Tests are failing. git commit is only allowed after all tests pass. Bypass: SD003_SKIP_PRECOMMIT_TEST=1"
  }
}
EOF
  fi
  exit 0
fi

# Tests passed - allow commit
exit 0
