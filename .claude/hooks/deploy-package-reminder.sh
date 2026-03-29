#!/bin/bash
# deploy-package-reminder.sh - Warn about unupdated deploy package after git commit
# PostToolUse hook for Claude Code (Bash)
#
# Detects git commit and warns if changed files include deploy targets
# (hooks, rules, skills, templates, settings.json etc.) but deploy.ps1/templates
# were not updated.

INPUT=$(cat)

# Extract command field
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# Skip non git-commit commands
if [ -z "$COMMAND" ]; then
  exit 0
fi

if ! echo "$COMMAND" | grep -qiE 'git\s+commit'; then
  exit 0
fi

# Get files changed in the last commit
CHANGED=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "")

if [ -z "$CHANGED" ]; then
  exit 0
fi

# Check if deploy target files were changed
DEPLOY_AFFECTED=false
AFFECTED_FILES=""

# Patterns to check
PATTERNS=(
  ".claude/hooks/"
  ".claude/rules/"
  ".claude/skills/"
  ".claude/commands/"
  ".claude/settings.json"
  ".handoff/"
  ".sd/ai-coordination/workflow/templates/"
  "CLAUDE.md"
)

for pattern in "${PATTERNS[@]}"; do
  matches=$(echo "$CHANGED" | grep "$pattern" || true)
  if [ -n "$matches" ]; then
    DEPLOY_AFFECTED=true
    AFFECTED_FILES="$AFFECTED_FILES\n  - $matches"
  fi
done

if [ "$DEPLOY_AFFECTED" = true ]; then
  # Check if deploy.ps1 itself was updated
  DEPLOY_UPDATED=$(echo "$CHANGED" | grep "deploy.ps1\|deploy.sh\|CLAUDE.md.template" || true)

  if [ -z "$DEPLOY_UPDATED" ]; then
    echo ""
    echo "⚠️  DEPLOY PACKAGE REMINDER ⚠️"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Deploy target files changed but package (deploy.ps1/templates) not updated."
    echo ""
    echo "Changed deploy targets:"
    echo -e "$AFFECTED_FILES"
    echo ""
    echo "Files to check:"
    echo "  - .claude/skills/sd-deploy/deploy.ps1 (FRAMEWORK_VERSION, Phase 5 settings.json)"
    echo "  - .claude/skills/sd-deploy/templates/CLAUDE.md.template"
    echo ""
    echo "Ignore this warning if only rule text was modified."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
fi

exit 0
