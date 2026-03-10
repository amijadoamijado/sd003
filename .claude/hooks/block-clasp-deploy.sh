#!/bin/bash
# block-clasp-deploy.sh - clasp deploy の新規作成をブロック
# PreToolUse hook for Claude Code
#
# 許可: clasp deploy -i <ID> （既存デプロイメントの更新）
# 許可: clasp deployments （一覧表示）
# ブロック: clasp deploy（引数なし＝新規作成）
# ブロック: clasp undeploy

INPUT=$(cat)

# jq不要: sed でJSONから command フィールドを抽出
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# clasp deployments（一覧表示）は常に許可
if echo "$COMMAND" | grep -qiE 'clasp\s+deployments'; then
  exit 0
fi

# clasp deploy -i（既存デプロイメント更新）は許可
if echo "$COMMAND" | grep -qiE 'clasp\s+deploy\s+-i\s'; then
  exit 0
fi

# clasp undeploy は常にブロック
if echo "$COMMAND" | grep -qiE 'clasp\s+undeploy'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: clasp undeploy は禁止されています。"
  }
}
EOF
  exit 0
fi

# clasp deploy（-i なし＝新規作成）はブロック
if echo "$COMMAND" | grep -qiE 'clasp\s+deploy'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: clasp deploy（新規作成）は禁止。既存デプロイメントを更新するには clasp deploy -i <デプロイメントID> を使用してください。"
  }
}
EOF
  exit 0
fi

exit 0
