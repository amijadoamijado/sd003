#!/bin/bash
# clasp-deploy-check-stop.sh - セッション終了時にdeploy漏れチェック
# Stop hook for Claude Code
#
# .clasp-deploy-state が残っている場合、警告を出力する
# needs-push: GASファイル編集済みだがpush未実施
# needs-deploy: push済みだがdeploy未実施

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.clasp-deploy-state"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

STATE=$(cat "$STATE_FILE")

case "$STATE" in
  "needs-push")
    cat <<'EOF' >&2

🚨 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨  GASファイルが変更されていますが push されていません！
🚨
🚨  以下を実行してください:
🚨    1. clasp push
🚨    2. clasp deploy -i <デプロイメントID>
🚨
🚨  本番URLに反映されていない変更があります。
🚨 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 1
    ;;
  "needs-deploy")
    cat <<'EOF' >&2

🚨 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨  clasp push 済みですが deploy されていません！
🚨
🚨  本番URLに反映するには:
🚨    clasp deploy -i <デプロイメントID>
🚨
🚨  デプロイメントID確認: clasp deployments
🚨
🚨  @HEAD のみ更新された状態です。本番URLは古いままです。
🚨 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 1
    ;;
esac

exit 0
