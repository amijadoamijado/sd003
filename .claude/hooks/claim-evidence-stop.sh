#!/bin/bash
# claim-evidence-stop.sh - Stop hook: non-blocking warn on unevidenced causal-confirmation claims.
# Guards sd003 /ai-suspect 2026-06-14 root cause (証拠より語りを優先する過信). fail-open.
# Delegates detection to claim_evidence_detect.py (deterministic, regression-tested).
INPUT=$(cat)
PY=$(command -v python 2>/dev/null || command -v python3 2>/dev/null)
if [ -z "$PY" ]; then
  printf '%s' '{"decision":"approve"}'
  exit 0
fi
OUT=$(printf '%s' "$INPUT" | "$PY" "$CLAUDE_PROJECT_DIR/.claude/hooks/claim_evidence_detect.py" gate)
if [ -z "$OUT" ]; then
  printf '%s' '{"decision":"approve"}'
else
  printf '%s' "$OUT"
fi
exit 0
