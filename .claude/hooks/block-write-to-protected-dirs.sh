#!/bin/bash
# block-write-to-protected-dirs.sh - Block venv/temp env creation in protected dirs
# PreToolUse hook for Claude Code (Bash + Write)
#
# Block: uv init, pip install, python -m venv in .sd/ .claude/ .handoff/
# Block: mkdir env/venv/test in .sd/ .claude/ .handoff/
# Allow: normal file read/write (Read/Write/Edit)

INPUT=$(cat)

# Extract command field (for Bash tool)
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# Extract file_path field (for Write tool)
FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# Protected directory pattern
PROTECTED_PATTERN='(\.sd|\.claude|\.handoff)/'

# --- Bash command check ---
if [ -n "$COMMAND" ]; then
  # Block uv/pip/venv in protected dirs
  if echo "$COMMAND" | grep -qiE "(uv (init|venv|add|sync)|pip install|python.*-m.*(venv|virtualenv))" && \
     echo "$COMMAND" | grep -qiE "$PROTECTED_PATTERN"; then
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
  if echo "$COMMAND" | grep -qiE "cd.*$PROTECTED_PATTERN.*(&&|;).*(uv|pip|python.*venv)"; then
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
if [ -n "$FILE_PATH" ]; then
  # Block Python project files in protected dirs
  if echo "$FILE_PATH" | grep -qiE "$PROTECTED_PATTERN" && \
     echo "$FILE_PATH" | grep -qiE "(pyproject\.toml|setup\.py|setup\.cfg|requirements\.txt|\.python-version)$"; then
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
