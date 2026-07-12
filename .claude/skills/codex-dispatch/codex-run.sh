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
[ -f "$PROMPT" ] && PROMPT="$(cat "$PROMPT")"
PROG="${OUT%.md}.progress.log"

# --- preflight: OOM/詰まり防止（pwsh 非搭載環境では警告をスキップ）---
FREE=$(pwsh -NoProfile -Command "[int]((Get-CIMInstance Win32_OperatingSystem).FreePhysicalMemory/1024)" 2>/dev/null | tr -dc '0-9')
[ -z "$FREE" ] && FREE=0
if [ "$FREE" -gt 0 ] && [ "$FREE" -lt 5000 ]; then
  echo "WARN: free RAM ${FREE}MB < 5000MB — OOM 危険。人手ハンドオフ推奨（SKILL.md 参照）。" >&2
fi
if pwsh -NoProfile -Command "Get-Process codex,agy,grok,claude -ErrorAction SilentlyContinue" 2>/dev/null | grep -qiE 'codex|agy|grok|claude'; then
  echo "WARN: 既存 codex/agy が稼働中。同時実行は OOM / knowledge.lock 競合。確認してから続行。" >&2
fi
if [ -f "$REPO/.git/sd-lead.lock" ] && [ -n "${SD003_LEAD_AI:-}" ]; then
  HOLDER=$(pwsh -NoProfile -Command "(Get-Content '$REPO/.git/sd-lead.lock' -Raw | ConvertFrom-Json).ai")
  [ "$HOLDER" != "$SD003_LEAD_AI" ] && { echo "FAIL: repo lock held by $HOLDER" >&2; exit 1; }
fi

# --- run（正準）---
rm -f "$OUT"
# --ignore-user-config はWindows sandbox設定を無効化して沈黙失敗させるため使用しない（2026-07-12実測）。
RUST_LOG=error codex exec "$PROMPT" \
  --cd "$REPO" \
  -c model_reasoning_effort="medium" \
  --sandbox "$SANDBOX" \
  -o "$OUT" \
  2> "$PROG" < /dev/null
RC=$?

# --- verify（出力検証）---
if [ "$RC" -eq 0 ] && [ -s "$OUT" ]; then
  echo "OK rc=$RC out=$OUT bytes=$(wc -c < "$OUT")"
  exit 0
else
  echo "FAIL rc=$RC: $OUT 未生成。盲目リトライ禁止。progress tail:" >&2
  tail -12 "$PROG" >&2 2>/dev/null
  exit 1
fi
