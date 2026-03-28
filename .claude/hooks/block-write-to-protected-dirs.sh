#!/bin/bash
# block-write-to-protected-dirs.sh - 保護ディレクトリ内でのvenv/temp環境作成をブロック
# PreToolUse hook for Claude Code (Bash + Write)
#
# ブロック: .sd/ .claude/ .handoff/ 内での uv init, pip install, python -m venv 等
# ブロック: .sd/ .claude/ .handoff/ 内での mkdir ...env/venv/test 等
# 許可: 通常のファイル読み書き（Read/Write/Edit）

INPUT=$(cat)

# command フィールドを抽出（Bashツール用）
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# file_path フィールドを抽出（Writeツール用）
FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# 保護対象ディレクトリのパターン
PROTECTED_PATTERN='(\.sd|\.claude|\.handoff)/'

# --- Bashコマンドのチェック ---
if [ -n "$COMMAND" ]; then
  # uv init / uv venv / uv add / pip install / python -m venv を保護ディレクトリ内で実行
  if echo "$COMMAND" | grep -qiE "(uv (init|venv|add|sync)|pip install|python.*-m.*(venv|virtualenv))" && \
     echo "$COMMAND" | grep -qiE "$PROTECTED_PATTERN"; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: .sd/ .claude/ .handoff/ 内でのvenv/パッケージ環境の作成は禁止です。テスト環境は D:/claudecode/cache/ 等の隔離ディレクトリに作成してください。理由: browser-use検証時に.sd/内にvenvを作成し、クリーンアップで.sd/全体が消失した事故(2026-03-21)の再発防止。"
  }
}
EOF
    exit 0
  fi

  # cd で保護ディレクトリに移動してからの環境構築コマンド
  if echo "$COMMAND" | grep -qiE "cd.*$PROTECTED_PATTERN.*(&&|;).*(uv|pip|python.*venv)"; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: 保護ディレクトリ内でのvenv/パッケージ環境の作成は禁止です。D:/claudecode/cache/ を使用してください。"
  }
}
EOF
    exit 0
  fi
fi

# --- Writeツールのチェック ---
if [ -n "$FILE_PATH" ]; then
  # 保護ディレクトリ内に pyproject.toml / setup.py / requirements.txt を作成
  if echo "$FILE_PATH" | grep -qiE "$PROTECTED_PATTERN" && \
     echo "$FILE_PATH" | grep -qiE "(pyproject\.toml|setup\.py|setup\.cfg|requirements\.txt|\.python-version)$"; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: .sd/ .claude/ .handoff/ 内でのPythonプロジェクトファイル作成は禁止です。テスト環境は D:/claudecode/cache/ に作成してください。"
  }
}
EOF
    exit 0
  fi
fi

exit 0
