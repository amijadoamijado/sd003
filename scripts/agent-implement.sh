#!/bin/bash
# agent-implement.sh - Antigravity CLI (agy)への実装依頼（非インタラクティブ実行）
#
# SD003 AI協調ワークフローにおいて、IMPLEMENT_REQUESTをAntigravity CLIに
# 渡し、非インタラクティブに実装を実行するスクリプト。
#
# Usage:
#   ./scripts/agent-implement.sh <案件ID> <タスク番号> [既存ファイルパス]
#
# Examples:
#   ./scripts/agent-implement.sh 20260101-001-auth 001
#   ./scripts/agent-implement.sh 20260101-001-auth 001 src/core/auth.ts
#
# Options:
#   --dry-run    プロンプトを表示するのみ（Antigravity実行なし）
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
            echo "agent-implement.sh - Antigravity CLIへの実装依頼（非インタラクティブ実行）"
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
            echo "  --dry-run    プロンプト表示のみ（Antigravity実行なし）"
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
OUTPUT_FILE="${OUTPUT_DIR}/agy-output-${TASK_NUM}.md"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Antigravity CLI Agent - Implementation${NC}"
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
PROMPT="あなたはSD003フレームワークの実装担当AIです。
以下の実装指示に従い、コードを実装してください。

## 制約事項
- TypeScript strictモード必須
- Node.js API禁止（fs, path, process）
- GAS API直接参照禁止（Env Interface経由のみ）
- ESLintエラー0件
- テストは本番バグ再現時のみ最小限（カバレッジ目標は廃止・VTD-001〜005準拠）。実データで動作確認すること

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
    echo -e "${YELLOW}[DRY-RUN] Antigravityへ送信されるプロンプト:${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "$PROMPT"
    echo ""
    echo -e "${YELLOW}[DRY-RUN] 実行なし${NC}"
    exit 0
fi

# Execute via Antigravity CLI (agy) headless + permission skip mode
echo ""
echo -e "${BLUE}Step 4: Antigravity CLI実行（agy --prompt）...${NC}"

# Check if agy is available
if ! command -v agy &>/dev/null; then
    echo -e "${RED}Error: Antigravity CLI (agy) が見つかりません${NC}"
    echo -e "Install: see Antigravity CLI documentation"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Execute Antigravity in print mode with auto-approval
RESULT=$(agy --prompt "$PROMPT" --dangerously-skip-permissions 2>&1) || {
    echo -e "${RED}Error: Antigravity CLI実行に失敗しました${NC}"
    echo "$RESULT" > "${OUTPUT_FILE%.md}-error.md"
    echo -e "エラーログ: ${OUTPUT_FILE%.md}-error.md"
    exit 1
}

# Save output
echo "$RESULT" > "$OUTPUT_FILE"

# Check for files written by Antigravity
AGY_CHANGES=$(git status --porcelain 2>/dev/null | grep -v "^??" | head -20 || true)
if [ -n "$AGY_CHANGES" ]; then
    echo -e "${GREEN}[OK] Antigravity CLI実行完了（ファイル直接書き込み）${NC}"
    echo -e "${BLUE}Antigravityが変更したファイル:${NC}"
    echo "$AGY_CHANGES"
else
    echo -e "${GREEN}[OK] Antigravity CLI実行完了${NC}"
fi
echo -e "出力ログ: ${GREEN}${OUTPUT_FILE}${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}IMPLEMENTATION COMPLETE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Antigravity変更を確認: git diff"
echo "  2. 出力ログ確認: cat ${OUTPUT_FILE}"
echo "  3. テスト実行: npm test && npm run lint && npm run build"
echo "  4. コミット: git add . && git commit"
echo "  5. レビュー依頼: Codex GUIDE参照"
