#!/bin/bash
# block-edit-write-on-sd.sh - Block Write/Edit/MultiEdit on .sd/ paths
# PreToolUse hook for Claude Code
#
# Background: Claude Code runtime wipes .sd/ files after Edit/Write tool usage
# followed by Bash commit (anthropics/claude-code#34330 variant).
# Memory: feedback_sd_directory_disappearance.md
# Mitigation: force all .sd/ ops via Bash tool (heredoc/redirect).

INPUT=$(cat)

# Extract file_path from JSON input
FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Normalize path separators (Windows backslash → forward)
NORMALIZED=$(echo "$FILE_PATH" | tr '\\' '/')

# Block if path contains .sd/ (anywhere, since file_path may be absolute or relative)
if echo "$NORMALIZED" | grep -qE '(^|/)\.sd/'; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Write/Edit/MultiEdit on .sd/ paths is prohibited. Reason: Claude Code runtime wipes .sd/ files after Write/Edit + Bash commit (anthropics/claude-code#34330). Use Bash tool instead (heredoc/echo). Example: cat > ${FILE_PATH} << 'EOF' ... EOF"
  }
}
EOF
fi

exit 0
