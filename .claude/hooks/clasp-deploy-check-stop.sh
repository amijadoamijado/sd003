#!/bin/bash
# clasp-deploy-check-stop.sh - Check for missed deploys on session exit
# Stop hook for Claude Code
#
# Warns if .clasp-deploy-state remains:
# needs-push: GAS files edited but not pushed
# needs-deploy: pushed but not deployed

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.clasp-deploy-state"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

STATE=$(cat "$STATE_FILE")

case "$STATE" in
  "needs-push")
    cat <<'EOF' >&2

WARNING: GAS files changed but NOT pushed!

  Run:
    1. clasp push
    2. clasp deploy -i <deploymentID>

  Changes are not reflected in production URL.
EOF
    exit 1
    ;;
  "needs-deploy")
    cat <<'EOF' >&2

WARNING: clasp push done but NOT deployed!

  To reflect in production URL:
    clasp deploy -i <deploymentID>

  Check deployment ID: clasp deployments

  Only @HEAD is updated. Production URL still uses old version.
EOF
    exit 1
    ;;
esac

exit 0
