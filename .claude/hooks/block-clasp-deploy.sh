#!/bin/bash
# block-clasp-deploy.sh - clasp deploy/undeploy を物理的にブロック
# PreToolUse hook for Claude Code
#
# clasp push のみ許可。deploy/undeploy は強制失敗。
# AI の「守ります」は信用しない。仕組みで止める。

INPUT=$(cat)

# jq不要: sed でJSONから command フィールドを抽出
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# clasp deploy / clasp undeploy を検出（直接実行・npm経由両方）
if echo "$COMMAND" | grep -qiE 'clasp\s+(deploy|undeploy)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: clasp deploy/undeploy は禁止されています。GASのコード反映は clasp push のみ。固定URL更新が必要な場合はユーザーに確認してください。"
  }
}
EOF
  exit 0
fi

exit 0
