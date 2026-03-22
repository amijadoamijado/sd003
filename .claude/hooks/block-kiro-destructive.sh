#!/bin/bash
# block-kiro-destructive.sh - .kiro/ への破壊的操作を全面ブロック
# PreToolUse hook for Claude Code (Bash)
#
# ブロック対象:
#   - git checkout -- .kiro/ / git checkout -- . (ファイル上書き)
#   - git checkout HEAD -- .kiro/ (HEAD状態に巻き戻し)
#   - git stash (ワーキングツリーから変更を退避=削除)
#   - git clean (untrackedファイル削除)
#   - git restore .kiro/ / git restore . (ファイル復元=上書き)
#   - git reset --hard (全変更破棄)
#   - rm / rm -rf .kiro (直接削除)
#   - mv .kiro (ディレクトリ移動)
#
# 許可:
#   - git add .kiro/ (ステージング)
#   - git commit (コミット)
#   - git diff / git status / git log (読み取り)
#   - Read/Write/Edit による .kiro/ 内ファイル操作
#
# 背景: 2026-03-21 .kiro消失事故
#   原因1: AIが git checkout HEAD を実行 → sessions消失
#   原因2: AIが .kiro/ 内にvenv作成 → クリーンアップで全消失
#   原因3: 「ツール呼び出し間の定期的消失」= 原因1の反復(推定)
#   共通パターン: AIのBashコマンドが.kiroを破壊した

INPUT=$(cat)

# command フィールドを抽出
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# === Pattern 1: git checkout -- . / git checkout -- .kiro ===
# git checkout HEAD -- .kiro/ or git checkout -- .kiro/ or git checkout -- .
if echo "$COMMAND" | grep -qiE 'git\s+checkout\s+.*--\s+(\.kiro|\.(/|$))'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git checkout -- .kiro/ は禁止です。.kiro/のファイルが上書き・消失します。2026-03-21事故の再発防止。個別ファイルの復元が必要な場合はユーザーに確認してください。"
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
    "permissionDecisionReason": "BLOCKED: git checkout <ref> -- . は禁止です。.kiro/を含む全ファイルが上書きされます。対象ファイルを明示してください（.kiro/以外）。"
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
    "permissionDecisionReason": "BLOCKED: git stash は禁止です。.kiro/の変更がワーキングツリーから退避（=消失）します。変更を保存するには git commit を使用してください。"
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
    "permissionDecisionReason": "BLOCKED: git clean は禁止です。.kiro/内のuntrackedファイルが削除される可能性があります。"
  }
}
EOF
  exit 0
fi

# === Pattern 5: git restore .kiro / git restore . ===
if echo "$COMMAND" | grep -qiE 'git\s+restore\s+.*(\.kiro|^\.\s|--\s+\.)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: git restore .kiro/ は禁止です。.kiro/のファイルがHEAD状態に巻き戻されます。"
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
    "permissionDecisionReason": "BLOCKED: git reset --hard は禁止です。.kiro/を含む全ての変更が破棄されます。"
  }
}
EOF
  exit 0
fi

# === Pattern 7: rm / rm -rf .kiro ===
if echo "$COMMAND" | grep -qiE '(rm\s+(-[a-z]*\s+)*\.kiro|rm\s+(-[a-z]*\s+)*\./\.kiro)'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: .kiro/ の直接削除(rm)は禁止です。ファイル管理原則: 削除禁止、アーカイブ移動を使用。"
  }
}
EOF
  exit 0
fi

# === Pattern 8: mv .kiro ===
if echo "$COMMAND" | grep -qiE 'mv\s+(-[a-z]*\s+)*\.kiro'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: .kiro/ の移動(mv)は禁止です。.kiro/はプロジェクトの中核ディレクトリです。"
  }
}
EOF
  exit 0
fi

# All checks passed
exit 0
