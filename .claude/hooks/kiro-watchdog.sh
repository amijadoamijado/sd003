#!/bin/bash
# kiro-watchdog.sh - .kiro/ ディレクトリ消失検知ウォッチドッグ
# PostToolUse hook for Claude Code (Bash)
#
# 全Bashツール実行後に .kiro/ の存在を確認。
# 消失検知時: 即座に警告 + git checkout HEAD で復元を試行。
#
# 背景: 2026-03-21 .kiro消失事故（AI自身のgit checkout + venvクリーンアップが原因）

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
KIRO_DIR="$PROJECT_DIR/.kiro"
SESSIONS_DIR="$KIRO_DIR/sessions"
TIMELINE="$SESSIONS_DIR/TIMELINE.md"

# --- Quick existence checks (fast path) ---

# Check 1: .kiro/ directory
if [ ! -d "$KIRO_DIR" ]; then
  echo "" >&2
  echo "🚨 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "🚨  CRITICAL: .kiro/ ディレクトリが消失しました！" >&2
  echo "🚨" >&2
  echo "🚨  自動復元を試行中..." >&2
  git checkout HEAD -- .kiro/ 2>&1 >&2
  if [ -d "$KIRO_DIR" ]; then
    echo "🚨  ✅ git checkout HEAD -- .kiro/ で復元成功" >&2
    echo "🚨  直前のBashコマンドが原因の可能性。調査してください。" >&2
  else
    echo "🚨  ❌ 復元失敗。手動対応が必要です。" >&2
    echo "🚨  git log --diff-filter=D -- .kiro/ で削除コミットを確認" >&2
  fi
  echo "🚨 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  exit 0
fi

# Check 2: .kiro/sessions/ directory
if [ ! -d "$SESSIONS_DIR" ]; then
  echo "" >&2
  echo "🚨  WARNING: .kiro/sessions/ が消失。復元中..." >&2
  git checkout HEAD -- .kiro/sessions/ 2>&1 >&2
  if [ -d "$SESSIONS_DIR" ]; then
    echo "🚨  ✅ sessions/ 復元成功" >&2
  else
    echo "🚨  ❌ sessions/ 復元失敗" >&2
  fi
  exit 0
fi

# Check 3: TIMELINE.md (最重要ファイル)
if [ ! -f "$TIMELINE" ]; then
  echo "" >&2
  echo "⚠️  WARNING: TIMELINE.md が消失。復元中..." >&2
  git checkout HEAD -- .kiro/sessions/TIMELINE.md 2>&1 >&2
  if [ -f "$TIMELINE" ]; then
    echo "⚠️  ✅ TIMELINE.md 復元成功" >&2
  fi
  exit 0
fi

# All checks passed - silent exit
exit 0
