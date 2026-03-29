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

# Extract command field
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# === Pattern 1: git checkout -- . / git checkout -- .sd ===
if echo "$COMMAND" | grep -qiE 'git\s+checkout\s+.*--\s+(\.sd|\.(/|$))'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git checkout -- .sd/ is prohibited. .sd/ files will be overwritten/lost. Prevention for 2026-03-21 incident. Ask user before restoring individual files."
  }
}
EOF
  exit 0
fi

# === Pattern 2: git checkout <ref> -- . (full checkout) ===
if echo "$COMMAND" | grep -qiE 'git\s+checkout\s+\S+\s+--\s+\.$'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git checkout <ref> -- . is prohibited. All files including .sd/ will be overwritten. Specify target files explicitly (excluding .sd/)."
  }
}
EOF
  exit 0
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
if echo "$COMMAND" | grep -qiE 'git\s+restore\s+.*(\.sd|^\.\s|--\s+\.)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git restore .sd/ is prohibited. .sd/ files will be reverted to HEAD state."
  }
}
EOF
  exit 0
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

# === Pattern 7: rm / rm -rf .sd ===
if echo "$COMMAND" | grep -qiE '(rm\s+(-[a-z]*\s+)*\.sd|rm\s+(-[a-z]*\s+)*\./\.sd)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Direct deletion (rm) of .sd/ is prohibited. Use archive instead."
  }
}
EOF
  exit 0
fi

# === Pattern 8: mv .sd ===
if echo "$COMMAND" | grep -qiE 'mv\s+(-[a-z]*\s+)*\.sd'; then
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

# All checks passed
exit 0
