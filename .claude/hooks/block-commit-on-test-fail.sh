#!/bin/bash
# block-commit-on-test-fail.sh - git commit をテスト失敗時にブロック
# PreToolUse hook for Claude Code
#
# 許可: git commit（npm test 成功時）
# ブロック: git commit（npm test 失敗時）
# バイパス: SD003_SKIP_PRECOMMIT_TEST=1

INPUT=$(cat)

# sed でJSONから command フィールドを抽出
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# git commit 以外は無視
if ! echo "$COMMAND" | grep -qiE 'git\s+commit'; then
  exit 0
fi

# git commit --amend も対象（通常commitと同じゲート）
# git add, git status, git diff 等は対象外（上のgrepで除外済み）

# 緊急バイパス
if [ "$SD003_SKIP_PRECOMMIT_TEST" = "1" ]; then
  exit 0
fi

# package.json が存在しない場合はスキップ（テスト不可）
if [ ! -f "$CLAUDE_PROJECT_DIR/package.json" ]; then
  exit 0
fi

# npm test 実行
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
TEST_OUTPUT=$(npm test 2>&1)
TEST_EXIT=$?

if [ $TEST_EXIT -ne 0 ]; then
  # 失敗したテスト名を抽出（最後の20行）
  FAIL_SUMMARY=$(echo "$TEST_OUTPUT" | tail -20 | sed 's/"/\\"/g' | tr '\n' ' ')
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: テストが失敗しています。git commit はテスト全パス後にのみ許可されます。\\n失敗サマリー: ${FAIL_SUMMARY}\\nバイパス: SD003_SKIP_PRECOMMIT_TEST=1"
  }
}
EOF
  exit 0
fi

# テスト成功 → commit許可
exit 0
