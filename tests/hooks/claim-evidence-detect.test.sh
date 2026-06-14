#!/bin/bash
# Regression test for claim_evidence_detect.py (sd003 /ai-suspect guardrail, 2026-06-14).
# Proves the deterministic detector: causal-confirmation AND no-evidence => FLAG; else OK.
set -u
PY=$(command -v python 2>/dev/null || command -v python3 2>/dev/null)
DET="$(cd "$(dirname "$0")/../.." && pwd)/.claude/hooks/claim_evidence_detect.py"
fail=0

check() { # $1=label $2=expected $3=text $4=had_tool_use
  got=$("$PY" "$DET" check "$3" "$4")
  if [ "$got" = "$2" ]; then
    echo "PASS $1"
  else
    echo "FAIL $1: got '$got' want '$2'"; fail=1
  fi
}

# POSITIVE: causal-confirmation, no evidence, no tool_use -> FLAG (the actual misconduct shape)
check "case1 unevidenced causal claim" FLAG "効かない原因は起動方法です。プランモードで起動された。" 0
# NEGATIVE: same causal claim but WITH a path:line citation -> OK
check "case2 evidenced via path:line" OK "原因は設定です。証拠: settings.json:8 に acceptEdits があります。" 0
# NEGATIVE: causal claim but a tool was run this turn -> OK
check "case3 evidenced via tool_use" OK "原因はXだ。" 1
# NEGATIVE: no causal-confirmation language at all -> OK
check "case4 no causal claim" OK "次に at002 を commit しますか？" 0

if [ "$fail" = "0" ]; then echo "ALL PASS"; exit 0; else echo "FAILURES"; exit 1; fi
