#!/bin/bash
# track-skill-read.sh - Track which SKILL.md files have been Read in this session
# PostToolUse hook for Claude Code (Read)
#
# Records skill IDs to ~/.claude/state/sd003/read-skills.log when AI reads
# .claude/skills/<skill-id>/SKILL.md
#
# Pairs with enforce-skill-read.sh (PreToolUse) which checks the same log
# to decide whether to block file operations on registered skill targets.

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# Only Read tool is interesting
if [ "$TOOL_NAME" != "Read" ]; then
  exit 0
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Match .claude/skills/<skill-id>/SKILL.md (forward or back slash)
SKILL_ID=$(echo "$FILE_PATH" | sed -n 's|.*\.claude[/\\]skills[/\\]\([^/\\]*\)[/\\]SKILL\.md.*|\1|p')

if [ -z "$SKILL_ID" ]; then
  exit 0
fi

LOG_DIR="$HOME/.claude/state/sd003"
LOG_FILE="$LOG_DIR/read-skills.log"

mkdir -p "$LOG_DIR" 2>/dev/null

# Append only if not already present (idempotent)
if [ ! -f "$LOG_FILE" ] || ! grep -qx "$SKILL_ID" "$LOG_FILE" 2>/dev/null; then
  echo "$SKILL_ID" >> "$LOG_FILE"
fi

exit 0
