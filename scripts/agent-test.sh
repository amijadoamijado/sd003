#!/bin/bash
# agent-test.sh - Antigravity テストパイプラインスクリプト
#
# Claude Code（指揮・判断）→ Antigravity（E2Eテスト実行）
# のテストパイプラインをハンドオフ方式で実行する。
#
# Usage:
#   ./scripts/agent-test.sh <案件ID> <タスク番号> [options]
#
# Examples:
#   ./scripts/agent-test.sh 20260101-001-auth 001
#   ./scripts/agent-test.sh 20260101-001-auth 001 --dry-run
#   ./scripts/agent-test.sh 20260101-001-auth 001 --manual
#
# Options:
#   --dry-run    プレビューのみ（テスト実行なし）
#   --manual     手動モード（Antigravity不在時の案内出力）
#   --help       ヘルプ表示

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
PROJECT_ID=""
TASK_NUM=""
DRY_RUN=false
MANUAL_MODE=false
USER_REQUESTED_MANUAL=false
REPORT_MISSING=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --manual)
            MANUAL_MODE=true
            USER_REQUESTED_MANUAL=true
            shift
            ;;
        --help|-h)
            echo "agent-test.sh - Antigravity テストパイプライン"
            echo ""
            echo "Usage:"
            echo "  $0 <案件ID> <タスク番号> [options]"
            echo ""
            echo "Pipeline:"
            echo "  Step 1: TEST_REQUEST 確認"
            echo "  Step 2: Antigravity ディスパッチ"
            echo "  Step 3: TEST_REPORT 収集"
            echo "  Step 4: handoff-log.json 更新"
            echo ""
            echo "Options:"
            echo "  --dry-run    プレビューのみ"
            echo "  --manual     手動モード（案内出力のみ）"
            echo "  --help       このヘルプを表示"
            exit 0
            ;;
        *)
            if [ -z "$PROJECT_ID" ]; then
                PROJECT_ID="$1"
            elif [ -z "$TASK_NUM" ]; then
                TASK_NUM="$1"
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$PROJECT_ID" ] || [ -z "$TASK_NUM" ]; then
    echo -e "${RED}Error: 案件ID と タスク番号 は必須です${NC}"
    echo "Usage: $0 <案件ID> <タスク番号> [--dry-run] [--manual]"
    exit 1
fi

# Paths
SPEC_DIR="${PROJECT_ROOT}/.kiro/ai-coordination/workflow/spec/${PROJECT_ID}"
REVIEW_DIR="${PROJECT_ROOT}/.kiro/ai-coordination/workflow/review/${PROJECT_ID}"
LOG_DIR="${PROJECT_ROOT}/.kiro/ai-coordination/workflow/log/${PROJECT_ID}"
TEST_REQUEST="${SPEC_DIR}/TEST_REQUEST_${TASK_NUM}.md"
TEST_REPORT="${REVIEW_DIR}/TEST_REPORT_${TASK_NUM}.md"
HANDOFF_LOG="${PROJECT_ROOT}/.kiro/ai-coordination/handoff/handoff-log.json"
TEST_LOG="${LOG_DIR}/test-${TASK_NUM}.log"

# Timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  SD003 Antigravity Test Pipeline          ║${NC}"
echo -e "${CYAN}║  TEST_REQUEST → Antigravity → TEST_REPORT ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "案件ID:     ${GREEN}${PROJECT_ID}${NC}"
echo -e "タスク番号:  ${GREEN}${TASK_NUM}${NC}"
echo -e "開始時刻:   ${TIMESTAMP}"
echo -e "Options:    dry-run=${DRY_RUN}, manual=${MANUAL_MODE}"
echo ""

# Create directories
mkdir -p "$LOG_DIR" "$REVIEW_DIR"

# Initialize test log
echo "# Test Pipeline Log: ${PROJECT_ID} #${TASK_NUM}" > "$TEST_LOG"
echo "Started: ${TIMESTAMP}" >> "$TEST_LOG"
echo "" >> "$TEST_LOG"

