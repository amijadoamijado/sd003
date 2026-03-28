#!/bin/bash
# agent-review.sh - Manual Code Review Script (Mode B)
#
# Reads a review request document and passes it to Codex CLI for review.
# Saves the result in the AI coordination review folder.
#
# Usage:
#   bash scripts/agent-review.sh <依頼書パス> [--dry-run]
#
# Examples:
#   bash scripts/agent-review.sh .sd/ai-coordination/workflow/spec/20260101-001-auth/IMPLEMENT_REQUEST_001.md
#   bash scripts/agent-review.sh review_request.md --dry-run
#
# Exit codes:
#   0 = Review completed successfully
#   1 = Error (missing file, codex unavailable, etc.)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
REQUEST_FILE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "agent-review.sh - Manual Code Review (Mode B)"
            echo ""
            echo "Usage:"
            echo "  $0 <依頼書パス> [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --dry-run   プレビューのみ（Codex実行なし）"
            echo "  --help      このヘルプを表示"
            echo ""
            echo "Examples:"
            echo "  $0 .sd/ai-coordination/workflow/spec/20260101-001-auth/IMPLEMENT_REQUEST_001.md"
            echo "  $0 review_request.md --dry-run"
            exit 0
            ;;
        *)
            if [ -z "$REQUEST_FILE" ]; then
                REQUEST_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$REQUEST_FILE" ]; then
    echo -e "${RED}Error: 依頼書パスは必須です${NC}"
    echo "Usage: $0 <依頼書パス> [--dry-run]"
    exit 1
fi

if [ ! -f "$REQUEST_FILE" ]; then
    echo -e "${RED}Error: ファイルが見つかりません: ${REQUEST_FILE}${NC}"
    exit 1
fi

# Check codex availability
if ! command -v codex &>/dev/null; then
    echo -e "${RED}Error: codex CLI が見つかりません${NC}"
    echo "Install: npm i -g @openai/codex"
    exit 1
fi

# Extract project ID from path if possible
PROJECT_ID=""
NORMALIZED_PATH=$(echo "$REQUEST_FILE" | sed 's|\\|/|g')
if echo "$NORMALIZED_PATH" | grep -qE 'workflow/spec/([^/]+)/'; then
    PROJECT_ID=$(echo "$NORMALIZED_PATH" | grep -oE 'workflow/spec/([^/]+)/' | sed 's|workflow/spec/||;s|/$||')
fi

# Determine output location
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP_FILE=$(date '+%Y%m%d-%H%M%S')
REQUEST_BASENAME=$(basename "$REQUEST_FILE" .md)

if [ -n "$PROJECT_ID" ]; then
    REVIEW_DIR="${PROJECT_ROOT}/.sd/ai-coordination/workflow/review/${PROJECT_ID}"
    REVIEW_OUTPUT="${REVIEW_DIR}/REVIEW_${REQUEST_BASENAME}_${TIMESTAMP_FILE}.md"
else
    REVIEW_DIR="${PROJECT_ROOT}/.sd/ai-coordination/workflow/review"
    REVIEW_OUTPUT="${REVIEW_DIR}/REVIEW_${REQUEST_BASENAME}_${TIMESTAMP_FILE}.md"
fi

mkdir -p "$REVIEW_DIR"

# Display info
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  SD002 Manual Code Review (Mode B)       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "依頼書:     ${GREEN}${REQUEST_FILE}${NC}"
[ -n "$PROJECT_ID" ] && echo -e "案件ID:     ${GREEN}${PROJECT_ID}${NC}"
echo -e "出力先:     ${GREEN}${REVIEW_OUTPUT}${NC}"
echo -e "開始時刻:   ${TIMESTAMP}"
echo -e "dry-run:    ${DRY_RUN}"
echo ""

# Read request content
REQUEST_CONTENT=$(cat "$REQUEST_FILE")

# Gather git context
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY-RUN] Codex実行をスキップ${NC}"
    echo -e "${BLUE}依頼書の内容:${NC}"
    echo "$REQUEST_CONTENT" | head -20
    [ "$(echo "$REQUEST_CONTENT" | wc -l)" -gt 20 ] && echo "... (truncated)"
    echo ""
    echo -e "${YELLOW}[DRY-RUN] 実行時のコマンド: codex exec --full-auto < <依頼書内容>${NC}"
    exit 0
fi

# Execute Codex review
echo -e "${BLUE}Codex CLIへレビュー依頼中...${NC}"

REVIEW_RESULT=""
REVIEW_EXIT=0

REVIEW_RESULT=$(echo "$REQUEST_CONTENT" | codex exec --full-auto 2>/dev/null) || REVIEW_EXIT=$?

if [ $REVIEW_EXIT -ne 0 ] && [ -z "$REVIEW_RESULT" ]; then
    echo -e "${RED}[FAIL] Codex CLIがエラーコード ${REVIEW_EXIT} で終了${NC}"
    {
        echo "# レビュー結果: ${REQUEST_BASENAME}"
        echo ""
        echo "## メタデータ"
        echo "| 項目 | 値 |"
        echo "|------|-----|"
        [ -n "$PROJECT_ID" ] && echo "| 案件ID | ${PROJECT_ID} |"
        echo "| レビュー日時 | ${TIMESTAMP} |"
        echo "| レビュアー | Codex CLI (manual) |"
        echo "| ステータス | ERROR (exit code: ${REVIEW_EXIT}) |"
    } > "$REVIEW_OUTPUT"
    exit 1
fi

# Save review result
{
    echo "# レビュー結果: ${REQUEST_BASENAME}"
    echo ""
    echo "## メタデータ"
    echo "| 項目 | 値 |"
    echo "|------|-----|"
    [ -n "$PROJECT_ID" ] && echo "| 案件ID | ${PROJECT_ID} |"
    echo "| レビュー日時 | ${TIMESTAMP} |"
    echo "| レビュアー | Codex CLI (manual) |"
    echo "| 対象コミット | ${COMMIT_HASH} |"
    echo "| 対象ブランチ | ${BRANCH} |"
    echo "| 依頼書 | ${REQUEST_FILE} |"
    echo ""
    echo "---"
    echo ""
    echo "$REVIEW_RESULT"
} > "$REVIEW_OUTPUT"

echo -e "${GREEN}[OK] Codex レビュー完了${NC}"
echo -e "レビュー結果: ${GREEN}${REVIEW_OUTPUT}${NC}"

# Record in handoff-log if project ID is available
if [ -n "$PROJECT_ID" ]; then
    echo -e "${YELLOW}[INFO] handoff-log.json への記録はClaude Codeが実行してください${NC}"
fi

echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. レビュー結果を確認: cat ${REVIEW_OUTPUT}"
echo "  2. 必要に応じて修正対応"
echo "  3. 工程更新: /workflow:status ${PROJECT_ID:-<案件ID>}"
