#!/bin/bash
# deploy-package-reminder.sh - git commit後にデプロイパッケージ未更新を警告
# PostToolUse hook for Claude Code (Bash)
#
# git commit を検知し、変更されたファイルがデプロイ対象（hooks, rules, skills,
# templates, settings.json等）を含む場合、deploy.ps1/テンプレートの更新を促す。

INPUT=$(cat)

# command フィールドを抽出
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# git commit 以外は無視
if [ -z "$COMMAND" ]; then
  exit 0
fi

if ! echo "$COMMAND" | grep -qiE 'git\s+commit'; then
  exit 0
fi

# 直前のコミットで変更されたファイルを取得
CHANGED=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "")

if [ -z "$CHANGED" ]; then
  exit 0
fi

# デプロイ対象ファイルが変更されたかチェック
DEPLOY_AFFECTED=false
AFFECTED_FILES=""

# チェック対象パターン
PATTERNS=(
  ".claude/hooks/"
  ".claude/rules/"
  ".claude/skills/"
  ".claude/commands/"
  ".claude/settings.json"
  ".handoff/"
  ".kiro/ai-coordination/workflow/templates/"
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
  # deploy.ps1自体が更新されているかチェック
  DEPLOY_UPDATED=$(echo "$CHANGED" | grep "deploy.ps1\|deploy.sh\|CLAUDE.md.template" || true)

  if [ -z "$DEPLOY_UPDATED" ]; then
    echo ""
    echo "⚠️  DEPLOY PACKAGE REMINDER ⚠️"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "デプロイ対象ファイルが変更されましたが、パッケージ（deploy.ps1/テンプレート）が未更新です。"
    echo ""
    echo "変更されたデプロイ対象:"
    echo -e "$AFFECTED_FILES"
    echo ""
    echo "確認すべきファイル:"
    echo "  - .claude/skills/kiro-deploy/deploy.ps1 (FRAMEWORK_VERSION, Phase 5 settings.json)"
    echo "  - .claude/skills/kiro-deploy/templates/CLAUDE.md.template"
    echo ""
    echo "不要な場合（ルール文言のみの修正等）はこの警告を無視してください。"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
fi

exit 0
