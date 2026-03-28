#!/bin/bash
# clasp-deploy-tracker.sh - GASファイル修正→push→deployの状態追跡
# PostToolUse hook for Claude Code
#
# 状態遷移:
#   GASファイル編集 → needs-push
#   clasp push      → needs-deploy（pushリマインダー表示）
#   clasp deploy -i → clear（完了）
#
# 状態ファイル: $CLAUDE_PROJECT_DIR/.clasp-deploy-state
#
# 引数: $1 = ツール名 (Edit, Write, Bash)

TOOL_NAME="${1:-Bash}"
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.clasp-deploy-state"
INPUT=$(cat)

# --- JSON からフィールド抽出 ---
extract_field() {
  local field="$1"
  local python_cmd=""
  if command -v python3 &>/dev/null; then python_cmd="python3";
  elif command -v python &>/dev/null; then python_cmd="python"; fi

  if [ -n "$python_cmd" ]; then
    echo "$INPUT" | $python_cmd -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get('tool_input', {})
    print(ti.get('$field', ''))
except:
    print('')
" 2>/dev/null || echo ""
  else
    echo "$INPUT" | sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
  fi
}

# --- GASソースファイル判定 ---
is_gas_file() {
  local path="$1"
  # GAS関連: .ts, .js, .html (src/ 配下), Code.gs 等
  if echo "$path" | grep -qiE '(src/.*\.(ts|js|html)|\.gs$|appsscript\.json)'; then
    return 0
  fi
  return 1
}

# --- 状態読取 ---
read_state() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "clear"
  fi
}

# --- 状態書込 ---
write_state() {
  echo "$1" > "$STATE_FILE"
}

# --- 状態クリア ---
clear_state() {
  rm -f "$STATE_FILE"
}

# ============================================================
# Edit / Write ツール: GASファイル編集の検出
# ============================================================
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(extract_field "file_path")
  if [ -n "$FILE_PATH" ] && is_gas_file "$FILE_PATH"; then
    CURRENT=$(read_state)
    if [ "$CURRENT" = "clear" ] || [ "$CURRENT" = "" ]; then
      write_state "needs-push"
      cat <<'EOF' >&2

📝 GASファイル変更検出 → clasp push が必要です
EOF
    fi
  fi
  exit 0
fi

# ============================================================
# Bash ツール: clasp push / deploy の検出
# ============================================================
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(extract_field "command")
  if [ -z "$COMMAND" ]; then
    exit 0
  fi

  # --- clasp deploy -i 検出 → 状態クリア（完了） ---
  if echo "$COMMAND" | grep -qiE 'clasp\s+deploy\s+-i\s'; then
    clear_state
    cat <<'EOF' >&2

✅ clasp deploy 完了 → 本番URLに反映済み
EOF
    exit 0
  fi

  # --- clasp push 検出 → needs-deploy に遷移 ---
  if echo "$COMMAND" | grep -qiE 'clasp\s+push'; then
    write_state "needs-deploy"
    cat <<'EOF' >&2

⚠️ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  clasp push 完了 → deploy を忘れないでください！
⚠️
⚠️  push は @HEAD（開発版）のみ更新します。
⚠️  本番URLに反映するには deploy が必要:
⚠️
⚠️    clasp deploy -i <デプロイメントID>
⚠️
⚠️  デプロイメントID確認: clasp deployments
⚠️ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 0
  fi
fi

exit 0
