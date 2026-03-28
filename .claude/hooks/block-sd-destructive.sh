#!/bin/bash
# block-sd-destructive.sh - .sd/ への破壊的操作を全面ブロック
# PreToolUse hook for Claude Code (Bash)
#
# ブロック対象:
#   - git checkout -- .sd/ / git checkout -- . (ファイル上書き)
#   - git checkout HEAD -- .sd/ (HEAD状態に巻き戻し)
#   - git stash (ワーキングツリーから変更を退避=削除)
#   - git clean (untrackedファイル削除)
#   - git restore .sd/ / git restore . (ファイル復元=上書き)
#   - git reset --hard (全変更破棄)
#   - rm / rm -rf .sd (直接削除)
#   - mv .sd (ディレクトリ移動)
#
# 許可:
#   - git add .sd/ (ステージング)
#   - git commit (コミット)
#   - git diff / git status / git log (読み取り)
#   - Read/Write/Edit による .sd/ 内ファイル操作
#
# 背景: 2026-03-21 .sd消失事故
#   原因1: AIが git checkout HEAD を実行 → sessions消失
#   原因2: AIが .sd/ 内にvenv作成 → クリーンアップで全消失
#   原因3: 「ツール呼び出し間の定期的消失」= 原因1の反復(推定)
#   共通パターン: AIのBashコマンドが.sdを破壊した

INPUT=$(cat)

# command フィールドを抽出
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# === Pattern 1: git checkout -- . / git checkout -- .sd ===
# git checkout HEAD -- .sd/ or git checkout -- .sd/ or git checkout -- .
if echo "$COMMAND" | grep -qiE 'git\s+checkout\s+.*--\s+(\.sd|\.(/|$))'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git checkout -- .sd/ は禁止です。.sd/のファイルが上書き・消失します。2026-03-21事故の再発防止。個別ファイルの復元が必要な場合はユーザーに確認してください。"
  }
}
EOF
  exit 0
fi

# === Pattern 2: git checkout <ref> -- . (全体チェックアウト) ===
if echo "$COMMAND" | grep -qiE 'git\s+checkout\s+\S+\s+--\s+\.$'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git checkout <ref> -- . は禁止です。.sd/を含む全ファイルが上書きされます。対象ファイルを明示してください（.sd/以外）。"
  }
}
EOF
  exit 0
fi

# === Pattern 3: git stash (push/save/無引数) ===
# git stash list / git stash show は許可
if echo "$COMMAND" | grep -qiE 'git\s+stash(\s|$)' && \
   ! echo "$COMMAND" | grep -qiE 'git\s+stash\s+(list|show|drop|pop|apply|branch)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git stash は禁止です。.sd/の変更がワーキングツリーから退避（=消失）します。変更を保存するには git commit を使用してください。"
  }
}
EOF
  exit 0
fi

# === Pattern 4: git clean ===
if echo "$COMMAND" | grep -qiE 'git\s+clean'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git clean は禁止です。.sd/内のuntrackedファイルが削除される可能性があります。"
  }
}
EOF
  exit 0
fi

# === Pattern 5: git restore .sd / git restore . ===
if echo "$COMMAND" | grep -qiE 'git\s+restore\s+.*(\.sd|^\.\s|--\s+\.)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git restore .sd/ は禁止です。.sd/のファイルがHEAD状態に巻き戻されます。"
  }
}
EOF
  exit 0
fi

# === Pattern 6: git reset --hard ===
if echo "$COMMAND" | grep -qiE 'git\s+reset\s+--hard'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git reset --hard は禁止です。.sd/を含む全ての変更が破棄されます。"
  }
}
EOF
  exit 0
fi

# === Pattern 7: rm / rm -rf .sd ===
if echo "$COMMAND" | grep -qiE '(rm\s+(-[a-z]*\s+)*\.sd|rm\s+(-[a-z]*\s+)*\./\.sd)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: .sd/ の直接削除(rm)は禁止です。ファイル管理原則: 削除禁止、アーカイブ移動を使用。"
  }
}
EOF
  exit 0
fi

# === Pattern 8: mv .sd ===
if echo "$COMMAND" | grep -qiE 'mv\s+(-[a-z]*\s+)*\.sd'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: .sd/ の移動(mv)は禁止です。.sd/はプロジェクトの中核ディレクトリです。"
  }
}
EOF
  exit 0
fi

# All checks passed
exit 0
