#!/bin/bash
# agent-review.sh - Codex Auto Code Review Hook for Claude Code
#
# PostToolUse hook: Triggers after git commit via Bash tool.
# Calls Codex CLI in full-auto mode to review the committed diff.
# Claude Code reads the result and decides whether to fix issues.
#
# Exit codes:
#   0 = Review passed (no Critical issues) or skipped
#   1 = Review found Critical issues (Claude Code should address)
#
# Requirements:
#   - codex CLI installed and on PATH
#   - git available in working directory

set -euo pipefail

# --- Configuration ---
REVIEW_OUTPUT=".codex-review-result.md"
MAX_DIFF_LINES=2000

# --- Read hook input from stdin ---
INPUT=$(cat)

# --- Check if this was a git commit command ---
# Try python first (safe JSON parsing), fallback to grep/sed
PYTHON_CMD=""
if command -v python3 &>/dev/null; then PYTHON_CMD="python3";
elif command -v python &>/dev/null; then PYTHON_CMD="python"; fi

if [ -n "$PYTHON_CMD" ]; then
  TOOL_INPUT=$(echo "$INPUT" | $PYTHON_CMD -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")
else
  # B1 fix: the old fallback used the same first-quote-stopping sed/grep bug
  # as the other hooks (see block-sd-destructive.sh). Since python is the
  # primary path and is expected to be present, fail OPEN here (empty command
  # => skip) rather than trust a broken extraction.
  TOOL_INPUT=""
fi

if [ -z "$TOOL_INPUT" ]; then
  # No command field - not a Bash tool call, skip
  exit 0
fi

# Only trigger on git commit commands.
# B15 fix: also match `;`-chained commands (e.g. `cd x; git commit`), which
# the old regex (only ^, &&, ||) missed.
if ! echo "$TOOL_INPUT" | grep -qE "^git commit|&&\s*git commit|\|\|\s*git commit|;\s*git commit"; then
  exit 0
fi

# --- Opt-in gate (default OFF) ---
# 2026-07-25 B16 fix: このhookは 231aca3 (2026-03-31) 以降ずっと壊れていた。
#   `codex review --commit <SHA> "<PROMPT>"` は codex CLI が
#   「--commit と [PROMPT] は同時指定不可」で exit 2 する組合せで、
#   さらに 2>/dev/null が原因を握り潰していたため、全コミットで
#   .codex-review-result.md にエラースタブを書くだけの状態だった（16プロジェクトで確認）。
# 呼び出しは下で正しく直したが、実レビューは 2行diff でも数分かかる（実測 240秒でも未完）。
# PostToolUse hook は同期実行（settings.json の timeout=600）なので、毎コミット
# 数分Claude Codeがブロックされる。既定ONにはできない。
#   → 既定OFF。使うときだけ SD_AUTO_REVIEW=1 で明示的に有効化する。
#   → 単発レビューは公式プラグイン /codex:review を使う（CLAUDE.md 記載の正規導線）。
if [ "${SD_AUTO_REVIEW:-0}" != "1" ]; then
  exit 0
fi

# --- Check prerequisites ---

# Check if codex is available
if ! command -v codex &>/dev/null; then
  echo "REVIEW_SKIP: codex CLI not found. Install with: npm i -g @openai/codex" >&2
  cat <<'SKIP_EOF' > "$REVIEW_OUTPUT"
# Auto Code Review - Skipped

**Reason**: `codex` CLI not installed.
**Install**: `npm i -g @openai/codex`

Once installed, this hook will automatically review every commit.
SKIP_EOF
  exit 0
fi

# Check if we're in a git repo with commits
if ! git rev-parse HEAD &>/dev/null; then
  exit 0
fi

# --- Gather diff ---
DIFF=$(git diff HEAD~1 HEAD 2>/dev/null || git diff --cached 2>/dev/null || echo "")

if [ -z "$DIFF" ]; then
  echo "REVIEW_SKIP: No diff to review" >&2
  exit 0
fi

# Truncate very large diffs
DIFF_LINES=$(echo "$DIFF" | wc -l)
if [ "$DIFF_LINES" -gt "$MAX_DIFF_LINES" ]; then
  DIFF=$(echo "$DIFF" | head -n "$MAX_DIFF_LINES")
  DIFF="${DIFF}

... (truncated: ${DIFF_LINES} total lines, showing first ${MAX_DIFF_LINES})"
fi

# --- Gather commit info ---
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
COMMIT_MSG=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "unknown")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# --- Build review prompt ---
REVIEW_PROMPT="Review this git diff. Output as markdown with Critical/Warning/Info items.
Use format: - [Critical] file:line - description
Check: no any type, no console.log, no Node.js APIs in GAS, proper error handling.

