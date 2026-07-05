#!/bin/bash
# session-skill-suggest.sh - Suggest required SKILL.md at session start
# SessionStart hook for Claude Code
#
# Reads .sessions/session-current.md (P0/P1 sections) and matches keywords/paths
# against .claude/skills/registry.json. Outputs a banner listing required skills
# that have NOT been read yet.
#
# Information only — does NOT block. PreToolUse enforce-skill-read.sh blocks.

INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
SESSION_FILE="$PROJECT_DIR/.sessions/session-current.md"
REGISTRY="$PROJECT_DIR/.claude/skills/registry.json"
LOG_DIR="$HOME/.claude/state/sd003"

PY_BIN=""
if command -v python >/dev/null 2>&1; then
  PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
fi

# --- B18: session-scoped read-skills log path ---
# Key the log by session_id (byte-identical derivation to track-skill-read.sh /
# enforce-skill-read.sh). Fall back to the legacy shared path when session_id is
# unavailable. This must be computed before the reset below.
SID=""
if [ -n "$PY_BIN" ]; then
  SID=$(printf '%s' "$INPUT" | "$PY_BIN" -c 'import sys, json, re
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
sys.stdout.write(re.sub(r"[^A-Za-z0-9._-]", "", str(d.get("session_id", "") or "")))' 2>/dev/null)
fi
if [ -n "$SID" ]; then
  LOG_FILE="$LOG_DIR/read-skills-$SID.log"
else
  LOG_FILE="$LOG_DIR/read-skills.log"
fi

# --- B9 fix: reset the read-skills gate every SessionStart ---
# The log was never cleared, so "read the SKILL.md this session" quietly
# became "ever read it, in any session" -- a permanent unlock. With B18
# session scoping a fresh session already gets a fresh (nonexistent) file, so
# re-arming no longer depends on this reset; it is kept as belt-and-suspenders
# and to give an honest empty slate for the banner below. Runs unconditionally
# (before the SESSION_FILE/REGISTRY existence checks) so the gate re-arms even
# on the very first run of a new project.
mkdir -p "$LOG_DIR" 2>/dev/null
: > "$LOG_FILE" 2>/dev/null

if [ ! -f "$SESSION_FILE" ] || [ ! -f "$REGISTRY" ]; then
  exit 0
fi

if [ -z "$PY_BIN" ]; then
  exit 0
fi

export SD003_SESSION="$SESSION_FILE"
export SD003_REGISTRY="$REGISTRY"
export SD003_LOG="$LOG_FILE"

"$PY_BIN" <<'PYEOF'
import os, sys, json, re

session_path = os.environ.get('SD003_SESSION', '')
registry_path = os.environ.get('SD003_REGISTRY', '')
log_path = os.environ.get('SD003_LOG', '')

try:
    with open(session_path, 'r', encoding='utf-8') as f:
        session_text = f.read()
    with open(registry_path, 'r', encoding='utf-8') as f:
        reg = json.load(f)
except Exception:
    sys.exit(0)

# Extract P0 / P1 sections (everything until next ## or ###)
sections = re.findall(r'###?\s*(?:P0|P1)[^\n]*\n((?:(?!^###?\s).+\n?)*)', session_text, re.MULTILINE)
task_text = '\n'.join(sections).lower()

if not task_text.strip():
    sys.exit(0)

read_skills = set()
if os.path.exists(log_path):
    try:
        with open(log_path, 'r', encoding='utf-8') as f:
            read_skills = set(line.strip() for line in f if line.strip())
    except Exception:
        pass

required = []
for skill_id, meta in reg.get('skills', {}).items():
    if skill_id in read_skills:
        continue
    matched = False
    matched_by = ''
    for kw in meta.get('keywords', []):
        if kw and kw.lower() in task_text:
            matched = True
            matched_by = 'keyword "' + kw + '"'
            break
    if not matched:
        for p in meta.get('paths', []):
            if p and p.lower() in task_text:
                matched = True
                matched_by = 'path "' + p + '"'
                break
    if matched:
        required.append({
            'skill_id': skill_id,
            'skill_path': meta.get('skill_path', '.claude/skills/' + skill_id + '/SKILL.md'),
            'matched_by': matched_by,
            'severity': meta.get('severity', 'warn'),
            'reason': meta.get('reason', '')
        })

if not required:
    sys.exit(0)

# Output banner
print('')
print('=' * 70)
print('  SKILL.md GUARDRAIL — Required reading detected from P0/P1 tasks')
print('=' * 70)
for r in required:
    sev = '[BLOCK]' if r['severity'] == 'block' else '[warn]'
    print('  ' + sev + ' ' + r['skill_id'])
    print('    Matched by: ' + r['matched_by'])
    print('    File: ' + r['skill_path'])
    if r['reason']:
        print('    Why: ' + r['reason'])
    print('')
print('  PreToolUse enforcement is active. Read these SKILL.md files BEFORE')
print('  using Bash/Write/Edit on matching files; otherwise tool calls deny.')
print('=' * 70)
print('')
PYEOF

exit 0
