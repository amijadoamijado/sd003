#!/bin/bash
# sd-watchdog.sh - .sd/ directory disappearance watchdog
# PostToolUse hook for Claude Code (all tools)
#
# On disappearance: warn only. No auto-restore.
#
# Root cause (2026-03-28 Bug Trace):
#   Claude Code runtime detects settings.json changes via git commit,
#   refreshes worktree, and modified .sd/ files disappear.
#   Fix: added settings.json to .gitignore (removed from git tracking)
#   Refs: anthropics/claude-code#34330, #10011

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SD_DIR="$PROJECT_DIR/.sd"
# B7 fix: the real session store is the ROOT-level .sessions/ directory
# (see .claude/rules/session/session-management.md), not .sd/sessions/.
# The old paths never matched an existing directory, so this watchdog
# always false-warned "WARNING: .sessions/ missing" / never actually
# detected a missing real TIMELINE.md.
SESSIONS_DIR="$PROJECT_DIR/.sessions"
TIMELINE="$SESSIONS_DIR/TIMELINE.md"

if [ ! -d "$SD_DIR" ]; then
  echo "" >&2
  echo "🚨 CRITICAL: .sd/ disappeared! Check recent tool execution." >&2
  exit 0
fi

if [ ! -d "$SESSIONS_DIR" ]; then
  echo "🚨 WARNING: .sessions/ missing." >&2
  exit 0
fi

if [ ! -f "$TIMELINE" ]; then
  echo "⚠️ WARNING: TIMELINE.md missing." >&2
  exit 0
fi

exit 0
# test
