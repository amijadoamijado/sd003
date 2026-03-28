#!/bin/bash
# agent-implement.sh - Gemini CLIへの実装依頼（非インタラクティブ・パイプ実行）
#
# SD002 AI協調ワークフローにおいて、IMPLEMENT_REQUESTをGemini CLIに
# パイプで渡し、非インタラクティブに実装を実行するスクリプト。
#
# Usage:
#   ./scripts/agent-implement.sh <案件ID> <タスク番号> [既存ファイルパス]
#
# Examples:
#   ./scripts/agent-implement.sh 20260101-001-auth 001
#   ./scripts/agent-implement.sh 20260101-001-auth 001 src/core/auth.ts
#
# Options:
#   --dry-run    プロンプトを表示するのみ（Gemini実行なし）
#   --help       ヘルプ表示

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
PROJECT_ID=""
TASK_NUM=""
TARGET_FILE=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "agent-implement.sh - Gemini CLIへの実装依頼（パイプ実行）"
            echo ""
            echo "Usage:"
            echo "  $0 <案件ID> <タスク番号> [既存ファイルパス]"
            echo ""
            echo "Arguments:"
            echo "  案件ID       対象案件のID (e.g., 20260101-001-auth)"
            echo "  タスク番号    タスク番号 3桁 (e.g., 001)"
            echo "  既存ファイル  変更対象の既存ファイルパス (optional)"
            echo ""
            echo "Options:"
            echo "  --dry-run    プロンプト表示のみ（Gemini実行なし）"
            echo "  --help       このヘルプを表示"
            echo ""
            echo "Examples:"
            echo "  $0 20260101-001-auth 001"
            echo "  $0 20260101-001-auth 001 src/core/auth.ts"
            exit 0
            ;;
        *)
            if [ -z "$PROJECT_ID" ]; then
                PROJECT_ID="$1"
            elif [ -z "$TASK_NUM" ]; then
                TASK_NUM="$1"
            else
                TARGET_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$PROJECT_ID" ] || [ -z "$TASK_NUM" ]; then
    echo -e "${RED}Error: 案件ID と タスク番号 は必須です${NC}"
    echo "Usage: $0 <案件ID> <タスク番号> [既存ファイルパス]"
    exit 1
fi

# Paths
SPEC_DIR="${PROJECT_ROOT}/.sd/ai-coordination/workflow/spec/${PROJECT_ID}"
REQUEST_FILE="${SPEC_DIR}/IMPLEMENT_REQUEST_${TASK_NUM}.md"
WORK_ORDER_FILE="${SPEC_DIR}/WORK_ORDER.md"
OUTPUT_DIR="${PROJECT_ROOT}/.sd/ai-coordination/workflow/log/${PROJECT_ID}"
OUTPUT_FILE="${OUTPUT_DIR}/gemini-output-${TASK_NUM}.md"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Gemini CLI Agent - Implementation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "案件ID:     ${GREEN}${PROJECT_ID}${NC}"
echo -e "タスク番号:  ${GREEN}${TASK_NUM}${NC}"
echo -e "Dry-run:    ${DRY_RUN}"
echo ""

# Validate IMPLEMENT_REQUEST exists
if [ ! -f "$REQUEST_FILE" ]; then
    echo -e "${RED}Error: 実装指示が見つかりません${NC}"
    echo -e "Expected: ${REQUEST_FILE}"
    echo -e "Run: /workflow:request ${PROJECT_ID} ${TASK_NUM}"
    exit 1
fi

# Read implementation request
echo -e "${BLUE}Step 1: 実装指示の読み込み...${NC}"
SPEC=$(cat "$REQUEST_FILE")
echo -e "${GREEN}[OK] ${REQUEST_FILE}${NC}"

# Read work order if available
WORK_ORDER_CONTEXT=""
if [ -f "$WORK_ORDER_FILE" ]; then
    echo -e "${BLUE}Step 2: 発注書の読み込み...${NC}"
    WORK_ORDER_CONTEXT="
