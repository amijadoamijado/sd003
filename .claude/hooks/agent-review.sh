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
  TOOL_INPUT=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "")
fi

if [ -z "$TOOL_INPUT" ]; then
  # No command field - not a Bash tool call, skip
  exit 0
fi

# Only trigger on git commit commands
if ! echo "$TOOL_INPUT" | grep -qE "^git commit|&&\s*git commit|\|\|\s*git commit"; then
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
echo "REVIEW: Running Codex auto-review for commit ${COMMIT_HASH}..." >&2

REVIEW_RESULT=""
REVIEW_EXIT=0

REVIEW_RESULT=$(printf '%s' "$REVIEW_PROMPT" | codex exec --full-auto 2>/dev/null) || REVIEW_EXIT=$?

if [ $REVIEW_EXIT -ne 0 ] && [ -z "$REVIEW_RESULT" ]; then
  echo "REVIEW_ERROR: Codex failed with exit code ${REVIEW_EXIT}" >&2
  cat <<ERROR_EOF > "$REVIEW_OUTPUT"
# Auto Code Review - Error

**Commit**: ${COMMIT_HASH} - ${COMMIT_MSG}
**Error**: Codex CLI exited with code ${REVIEW_EXIT}

Please run manually: \`echo "Review diff" | codex exec --full-auto\`
ERROR_EOF
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
if echo "$REVIEW_RESULT" | grep -qi "\[Critical\]"; then
  CRITICAL_COUNT=$(echo "$REVIEW_RESULT" | grep -ci "\[Critical\]" || echo "0")
  echo "REVIEW_FAIL: ${CRITICAL_COUNT} critical issue(s) found. See ${REVIEW_OUTPUT}" >&2
  exit 1
elif echo "$REVIEW_RESULT" | grep -qi "Overall.*FAIL"; then
  echo "REVIEW_FAIL: Review verdict is FAIL. See ${REVIEW_OUTPUT}" >&2
  exit 1
else
  echo "REVIEW_PASS: No critical issues found." >&2
  exit 0
fi