# ============================================================
# Step 1: TEST_REQUEST 確認
# ============================================================
echo -e "${BLUE}━━━ Step 1/4: TEST_REQUEST 確認 ━━━${NC}"
echo "## Step 1: TEST_REQUEST Verification" >> "$TEST_LOG"

if [ ! -f "$TEST_REQUEST" ]; then
    echo -e "${RED}Error: TEST_REQUEST が見つかりません${NC}"
    echo -e "Expected: ${TEST_REQUEST}"
    echo -e "Run: /workflow:test ${PROJECT_ID} ${TASK_NUM}"
    echo "Status: MISSING" >> "$TEST_LOG"
    exit 1
fi

echo -e "${GREEN}[OK] TEST_REQUEST 確認完了${NC}"
echo -e "  File: ${TEST_REQUEST}"
echo "Status: FOUND" >> "$TEST_LOG"
echo "" >> "$TEST_LOG"

# ============================================================
# Step 2: Antigravity ディスパッチ
# ============================================================
echo ""
echo -e "${BLUE}━━━ Step 2/4: Antigravity ディスパッチ ━━━${NC}"
echo "## Step 2: Antigravity Dispatch" >> "$TEST_LOG"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY-RUN] Would dispatch TEST_REQUEST to Antigravity${NC}"
    echo "[DRY-RUN] Skipped" >> "$TEST_LOG"
elif [ "$MANUAL_MODE" = true ]; then
    echo -e "${YELLOW}[MANUAL] Antigravity手動テスト案内:${NC}"
    echo ""
    echo "  1. Antigravityセッションを開始"
    echo "  2. 以下のTEST_REQUESTを読み込み:"
    echo -e "     ${GREEN}${TEST_REQUEST}${NC}"
    echo "  3. テストケースを順次実行"
    echo "  4. TEST_REPORTを以下に保存:"
    echo -e "     ${GREEN}${TEST_REPORT}${NC}"
    echo ""
    echo "Status: MANUAL_DISPATCH" >> "$TEST_LOG"
else
    # Antigravity CLIが利用可能か確認（検出されたバイナリを使用）
    ANTIGRAVITY_BIN=""
    if command -v antigravity &> /dev/null; then
        ANTIGRAVITY_BIN="antigravity"
    elif command -v gemini &> /dev/null; then
        ANTIGRAVITY_BIN="gemini"
    fi

    if [ -n "$ANTIGRAVITY_BIN" ]; then
        echo -e "${BLUE}Antigravityへテスト依頼中... (using: ${ANTIGRAVITY_BIN})${NC}"

        # Antigravityにパイプで送信
        TEST_CONTENT=$(cat "$TEST_REQUEST")
        TEST_PROMPT="以下のテスト依頼に従って、E2Eテストを実行してください。結果はTEST_REPORT形式で出力してください。

${TEST_CONTENT}"

        if echo "$TEST_PROMPT" | "$ANTIGRAVITY_BIN" 2>&1 > "${TEST_REPORT}" ; then
            echo -e "${GREEN}[OK] Antigravity テスト完了${NC}"
            echo "Status: COMPLETED" >> "$TEST_LOG"
        else
            echo -e "${YELLOW}[WARN] Antigravity実行に失敗（手動テストに切り替え）${NC}"
            echo "Status: DISPATCH_FAILED" >> "$TEST_LOG"
            MANUAL_MODE=true
        fi
    else
        echo -e "${YELLOW}[INFO] Antigravity CLI未検出。手動テストモードに切り替え。${NC}"
        echo ""
        echo "  TEST_REQUEST: ${TEST_REQUEST}"
        echo "  TEST_REPORT保存先: ${TEST_REPORT}"
        echo ""
        echo "Status: CLI_NOT_FOUND" >> "$TEST_LOG"
        MANUAL_MODE=true
    fi