--- 発注書（参考） ---
$(cat "$WORK_ORDER_FILE")
"
    echo -e "${GREEN}[OK] ${WORK_ORDER_FILE}${NC}"
else
    echo -e "${YELLOW}[SKIP] 発注書なし: ${WORK_ORDER_FILE}${NC}"
fi

# Read existing code if target file specified
EXISTING_CODE=""
if [ -n "$TARGET_FILE" ]; then
    FULL_TARGET="${PROJECT_ROOT}/${TARGET_FILE}"
    if [ -f "$FULL_TARGET" ]; then
        echo -e "${BLUE}Step 3: 既存コードの読み込み...${NC}"
        EXISTING_CODE="
--- 既存コード (${TARGET_FILE}) ---
\`\`\`typescript
$(cat "$FULL_TARGET")
\`\`\`
"
        echo -e "${GREEN}[OK] ${TARGET_FILE}${NC}"
    else
        echo -e "${YELLOW}[INFO] 新規作成ファイル: ${TARGET_FILE}${NC}"
    fi
fi

# Build prompt
PROMPT="あなたはSD002フレームワークの実装担当AIです。
以下の実装指示に従い、コードを実装してください。

## 制約事項
- TypeScript strictモード必須
- Node.js API禁止（fs, path, process）
- GAS API直接参照禁止（Env Interface経由のみ）
- ESLintエラー0件
- カバレッジ80%以上を目指すテスト作成

--- 実装指示 ---
${SPEC}

${WORK_ORDER_CONTEXT}

${EXISTING_CODE}

## 出力形式（厳守）
ファイルを直接書き込め。write_fileツールを使用してファイルを作成・変更せよ。
差分形式（<<<<, ====, >>>>、patch形式）は絶対に使用しない。
説明は最小限にし、実装を中心に進めよ。"

# Dry-run mode
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}[DRY-RUN] Geminiへ送信されるプロンプト:${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "$PROMPT"
    echo ""
    echo -e "${YELLOW}[DRY-RUN] 実行なし${NC}"
    exit 0
fi

# Execute via Gemini CLI headless + yolo mode
echo ""
echo -e "${BLUE}Step 4: Gemini CLI実行（headless + yolo）...${NC}"

# Check if gemini is available
if ! command -v gemini &>/dev/null; then
    echo -e "${RED}Error: gemini CLI が見つかりません${NC}"
    echo -e "Install: see https://github.com/google-gemini/gemini-cli"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Execute Gemini in headless mode with auto-approval
RESULT=$(gemini -p "$PROMPT" --yolo 2>&1) || {
    echo -e "${RED}Error: Gemini CLI実行に失敗しました${NC}"
    echo "$RESULT" > "${OUTPUT_FILE%.md}-error.md"
    echo -e "エラーログ: ${OUTPUT_FILE%.md}-error.md"
    exit 1
}

# Save output
echo "$RESULT" > "$OUTPUT_FILE"

# Check for files written by Gemini
GEMINI_CHANGES=$(git status --porcelain 2>/dev/null | grep -v "^??" | head -20)
if [ -n "$GEMINI_CHANGES" ]; then
    echo -e "${GREEN}[OK] Gemini CLI実行完了（ファイル直接書き込み）${NC}"
    echo -e "${BLUE}Geminiが変更したファイル:${NC}"
    echo "$GEMINI_CHANGES"
else
    echo -e "${GREEN}[OK] Gemini CLI実行完了${NC}"
fi
echo -e "出力ログ: ${GREEN}${OUTPUT_FILE}${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}IMPLEMENTATION COMPLETE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Gemini変更を確認: git diff"
echo "  2. 出力ログ確認: cat ${OUTPUT_FILE}"
echo "  3. テスト実行: npm test && npm run lint && npm run build"
echo "  4. コミット: git add . && git commit"
echo "  5. レビュー依頼: Codex GUIDE参照"
