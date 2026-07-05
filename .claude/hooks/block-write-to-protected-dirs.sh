#!/bin/bash
# block-write-to-protected-dirs.sh - Block venv/temp env creation in protected dirs
# PreToolUse hook for Claude Code (Bash + Write)
#
# Block: uv init, pip install, python -m venv in .sd/ .claude/ .handoff/
# Block: mkdir env/venv/test in .sd/ .claude/ .handoff/
# Allow: normal file read/write (Read/Write/Edit)

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

# Extract command field (for Bash tool)
COMMAND=$(extract_field command)

# Extract file_path field (for Write tool)
FILE_PATH=$(extract_field file_path)

# --- B4 fix: normalize path separators before matching ---
# Windows backslash paths (e.g. "D:\claudecode\sd003\.sd\pyproject.toml")
# previously bypassed the forward-slash-only PROTECTED_PATTERN entirely.
# Mirrors block-edit-write-on-sd.sh's `tr '\\' '/'` normalization.
COMMAND_NORM=$(printf '%s' "$COMMAND" | tr '\\' '/')
FILE_PATH_NORM=$(printf '%s' "$FILE_PATH" | tr '\\' '/')

# Protected directory pattern
PROTECTED_PATTERN='(\.sd|\.claude|\.handoff)/'

# --- Bash command check ---
if [ -n "$COMMAND_NORM" ]; then
  # Block uv/pip/venv in protected dirs
  if echo "$COMMAND_NORM" | grep -qiE "(uv (init|venv|add|sync)|pip install|python.*-m.*(venv|virtualenv))" && \
     echo "$COMMAND_NORM" | grep -qiE "$PROTECTED_PATTERN"; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Creating venv/package environments inside .sd/ .claude/ .handoff/ is prohibited. Use D:/claudecode/cache/ instead. Reason: 2026-03-21 incident where venv inside .sd/ caused full directory loss on cleanup."
  }
}
EOF
    exit 0
  fi

  # Block cd to protected dir then env setup
  if echo "$COMMAND_NORM" | grep -qiE "cd.*$PROTECTED_PATTERN.*(&&|;).*(uv|pip|python.*venv)"; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Creating venv/package environments inside protected directories is prohibited. Use D:/claudecode/cache/ instead."
  }
}
EOF
    exit 0
  fi
fi

# --- Write tool check ---
if [ -n "$FILE_PATH_NORM" ]; then
  # Block Python project files in protected dirs
  if echo "$FILE_PATH_NORM" | grep -qiE "$PROTECTED_PATTERN" && \
     echo "$FILE_PATH_NORM" | grep -qiE "(pyproject\.toml|setup\.py|setup\.cfg|requirements\.txt|\.python-version)$"; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Creating Python project files inside .sd/ .claude/ .handoff/ is prohibited. Use D:/claudecode/cache/ instead."
  }
}
EOF
    exit 0
  fi
fi

exit 0