--- diff ---
${DIFF}"

# --- Execute Codex review ---
# 正準invocation は .claude/skills/codex-dispatch/SKILL.md に従う:
#   RUST_LOG=error / -c model_reasoning_effort=medium / --sandbox read-only /
#   -o <最終回答> / 2> <progress.log>（`2>&1` は禁止。stderr にテレメトリが数MB流れる）
# 進捗ログと中間出力は .git/ 配下に置く（tracked にならず、.gitignore を汚さない）。
echo "REVIEW: Running Codex auto-review for commit ${COMMIT_HASH}..." >&2

REVIEW_RESULT=""
REVIEW_EXIT=0

GIT_DIR_PATH=$(git rev-parse --git-dir 2>/dev/null || echo ".git")
PROGRESS_LOG="${GIT_DIR_PATH}/codex-review-progress.log"
CODEX_OUT="${GIT_DIR_PATH}/codex-review-last.md"
REVIEW_TIMEOUT="${SD_AUTO_REVIEW_TIMEOUT:-300}"

rm -f "$CODEX_OUT"
RUST_LOG=error timeout "$REVIEW_TIMEOUT" codex exec "$REVIEW_PROMPT" \
  -c model_reasoning_effort="medium" \
  --sandbox read-only \
  -o "$CODEX_OUT" \
  >/dev/null 2>"$PROGRESS_LOG" || REVIEW_EXIT=$?
[ -f "$CODEX_OUT" ] && REVIEW_RESULT=$(cat "$CODEX_OUT")

if [ $REVIEW_EXIT -ne 0 ] && [ -z "$REVIEW_RESULT" ]; then
  echo "REVIEW_ERROR: codex exec failed with exit code ${REVIEW_EXIT} (see ${PROGRESS_LOG})" >&2
  # B16: 旧実装は原因を一切残さず「exit code N」だけ書いていた。
  # stderr の末尾を必ず添付して、次に見た人が真因を判別できるようにする。
  {
    echo "# Auto Code Review - Error"
    echo ""
    echo "**Commit**: ${COMMIT_HASH} - ${COMMIT_MSG}"
    if [ "$REVIEW_EXIT" -eq 124 ]; then
      echo "**Error**: codex exec timed out after ${REVIEW_TIMEOUT}s (SD_AUTO_REVIEW_TIMEOUT で変更可)"
    else
      echo "**Error**: codex exec exited with code ${REVIEW_EXIT}"
    fi
    echo ""
    echo "## stderr (tail)"
    echo ""
    echo '```'
    tail -n 20 "$PROGRESS_LOG" 2>/dev/null || echo "(no progress log)"
    echo '```'
    echo ""
    echo "手動再現: \`RUST_LOG=error codex exec \"<prompt>\" --sandbox read-only -o out.md 2> progress.log\`"
  } > "$REVIEW_OUTPUT"
  exit 0
fi

# --- Save results ---
{
  echo "# Auto Code Review Result"
  echo ""
  echo "**Reviewed by**: Codex (auto)"
  echo "**Date**: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "**Commit**: ${COMMIT_HASH} - ${COMMIT_MSG}"
  echo "**Branch**: ${BRANCH}"
  echo ""
  echo "---"
  echo ""
  echo "$REVIEW_RESULT"
} > "$REVIEW_OUTPUT"

echo "REVIEW: Results saved to ${REVIEW_OUTPUT}" >&2

# --- Determine severity and exit ---
# B15 fix: exit 1 from a PostToolUse hook only prints to stderr as a
# non-blocking error -- Claude Code never sees it as feedback to act on.
# Exit 2 is the documented "blocking/feedback" signal: stderr is fed back
# to Claude so it actually reads and addresses the Critical findings.
if echo "$REVIEW_RESULT" | grep -qi "\[Critical\]"; then
  CRITICAL_COUNT=$(echo "$REVIEW_RESULT" | grep -ci "\[Critical\]" || echo "0")
  echo "REVIEW_FAIL: ${CRITICAL_COUNT} critical issue(s) found. See ${REVIEW_OUTPUT}" >&2
  exit 2
elif echo "$REVIEW_RESULT" | grep -qi "Overall.*FAIL"; then
  echo "REVIEW_FAIL: Review verdict is FAIL. See ${REVIEW_OUTPUT}" >&2
  exit 2
else
  echo "REVIEW_PASS: No critical issues found." >&2
  exit 0
fi
