#!/bin/bash
# track-skill-read.sh - Track which SKILL.md files have been Read in this session
# PostToolUse hook for Claude Code (Read)
#
# Records skill IDs to a per-session read-skills log when AI reads
# .claude/skills/<skill-id>/SKILL.md
#
# Pairs with enforce-skill-read.sh (PreToolUse) which checks the same log
# to decide whether to block file operations on registered skill targets.
#
# B18 (session scoping): the log is keyed by session_id
# (~/.claude/state/sd003/read-skills-<session_id>.log). Previously a single
# fixed path was shared across ALL sessions/projects, so two concurrent
# sessions clobbered each other's read-history (false block) or leaked it
# (false unlock). When session_id is unavailable the path falls back to the
# legacy shared file; enforce-skill-read.sh / session-skill-suggest.sh use the
# byte-identical derivation, so the three hooks always agree -> no regression.
#
# JSON is parsed with Python (not sed): sed-based field extraction is bypassable
# and was the class of bug removed from the other guardrail hooks.

INPUT=$(cat)

PY_BIN=""
if command -v python >/dev/null 2>&1; then
  PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
else
  # No Python available — nothing tracked (enforce-skill-read fails open too).
  exit 0
fi

export SD003_INPUT_JSON="$INPUT"

"$PY_BIN" <<'PYEOF'
import os, sys, json, re

try:
    data = json.loads(os.environ.get('SD003_INPUT_JSON', ''))
except Exception:
    sys.exit(0)

if data.get('tool_name', '') != 'Read':
    sys.exit(0)

tool_input = data.get('tool_input', {}) or {}
file_path = tool_input.get('file_path') or data.get('file_path') or ''
if not file_path:
    sys.exit(0)

# Match .claude/skills/<skill-id>/SKILL.md (forward or back slash)
m = re.search(r'\.claude[/\\]skills[/\\]([^/\\]+)[/\\]SKILL\.md', file_path)
if not m:
    sys.exit(0)
skill_id = m.group(1)

state_dir = os.path.join(os.path.expanduser('~'), '.claude', 'state', 'sd003')
sid = re.sub(r'[^A-Za-z0-9._-]', '', str(data.get('session_id', '') or ''))
log_file = os.path.join(state_dir, 'read-skills-' + sid + '.log') if sid \
    else os.path.join(state_dir, 'read-skills.log')

try:
    os.makedirs(state_dir, exist_ok=True)
except Exception:
    pass

# Append only if not already present (idempotent)
existing = set()
if os.path.exists(log_file):
    try:
        with open(log_file, 'r', encoding='utf-8') as f:
            existing = set(line.strip() for line in f if line.strip())
    except Exception:
        pass

if skill_id not in existing:
    try:
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(skill_id + '\n')
    except Exception:
        pass

sys.exit(0)
PYEOF

exit 0
