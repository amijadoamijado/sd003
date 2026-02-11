#!/bin/bash
# agent-pipeline.sh - 3-Agent パイプライン統合スクリプト
#
# Claude Code（指揮・判断）→ Gemini CLI（実装）→ Codex（レビュー）
# の3段階パイプラインを非インタラクティブに実行する。
#
# Usage:
#   ./scripts/agent-pipeline.sh <案件ID> <タスク番号> [--skip-review] [--auto-apply]
#
# Examples:
#   ./scripts/agent-pipeline.sh 20260101-001-auth 001
#   ./scripts/agent-pipeline.sh 20260101-001-auth 001 --skip-review
#   ./scripts/agent-pipeline.sh 20260101-001-auth 001 --auto-apply
#
# Options:
#   --skip-review   Codexレビューをスキップ
#   --auto-apply    Gemini出力のgit add + commit を実行（要注意）
#   --dry-run       全ステップをプレビューのみ
#   --help          ヘルプ表示

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
SKIP_REVIEW=false
AUTO_APPLY=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-review)
            SKIP_REVIEW=true
            shift
            ;;
        --auto-apply)
            AUTO_APPLY=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "agent-pipeline.sh - 3-Agent パイプライン"
            echo ""
            echo "Usage:"
            echo "  $0 <案件ID> <タスク番号> [options]"
            echo ""
            echo "Pipeline:"
            echo "  Step 1: Gemini CLI  - 実装（パイプ実行）"
            echo "  Step 2: git commit  - 自動コミット（--auto-apply時）"
            echo "  Step 3: Codex      - レビュー（パイプ実行）"
            echo "  Step 4: 結果出力   - Claude Codeが判断"
            echo ""
            echo "Options:"
            echo "  --skip-review   Codexレビューをスキップ"
            echo "  --auto-apply    Gemini出力のgit add + commit を実行"
            echo "  --dry-run       プレビューのみ"
            echo "  --help          このヘルプを表示"
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
    echo "Usage: $0 <案件ID> <タスク番号> [--skip-review] [--auto-apply] [--dry-run]"
    exit 1
fi

# Paths
SPEC_DIR="${PROJECT_ROOT}/.kiro/ai-coordination/workflow/spec/${PROJECT_ID}"
REVIEW_DIR="${PROJECT_ROOT}/.kiro/ai-coordination/workflow/review/${PROJECT_ID}"
LOG_DIR="${PROJECT_ROOT}/.kiro/ai-coordination/workflow/log/${PROJECT_ID}"
REQUEST_FILE="${SPEC_DIR}/IMPLEMENT_REQUEST_${TASK_NUM}.md"
GEMINI_OUTPUT="${LOG_DIR}/gemini-output-${TASK_NUM}.md"
REVIEW_OUTPUT="${REVIEW_DIR}/REVIEW_IMPL_${TASK_NUM}.md"
PIPELINE_LOG="${LOG_DIR}/pipeline-${TASK_NUM}.log"

# Timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  SD002 3-Agent Pipeline                  ║${NC}"
echo -e "${CYAN}║  Gemini(実装) → Codex(レビュー) → 判断   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "案件ID:     ${GREEN}${PROJECT_ID}${NC}"
echo -e "タスク番号:  ${GREEN}${TASK_NUM}${NC}"
echo -e "開始時刻:   ${TIMESTAMP}"
echo -e "Options:    skip-review=${SKIP_REVIEW}, auto-apply=${AUTO_APPLY}, dry-run=${DRY_RUN}"
echo ""

# Create directories
mkdir -p "$LOG_DIR" "$REVIEW_DIR"

# Initialize pipeline log
echo "# Pipeline Log: ${PROJECT_ID} #${TASK_NUM}" > "$PIPELINE_LOG"
echo "Started: ${TIMESTAMP}" >> "$PIPELINE_LOG"
echo "" >> "$PIPELINE_LOG"

# Validate prerequisites
if [ ! -f "$REQUEST_FILE" ]; then
    echo -e "${RED}Error: 実装指示が見つかりません${NC}"
    echo -e "Expected: ${REQUEST_FILE}"
    echo -e "Run: /workflow:request ${PROJECT_ID} ${TASK_NUM}"
    exit 1
