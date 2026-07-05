#!/bin/bash
# block-clasp-deploy.sh - Block new clasp deployments
# PreToolUse hook for Claude Code
#
# Allow: clasp deploy -i <ID> (update existing deployment)
# Allow: clasp deployments (list)
# Block: clasp deploy (no args = create new)
# Block: clasp undeploy

INPUT=$(cat)

# --- Robust JSON field extraction (Python) --- (B1 fix, see block-sd-destructive.sh)
PY_BIN=""
if command -v python >/dev/null 2>&1; then
  PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
fi

extract_field() {
  if [ -z "$PY_BIN" ]; then
    printf ''
    return
  fi
  SD003_INPUT_JSON="$INPUT" SD003_FIELD="$1" "$PY_BIN" <<'PYEOF'
import os, json
try:
    data = json.loads(os.environ.get('SD003_INPUT_JSON', '') or '{}')
except Exception:
    data = {}
ti = data.get('tool_input', {})
if not isinstance(ti, dict):
    ti = {}
field = os.environ.get('SD003_FIELD', '')
v = ti.get(field)
if v is None:
    v = data.get(field, '')
if v is None:
    v = ''
if not isinstance(v, str):
    try:
        v = json.dumps(v, ensure_ascii=False)
    except Exception:
        v = str(v)
print(v)
PYEOF
}

COMMAND=$(extract_field command)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# --- B5 fix: BLOCK checks run before any allow early-exit ---
# The old code checked "allow clasp deployments" (unanchored substring match)
# FIRST and exited 0 immediately, so a compound command like
# `clasp deployments && clasp undeploy 123` matched the allow-list substring
# and bypassed the undeploy block entirely. Now: block patterns are checked
# unconditionally against the whole command (undeploy is never legitimate
# regardless of what else is chained), and "new deploy without -i/--deploymentId"
# is detected per-invocation via segment extraction so `clasp deployments`
# (which merely starts with the letters "deploy") is never mistaken for a
# `clasp deploy` invocation (word-boundary \b after "deploy" excludes it).

# Block clasp undeploy (checked first, unconditionally)
if echo "$COMMAND" | grep -qiE 'clasp\s+undeploy\b'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: clasp undeploy is prohibited."
  }
}
EOF
  exit 0
fi

# Block clasp deploy without -i / --deploymentId (creates new deployment).
# `clasp\s+deploy\b` requires a word boundary right after "deploy", so it
# does NOT match inside "deployments" (list command, always allowed).
DEPLOY_SEGMENTS=$(echo "$COMMAND" | grep -oiE 'clasp\s+deploy\b[^;&|]*')
if [ -n "$DEPLOY_SEGMENTS" ]; then
  BARE_DEPLOYS=$(echo "$DEPLOY_SEGMENTS" | grep -viE 'clasp\s+deploy\s+(-i|--deploymentId)\s')
  if [ -n "$BARE_DEPLOYS" ]; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: clasp deploy (new) is prohibited. Use clasp deploy -i <deploymentID> (or --deploymentId <ID>) to update an existing deployment."
  }
}
EOF
    exit 0
  fi
fi

exit 0
