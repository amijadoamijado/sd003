#!/bin/bash
# session-skill-suggest.sh - Suggest required SKILL.md at session start
# SessionStart hook for Claude Code
#
# Reads .sessions/session-current.md (P0/P1 sections) and matches keywords/paths
# against .claude/skills/registry.json. Outputs a banner listing required skills
# that have NOT been read yet.
#
# Information only — does NOT block. PreToolUse enforce-skill-read.sh blocks.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
SESSION_FILE="$PROJECT_DIR/.sessions/session-current.md"
REGISTRY="$PROJECT_DIR/.claude/skills/registry.json"
LOG_FILE="$HOME/.claude/state/sd003/read-skills.log"

if [ ! -f "$SESSION_FILE" ] || [ ! -f "$REGISTRY" ]; then
  exit 0
fi

PY_BIN=""
if command -v python >/dev/null 2>&1; then
  PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
else
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