fi

# ============================================================
# Step 1: Gemini CLI - Implementation via pipe
# ============================================================
echo -e "${BLUE}━━━ Step 1/3: Gemini CLI 実装 ━━━${NC}"
echo "## Step 1: Gemini Implementation" >> "$PIPELINE_LOG"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY-RUN] Would execute: agent-implement.sh ${PROJECT_ID} ${TASK_NUM}${NC}"
    echo "[DRY-RUN] Skipped" >> "$PIPELINE_LOG"
else
    # Execute Gemini implementation
    if "${SCRIPT_DIR}/agent-implement.sh" "$PROJECT_ID" "$TASK_NUM"; then
        echo -e "${GREEN}[OK] Gemini CLI 実装完了${NC}"
        echo "Status: SUCCESS" >> "$PIPELINE_LOG"
        echo "Output: ${GEMINI_OUTPUT}" >> "$PIPELINE_LOG"
    else
        echo -e "${RED}[FAIL] Gemini CLI 実装失敗${NC}"
        echo "Status: FAILED" >> "$PIPELINE_LOG"
        echo -e "パイプラインを中断します。ログ: ${PIPELINE_LOG}"
        exit 1
    fi
fi
echo "" >> "$PIPELINE_LOG"

# ============================================================
# Step 2: Auto-apply (optional)
# ============================================================
if [ "$AUTO_APPLY" = true ]; then
    echo ""
    echo -e "${BLUE}━━━ Step 2/3: Auto Apply & Commit ━━━${NC}"
    echo "## Step 2: Auto Apply" >> "$PIPELINE_LOG"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN] Would auto-apply and commit Gemini output${NC}"
        echo "[DRY-RUN] Skipped" >> "$PIPELINE_LOG"
    else
        HAS_CHANGES=false
        if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet HEAD 2>/dev/null; then
            HAS_CHANGES=true
        elif [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
            HAS_CHANGES=true
        fi

        if [ "$HAS_CHANGES" = true ]; then
            echo -e "${BLUE}Staging and committing changes...${NC}"
            git add -A
            if git commit -m "feat(${PROJECT_ID}): auto-apply Gemini output #${TASK_NUM}"; then
                echo -e "${GREEN}[OK] Auto-apply commit 完了${NC}"
                echo "Status: COMMITTED" >> "$PIPELINE_LOG"
            else
                echo -e "${RED}[FAIL] git commit に失敗しました${NC}"
                echo "Status: COMMIT_FAILED" >> "$PIPELINE_LOG"
                exit 1
            fi
        else
            echo -e "${YELLOW}[SKIP] ワーキングツリーに変更なし${NC}"
            echo "Status: NO_CHANGES" >> "$PIPELINE_LOG"
        fi
    fi
    echo "" >> "$PIPELINE_LOG"
else
    echo ""
    echo -e "${YELLOW}[SKIP] Auto-apply 無効（--auto-apply で有効化）${NC}"
fi

# ============================================================
# Step 3: Codex Review via pipe
# ============================================================
if [ "$SKIP_REVIEW" = false ]; then
    echo ""
    echo -e "${BLUE}━━━ Step 3/3: Codex レビュー ━━━${NC}"
    echo "## Step 3: Codex Review" >> "$PIPELINE_LOG"

    if [ ! -f "$GEMINI_OUTPUT" ]; then
        echo -e "${YELLOW}[SKIP] Gemini出力なし（dry-run or 未実行）${NC}"
        echo "Status: SKIPPED (no Gemini output)" >> "$PIPELINE_LOG"
    elif [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN] Would execute: codex review on ${GEMINI_OUTPUT}${NC}"
        echo "[DRY-RUN] Skipped" >> "$PIPELINE_LOG"
    else
        # Build review prompt
        REVIEW_PROMPT="以下のコードをレビューしてください。SD002フレームワークの品質基準に基づいて評価してください。

## レビュー観点
1. TypeScript strictモード準拠
2. Node.js API使用禁止（fs, path, process）
3. GAS API直接参照禁止（Env Interface経由のみ）
4. ESLintルール準拠
5. テストカバレッジ80%以上
6. エラーハンドリング
7. JSDocコメント（公開API）

## レビュー対象コード
$(cat "$GEMINI_OUTPUT")

## 出力形式
以下の形式でレビュー結果を出力:
- **判定**: Approve / Request Changes
- **指摘事項**: 具体的な問題点と修正提案
- **良い点**: 評価できるポイント"

        # Execute Codex review
        echo -e "${BLUE}Codex CLIへレビュー依頼中...${NC}"
        REVIEW_RESULT=$(echo "$REVIEW_PROMPT" | codex exec --full-auto 2>&1) || {
            echo -e "${YELLOW}[WARN] Codex CLI実行に失敗（手動レビューに切り替え）${NC}"
            echo "Status: CODEX_UNAVAILABLE" >> "$PIPELINE_LOG"
            REVIEW_RESULT="[Codex CLI unavailable - manual review required]"
        }

        # Save review result
        {
            echo "# レビュー結果: ${PROJECT_ID} #${TASK_NUM}"
            echo ""
            echo "| 項目 | 値 |"
            echo "|------|-----|"
            echo "| 案件ID | ${PROJECT_ID} |"
            echo "| タスク番号 | ${TASK_NUM} |"
            echo "| レビュー日時 | ${TIMESTAMP} |"
            echo "| レビュアー | Codex CLI (automated) |"
            echo ""
            echo "## レビュー結果"
            echo ""
            echo "$REVIEW_RESULT"
        } > "$REVIEW_OUTPUT"

        echo -e "${GREEN}[OK] Codex レビュー完了${NC}"
        echo -e "レビュー結果: ${GREEN}${REVIEW_OUTPUT}${NC}"
        echo "Status: SUCCESS" >> "$PIPELINE_LOG"
        echo "Output: ${REVIEW_OUTPUT}" >> "$PIPELINE_LOG"
    fi
    echo "" >> "$PIPELINE_LOG"
else
    echo ""
    echo -e "${YELLOW}[SKIP] Codex レビュー無効（--skip-review）${NC}"
    echo "## Step 3: Codex Review" >> "$PIPELINE_LOG"
    echo "Status: SKIPPED (--skip-review)" >> "$PIPELINE_LOG"
    echo "" >> "$PIPELINE_LOG"
fi

# ============================================================
# Summary
# ============================================================
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Pipeline Complete                       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "完了時刻: ${END_TIMESTAMP}"
echo ""
echo "Output files:"
[ -f "$GEMINI_OUTPUT" ] && echo -e "  Gemini:  ${GREEN}${GEMINI_OUTPUT}${NC}"
[ -f "$REVIEW_OUTPUT" ] && echo -e "  Review:  ${GREEN}${REVIEW_OUTPUT}${NC}"
echo -e "  Log:     ${GREEN}${PIPELINE_LOG}${NC}"
echo ""
echo "Next steps (Claude Code判断):"
echo "  1. Gemini出力を確認:  cat ${GEMINI_OUTPUT}"
[ "$SKIP_REVIEW" = false ] && echo "  2. レビュー結果を確認: cat ${REVIEW_OUTPUT}"
echo "  3. 必要に応じて修正"
echo "  4. テスト実行: npm test && npm run lint && npm run build"
echo "  5. 工程更新: /workflow:status ${PROJECT_ID}"

# Finalize pipeline log
{
    echo "## Summary"
    echo "Completed: ${END_TIMESTAMP}"
    PIPELINE_FLAGS=""
    if [ "$DRY_RUN" = true ]; then PIPELINE_FLAGS="${PIPELINE_FLAGS}DRY-RUN "; fi
    if [ "$SKIP_REVIEW" = true ]; then PIPELINE_FLAGS="${PIPELINE_FLAGS}SKIP-REVIEW "; fi
    if [ "$AUTO_APPLY" = true ]; then PIPELINE_FLAGS="${PIPELINE_FLAGS}AUTO-APPLY "; fi
    echo "Pipeline: ${PIPELINE_FLAGS:-STANDARD}"
} >> "$PIPELINE_LOG"
