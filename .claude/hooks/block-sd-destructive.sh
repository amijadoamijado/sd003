#!/bin/bash
# block-sd-destructive.sh - Block all destructive operations on .sd/
# PreToolUse hook for Claude Code (Bash)
#
# Blocked:
#   - git checkout -- .sd/ / git checkout -- . (file overwrite)
#   - git checkout HEAD -- .sd/ (revert to HEAD)
#   - git stash (stash = remove from worktree)
#   - git clean (delete untracked files)
#   - git restore .sd/ / git restore . (restore = overwrite)
#   - git reset --hard (discard all changes)
#   - rm / rm -rf .sd (direct delete)
#   - mv .sd (directory move)
#
# Allowed:
#   - git add .sd/ (staging)
#   - git commit (commit)
#   - git diff / git status / git log (read-only)
#   - Read/Write/Edit on .sd/ files
#
# Background: 2026-03-21 .sd disappearance incident
#   Cause 1: AI ran git checkout HEAD -> sessions lost
#   Cause 2: AI created venv inside .sd/ -> cleanup deleted everything
#   Cause 3: Periodic disappearance between tool calls = repetition of cause 1
#   Common pattern: AI Bash commands destroyed .sd

INPUT=$(cat)

# --- Robust JSON field extraction (Python) ---
# Fixes: sed 's/.*"command"...:"\([^"]*\)".*/\1/p' stopped at the FIRST double
# quote, so `echo "hi" && rm -rf .sd` only ever yielded `echo \` and the
# dangerous tail was never inspected by any pattern below (total bypass).
PY_BIN=""
if command -v python >/dev/null 2>&1; then
  PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
fi

extract_field() {
  # Usage: extract_field <json-field-name>  (reads $INPUT)
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

# === Pattern 1: git checkout targeting root (.) or .sd ===
# Handles: `git checkout .` / `git checkout HEAD .` (no --) / `git checkout -- .`
# / `git checkout HEAD -- .` / `git -C . checkout HEAD -- .sd` (interposed -C).
# Only the arguments AFTER the `checkout` keyword are scanned for the
# dangerous target, so `git -C . checkout mybranch` (unrelated to .sd) is not
# falsely blocked by the `-C .` token.
if echo "$COMMAND" | grep -qiE 'git(\s+-C\s+\S+)?\s+checkout\b'; then
  CHECKOUT_ARGS=$(echo "$COMMAND" | grep -oiE 'checkout\b.*' | head -1)
  if [ -n "$CHECKOUT_ARGS" ] && { echo "$CHECKOUT_ARGS" | grep -qE '(^|[[:space:]])\.([[:space:]]|$)' || echo "$CHECKOUT_ARGS" | grep -qiE '\.sd(\b|/)'; }; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git checkout targeting . or .sd/ is prohibited (with or without --, with or without -C interposition). .sd/ files will be overwritten/lost. Prevention for 2026-03-21 incident. Ask user before restoring individual files."
  }
}
EOF
    exit 0
  fi
fi

# === Pattern 3: git stash (push/save/no args) ===
# git stash list / git stash show are allowed
if echo "$COMMAND" | grep -qiE 'git\s+stash(\s|$)' && \
   ! echo "$COMMAND" | grep -qiE 'git\s+stash\s+(list|show|drop|pop|apply|branch)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git stash is prohibited. .sd/ changes will be removed from worktree. Use git commit to save changes."
  }
}
EOF
  exit 0
fi

# === Pattern 4: git clean ===
if echo "$COMMAND" | grep -qiE 'git\s+clean'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git clean is prohibited. Untracked files in .sd/ may be deleted."
  }
}
EOF
  exit 0
fi

# === Pattern 5: git restore .sd / git restore . ===
# Fixed: the old regex embedded a `^` mid-alternation (`.*(\.sd|^\.\s|...)`)
# which can never match after `.*` has already consumed characters, so
# `git restore .` was silently NEVER denied. Now we isolate the arguments
# after `restore` and check for a standalone `.` token or a `.sd` target.
if echo "$COMMAND" | grep -qiE 'git\s+restore\b'; then
  RESTORE_ARGS=$(echo "$COMMAND" | grep -oiE 'restore\b.*' | head -1)
  if [ -n "$RESTORE_ARGS" ] && { echo "$RESTORE_ARGS" | grep -qE '(^|[[:space:]])\.([[:space:]]|$)' || echo "$RESTORE_ARGS" | grep -qiE '\.sd(\b|/)'; }; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git restore .sd/ or git restore . is prohibited. .sd/ files will be reverted to HEAD state."
  }
}
EOF
    exit 0
  fi
fi

# === Pattern 6: git reset --hard ===
if echo "$COMMAND" | grep -qiE 'git\s+reset\s+--hard'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git reset --hard is prohibited. All changes including .sd/ will be discarded."
  }
}
EOF
  exit 0
fi

# === Pattern 7: rm / rm -rf .sd (any option style, absolute or relative path) ===
# Fixed: old regex only consumed short-style flags (`-[a-z]*`), so long options
# (`rm --recursive --force .sd`) were not matched. Also only matched a literal
# `.sd` / `./.sd` prefix, so an absolute path like
# `rm -rf D:/claudecode/sd003/.sd` was never matched. Now: find every `rm`
# invocation up to the next command separator (;, &, |) and check whether ANY
# of them targets a `.sd` path *segment* (preceded by start/slash/space,
# followed by slash/space/end) -- this matches absolute paths, long options,
# and multiple chained rm calls, while NOT matching unrelated dirs like
# `./build`, `.sdcard`, or `test/.sd-backup`.
RM_SEGMENTS=$(echo "$COMMAND" | grep -oiE '\brm\b[^;&|]*')
if [ -n "$RM_SEGMENTS" ] && echo "$RM_SEGMENTS" | grep -qiE '(^|[/[:space:]])\.sd([/[:space:]]|$)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Direct deletion (rm) of .sd/ is prohibited (any flag style, absolute or relative path). Use archive instead."
  }
}
EOF
  exit 0
fi

# === Pattern 8: mv .sd (any option style, absolute or relative path) ===
MV_SEGMENTS=$(echo "$COMMAND" | grep -oiE '\bmv\b[^;&|]*')
if [ -n "$MV_SEGMENTS" ] && echo "$MV_SEGMENTS" | grep -qiE '(^|[/[:space:]])\.sd([/[:space:]]|$)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Moving .sd/ is prohibited. .sd/ is a core project directory."
  }
}
EOF
  exit 0
fi

# === Pattern 9: find .sd ... -delete / -exec rm ===
FIND_SEGMENTS=$(echo "$COMMAND" | grep -oiE '\bfind\b[^;&|]*')
if [ -n "$FIND_SEGMENTS" ] && echo "$FIND_SEGMENTS" | grep -qiE '(^|[/[:space:]])\.sd([/[:space:]]|$)' && echo "$FIND_SEGMENTS" | grep -qiE '(-delete\b|-exec\s+rm\b)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: find .sd/ ... -delete (or -exec rm) is prohibited. Untracked/tracked files in .sd/ may be deleted."
  }
}
EOF
  exit 0
fi

# === Pattern 10: PowerShell Remove-Item targeting .sd (e.g. via pwsh -Command "...") ===
if echo "$COMMAND" | grep -qiE 'Remove-Item' && echo "$COMMAND" | grep -qiE '(^|[/\\]|[[:space:]])\.sd([/\\]|[[:space:]]|$)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: PowerShell Remove-Item targeting .sd/ is prohibited. .sd/ is a core project directory."
  }
}
EOF
  exit 0
fi

# All checks passed
exit 0
