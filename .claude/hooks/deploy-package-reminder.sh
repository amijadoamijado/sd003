#!/bin/bash
# deploy-package-reminder.sh - Warn about unupdated deploy package after git commit
# PostToolUse hook for Claude Code (Bash)
#
# Detects git commit and warns if changed files include deploy targets
# (hooks, rules, skills, templates, settings.json etc.) but deploy.ps1/templates
# were not updated.

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
