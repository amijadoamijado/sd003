#!/usr/bin/env bash
# codex-run.sh — 正準 codex dispatch（フラグを間違えない決定論入口）
# 2026-05-26 事故対策: 素の `codex exec ... 2>&1 | tee` を禁止し、正しい invocation を1点に集約。
#
# usage: codex-run.sh <repo> <out.md> <read-only|workspace-write> "<prompt>"
#   <repo>    : 作業ディレクトリ（リポジトリ直下）
#   <out.md>  : 最終回答の出力先（cleanな最終メッセージのみ）
#   <sandbox> : read-only（レビュー/調査の既定）/ workspace-write（編集タスク）
#   <prompt>  : codex への指示本文
set -u
REPO="${1:?repo}"; OUT="${2:?out.md}"; SANDBOX="${3:?read-only|workspace-write}"; PROMPT="${4:?prompt}"
PROG="${OUT%.md}.progress.log"

# --- preflight: OOM/詰まり防止（pwsh 非搭載環境では警告をスキップ）---
FREE=$(pwsh -NoProfile -Command "[int]((Get-CIMInstance Win32_OperatingSystem).FreePhysicalMemory/1024)" 2>/dev/null | tr -dc '0-9')
[ -z "$FREE" ] && FREE=0
if [ "$FREE" -gt 0 ] && [ "$FREE" -lt 5000 ]; then
  echo "WARN: free RAM ${FREE}MB < 5000MB — OOM 危険。人手ハンドオフ推奨（SKILL.md 参照）。" >&2
fi
if pwsh -NoProfile -Command "Get-Process codex,agy -ErrorAction SilentlyContinue" 2>/dev/null | grep -qiE 'codex|agy'; then
  echo "WARN: 既存 codex/agy が稼働中。同時実行は OOM / knowledge.lock 競合。確認してから続行。" >&2
fi

# --- run（正準）---
rm -f "$OUT"
RUST_LOG=error codex exec "$PROMPT" \
  --cd "$REPO" \
  -c model_reasoning_effort="medium" \
  --ignore-user-config \
  --sandbox "$SANDBOX" \
  -o "$OUT" \
  2> "$PROG"
RC=$?

# --- verify（出力検証）---
if [ -s "$OUT" ]; then
  echo "OK rc=$RC out=$OUT bytes=$(wc -c < "$OUT")"
  exit 0
else
  echo "FAIL rc=$RC: $OUT 未生成。盲目リトライ禁止。progress tail:" >&2
  tail -12 "$PROG" >&2 2>/dev/null
  exit 1
fi
