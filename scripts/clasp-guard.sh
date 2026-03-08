#!/bin/bash
# clasp-guard.sh - clasp deploy/undeploy を物理的にブロック
#
# Codex / Gemini CLI など hook が使えないAI向けのガード。
# package.json の gas:deploy 等から呼ばれる。
#
# 許可: clasp push, clasp pull, clasp status, clasp versions, clasp deployments
# 禁止: clasp deploy, clasp undeploy

SUBCOMMAND="${1:-}"

case "$SUBCOMMAND" in
  deploy|undeploy)
    echo "============================================" >&2
    echo "BLOCKED: clasp $SUBCOMMAND is prohibited." >&2
    echo "" >&2
    echo "GAS code sync uses 'clasp push' only." >&2
    echo "To update a fixed deployment, get explicit" >&2
    echo "user permission first." >&2
    echo "============================================" >&2
    exit 1
    ;;
  push|pull|status|versions|deployments|login|logout|open|logs|run|version)
    exec clasp "$@"
    ;;
  *)
    echo "clasp-guard: unknown subcommand '$SUBCOMMAND'" >&2
    echo "Allowed: push, pull, status, versions, deployments, login, logout, open, logs, run, version" >&2
    exit 1
    ;;
esac
