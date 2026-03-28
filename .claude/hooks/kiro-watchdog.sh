#!/bin/bash
# kiro-watchdog.sh - .kiro/ ディレクトリ消失検知ウォッチドッグ
# PostToolUse hook for Claude Code (all tools)
#
# 消失検知時: 警告のみ。自動復元しない。
#
# 根本原因 (2026-03-28 Bug Trace):
#   Claude Codeランタイムがsettings.jsonの変更をgit commit経由で検知すると
#   ワーキングツリーをリフレッシュし、modified状態の.kiro/ファイルが消失する。
#   対策: settings.jsonを.gitignoreに追加（git管理外にした）
#   Refs: anthropics/claude-code#34330, #10011

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
KIRO_DIR="$PROJECT_DIR/.kiro"
SESSIONS_DIR="$KIRO_DIR/sessions"
TIMELINE="$SESSIONS_DIR/TIMELINE.md"

if [ ! -d "$KIRO_DIR" ]; then
  echo "" >&2
  echo "🚨 CRITICAL: .kiro/ disappeared! Check recent tool execution." >&2
  exit 0
fi

if [ ! -d "$SESSIONS_DIR" ]; then
  echo "🚨 WARNING: .kiro/sessions/ missing." >&2
  exit 0
fi

if [ ! -f "$TIMELINE" ]; then
  echo "⚠️ WARNING: TIMELINE.md missing." >&2
  exit 0
fi

exit 0
