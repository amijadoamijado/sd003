#!/bin/bash
# kiro-watchdog.sh - .kiro/ ディレクトリ消失検知ウォッチドッグ
# PostToolUse hook for Claude Code (all tools)
#
# 全ツール実行後に .kiro/ の存在を確認。
# 消失検知時: 警告のみ。自動復元しない（Write toolの変更を上書きするバグの原因だったため）。
#
# 背景:
#   2026-03-21 .kiro消失事故（AI自身のgit checkout + venvクリーンアップが原因）
#   2026-03-28 自動復元バグ修正: git checkout HEADが Write/sed の変更を上書きしていた
#     原因: watchdogがファイル一時状態を「消失」と誤検知→git checkout HEADで巻き戻し
#     修正: 検知のみ、復元はAIがユーザーに確認してから手動で実行

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
  echo "🚨  直前のツール実行が原因の可能性があります。" >&2
  echo "🚨  復元: git show HEAD:.kiro/sessions/TIMELINE.md > .kiro/sessions/TIMELINE.md" >&2
  echo "🚨 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  exit 0
fi

# Check 2: .kiro/sessions/ directory
if [ ! -d "$SESSIONS_DIR" ]; then
  echo "" >&2
  echo "🚨  WARNING: .kiro/sessions/ が消失しました。" >&2
  echo "🚨  mkdir -p .kiro/sessions && git show HEAD:.kiro/sessions/TIMELINE.md > .kiro/sessions/TIMELINE.md" >&2
  exit 0
fi

# Check 3: TIMELINE.md (最重要ファイル)
if [ ! -f "$TIMELINE" ]; then
  echo "" >&2
  echo "⚠️  WARNING: TIMELINE.md が見つかりません。" >&2
  echo "⚠️  復元: git show HEAD:.kiro/sessions/TIMELINE.md > .kiro/sessions/TIMELINE.md" >&2
  exit 0
fi

# All checks passed - silent exit
exit 0
