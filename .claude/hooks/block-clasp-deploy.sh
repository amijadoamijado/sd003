#!/bin/bash
# block-clasp-deploy.sh - Block new clasp deployments
# PreToolUse hook for Claude Code
#
# Allow: clasp deploy -i <ID> (update existing deployment)
# Allow: clasp deployments (list)
# Block: clasp deploy (no args = create new)
# Block: clasp undeploy

INPUT=$(cat)

# Extract command field from JSON
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Allow clasp deployments (list)
if echo "$COMMAND" | grep -qiE 'clasp\s+deployments'; then
  exit 0
fi

# Allow clasp deploy -i (update existing)
if echo "$COMMAND" | grep -qiE 'clasp\s+deploy\s+-i\s'; then
  exit 0
fi

# Block clasp undeploy
if echo "$COMMAND" | grep -qiE 'clasp\s+undeploy'; then
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

# Block clasp deploy without -i (creates new deployment)
if echo "$COMMAND" | grep -qiE 'clasp\s+deploy'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: clasp deploy (new) is prohibited. Use clasp deploy -i <deploymentID> to update an existing deployment."
  }
}
EOF
  exit 0
fi

exit 0
