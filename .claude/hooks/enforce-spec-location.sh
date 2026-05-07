#!/bin/bash
# enforce-spec-location.sh - Block writing spec files outside .sd/specs/
# PreToolUse hook for Write/Edit/MultiEdit
#
# Background: at001-v1 incident (2026-05-07). AI placed spec files in
# docs/specs/at001-v1/ instead of SD003 standard .sd/specs/at001-v1/.
# Root cause: spec-driven.md had paths constraint ".sd/specs/**/*" which
# only fired AFTER files were placed there (chicken-and-egg). No physical
# guardrail existed.
#
# This hook denies Write/Edit/MultiEdit when target file path:
#   1. Contains "/specs/" (any dir named specs)
#   2. AND does NOT contain "/.sd/specs/"
# The user must move the file under .sd/specs/{feature}/ or revise the path.

INPUT=$(cat)

PY_BIN=""
if command -v python >/dev/null 2>&1; then
  PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
else
  exit 0
fi

export SD003_INPUT_JSON="$INPUT"

OUTPUT=$("$PY_BIN" <<'PYEOF'
import os, sys, json, re

try:
    data = json.loads(os.environ.get('SD003_INPUT_JSON', ''))
except Exception:
    sys.exit(0)

tool_name = data.get('tool_name', '')
if tool_name not in ('Write', 'Edit', 'MultiEdit'):
    sys.exit(0)

tool_input = data.get('tool_input', {}) or {}
file_path = tool_input.get('file_path') or data.get('file_path') or ''

if not file_path:
    sys.exit(0)

# Normalize path separators for matching
fp_norm = file_path.replace('\\', '/').lower()

# Heuristic: target looks like a spec location?
# Match if path contains "/specs/" segment (e.g. docs/specs/, my-specs/, etc.)
if '/specs/' not in fp_norm:
    sys.exit(0)

# Allow if under .sd/specs/ (canonical location)
if '/.sd/specs/' in fp_norm:
    sys.exit(0)

# Allow rules/templates/skills/commands/hooks themselves to mention spec paths
allowed_contexts = [
    '/.claude/rules/',
    '/.claude/skills/',
    '/.claude/commands/',
    '/.claude/hooks/',
    '/.claude/state/',
    '/docs/troubleshooting/',
    '/docs/core-doctrine',
    '/.handoff/',
    '/.sessions/',
    '/node_modules/',
    '/.git/',
]
for ctx in allowed_contexts:
    if ctx in fp_norm:
        sys.exit(0)

# This is a spec-like path NOT under .sd/specs/ → deny
msg = (
    'BLOCKED: Spec file placed outside .sd/specs/.\n'
    'File: ' + file_path + '\n'
    'SD003 standard requires spec files under: .sd/specs/{feature}/\n'
    'See .claude/rules/specs/spec-driven.md\n\n'
    'Required action:\n'
    '  - Move target path under .sd/specs/{feature}/\n'
    '  - Or, if this is not a SD003 spec, place under docs/ (not docs/specs/)\n\n'
    '(Physical guardrail - at001-v1 incident 2026-05-07 prevention.\n'
    'See docs/troubleshooting/RESOLUTION_LOG.md)'
)
out = {
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'deny',
        'permissionDecisionReason': msg
    }
}
print(json.dumps(out, ensure_ascii=False))
sys.exit(0)
PYEOF
)

if [ -n "$OUTPUT" ]; then
  echo "$OUTPUT"
fi

exit 0