fi
echo "" >> "$TEST_LOG"

# ============================================================
# Step 3: TEST_REPORT 収集
# ============================================================
echo ""
echo -e "${BLUE}━━━ Step 3/4: TEST_REPORT 確認 ━━━${NC}"
echo "## Step 3: TEST_REPORT Collection" >> "$TEST_LOG"

if [ -f "$TEST_REPORT" ]; then
    echo -e "${GREEN}[OK] TEST_REPORT 存在確認${NC}"
    echo -e "  File: ${TEST_REPORT}"
    echo "Status: FOUND" >> "$TEST_LOG"
    echo "Output: ${TEST_REPORT}" >> "$TEST_LOG"
else
    echo -e "${YELLOW}[PENDING] TEST_REPORT 未作成（Antigravityテスト待ち）${NC}"
    echo "Status: PENDING" >> "$TEST_LOG"
    REPORT_MISSING=true
fi
echo "" >> "$TEST_LOG"

# ============================================================
# Step 4: handoff-log.json 更新案内
# ============================================================
echo ""
echo -e "${BLUE}━━━ Step 4/4: handoff-log.json 更新 ━━━${NC}"
echo "## Step 4: Handoff Log" >> "$TEST_LOG"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY-RUN] Would update handoff-log.json${NC}"
    echo "[DRY-RUN] Skipped" >> "$TEST_LOG"
else
    echo -e "${YELLOW}[INFO] handoff-log.json は Claude Code が更新します${NC}"
    echo "Status: DEFERRED_TO_CLAUDE" >> "$TEST_LOG"
fi
echo "" >> "$TEST_LOG"

# ============================================================
# Summary
# ============================================================
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Test Pipeline Complete                   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "完了時刻: ${END_TIMESTAMP}"
echo ""
echo "Output files:"
[ -f "$TEST_REQUEST" ] && echo -e "  Request: ${GREEN}${TEST_REQUEST}${NC}"
[ -f "$TEST_REPORT" ] && echo -e "  Report:  ${GREEN}${TEST_REPORT}${NC}"
echo -e "  Log:     ${GREEN}${TEST_LOG}${NC}"
echo ""

if [ "$MANUAL_MODE" = true ]; then
    echo "Next steps (手動テスト):"
    echo "  1. Antigravityセッションを開始"
    echo "  2. TEST_REQUESTを読み込み: cat ${TEST_REQUEST}"
    echo "  3. テスト実行・証跡取得"
    echo "  4. TEST_REPORTを作成: ${TEST_REPORT}"
    echo "  5. Claude Codeに報告: /workflow:status ${PROJECT_ID}"
else
    echo "Next steps (Claude Code判断):"
    echo "  1. TEST_REPORT確認: cat ${TEST_REPORT}"
    echo "  2. 判定確認: Pass / Fail / Blocked"
    echo "  3. 工程更新: /workflow:status ${PROJECT_ID}"
fi

# Finalize test log
{
    echo "## Summary"
    echo "Completed: ${END_TIMESTAMP}"
    TEST_FLAGS=""
    if [ "$DRY_RUN" = true ]; then TEST_FLAGS="${TEST_FLAGS}DRY-RUN "; fi
    if [ "$MANUAL_MODE" = true ]; then TEST_FLAGS="${TEST_FLAGS}MANUAL "; fi
    echo "Pipeline: ${TEST_FLAGS:-STANDARD}"
} >> "$TEST_LOG"

# Exit with non-zero status if TEST_REPORT was not produced
# This prevents agent-pipeline.sh from treating incomplete runs as success.
# Only skip this check for --dry-run and explicitly requested --manual mode.
# Automatic fallbacks (CLI not found, dispatch failed) must still fail.
if [ "$REPORT_MISSING" = true ] && [ "$DRY_RUN" = false ] && [ "$USER_REQUESTED_MANUAL" = false ]; then
    exit 2
fi
