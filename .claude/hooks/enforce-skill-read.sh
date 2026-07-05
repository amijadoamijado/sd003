#!/bin/bash
# enforce-skill-read.sh - Block tool use when required SKILL.md is not read
# PreToolUse hook for Claude Code (Bash, Write, Edit, MultiEdit)
#
# Reads .claude/skills/registry.json and matches:
#   - file extensions (*.csv, *.xlsx)
#   - keywords (奉行, 弥生, openpyxl, etc.)
#   - path fragments (サクセス/, 山一/)
# against the current tool input (command/file_path/edits). If a registered
# skill matches and the corresponding SKILL.md was NOT read in this session
# (per ~/.claude/state/sd003/read-skills.log), return permissionDecision=deny.
#
# Pairs with track-skill-read.sh (PostToolUse Read) which writes to the log.
#
# Background: cf001 (Excel COM ignored, xlsx library used → format破壊),
# サクセス変換 (SKILL.md unread → 複合仕訳バグ). Both were "rule declared but not enforced".

INPUT=$(cat)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

REGISTRY="$PROJECT_DIR/.claude/skills/registry.json"

if [ ! -f "$REGISTRY" ]; then
  exit 0
fi

# Pick Python (Windows: python; Linux/Mac: python3)
PY_BIN=""
if command -v python >/dev/null 2>&1; then
  PY_BIN="python"
elif command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
else
  # No Python available — fail open
  exit 0
fi

export SD003_REGISTRY="$REGISTRY"
export SD003_INPUT_JSON="$INPUT"

OUTPUT=$("$PY_BIN" <<'PYEOF'
import os, sys, json, re

try:
    data = json.loads(os.environ.get('SD003_INPUT_JSON', ''))
except Exception:
    sys.exit(0)

tool_name = data.get('tool_name', '')
if tool_name not in ('Bash', 'Write', 'Edit', 'MultiEdit'):
    sys.exit(0)

# Claude Code passes inputs under "tool_input"; older harness may put them top-level
tool_input = data.get('tool_input', {}) or {}
command = tool_input.get('command') or data.get('command') or ''
file_path = tool_input.get('file_path') or data.get('file_path') or ''
old_string = tool_input.get('old_string') or ''
new_string = tool_input.get('new_string') or ''
content = tool_input.get('content') or ''

edits = tool_input.get('edits') or []
edit_text = ''
for e in edits:
    if isinstance(e, dict):
        edit_text += ' ' + str(e.get('old_string', '')) + ' ' + str(e.get('new_string', ''))

haystack = ' '.join(str(p) for p in [command, file_path, old_string, new_string, content, edit_text] if p)
haystack_lower = haystack.lower()

if not haystack.strip():
    sys.exit(0)

registry_path = os.environ.get('SD003_REGISTRY', '')

# Session-scoped read-skills log (B18). Previously a single fixed path shared
# across ALL sessions/projects, so concurrent sessions clobbered each other's
# read-history (false block) or leaked it (false unlock). Key by session_id;
# fall back to the legacy shared path when session_id is absent. track-skill-read.sh
# and session-skill-suggest.sh use the byte-identical derivation, so within a
# session the three hooks always resolve to the same file -> no regression, no
# hard-lock even if session_id is ever missing (both writer and reader fall back
# together).
_state_dir = os.path.join(os.path.expanduser('~'), '.claude', 'state', 'sd003')
_sid = re.sub(r'[^A-Za-z0-9._-]', '', str(data.get('session_id', '') or ''))
log_path = os.path.join(_state_dir, 'read-skills-' + _sid + '.log') if _sid \
    else os.path.join(_state_dir, 'read-skills.log')

try:
    with open(registry_path, 'r', encoding='utf-8') as f:
        reg = json.load(f)
except Exception:
    sys.exit(0)

# Safe-extension early exit (Write/Edit/MultiEdit only):
# If the target file's extension is in extensions_safe (e.g. .md, .txt, .json),
# do NOT block based on content. The risk is in the target file type, not in
# whatever keywords happen to appear in markdown body / commit messages / etc.
safe_exts = [e.lower() for e in reg.get('exclusions', {}).get('extensions_safe', [])]
if tool_name in ('Write', 'Edit', 'MultiEdit') and file_path:
    fp_lower = file_path.lower()
    for safe_ext in safe_exts:
        if fp_lower.endswith(safe_ext):
            sys.exit(0)

# Path-based exclusions (e.g. node_modules/, .git/, logs/)
for excl in reg.get('exclusions', {}).get('paths', []):
    if excl.lower() in haystack_lower:
        sys.exit(0)

# Read-skills log (skills that were Read this session)
read_skills = set()
if os.path.exists(log_path):
    try:
        with open(log_path, 'r', encoding='utf-8') as f:
            read_skills = set(line.strip() for line in f if line.strip())
    except Exception:
        pass

for skill_id, meta in reg.get('skills', {}).items():
    if skill_id in read_skills:
        continue
    matched = False
    matched_by = ''

    # extensions (substring match in haystack)
    for ext in meta.get('extensions', []):
        suffix = ext.lstrip('*').lower()
        if not suffix:
            continue
        if suffix in haystack_lower:
            matched = True
            matched_by = 'extension ' + ext
            break

    # keywords
    if not matched:
        for kw in meta.get('keywords', []):
            if not kw:
                continue
            if kw.lower() in haystack_lower:
                matched = True
                matched_by = 'keyword "' + kw + '"'
                break

    # path fragments
    if not matched:
        for p in meta.get('paths', []):
            if not p:
                continue
            if p.lower() in haystack_lower:
                matched = True
                matched_by = 'path "' + p + '"'
                break

    if not matched:
        continue

    severity = meta.get('severity', 'warn')
    skill_path = meta.get('skill_path', '.claude/skills/' + skill_id + '/SKILL.md')
    reason = meta.get('reason', '')

    if severity == 'block':
        msg = (
            'BLOCKED: Required SKILL.md not read.\n'
            'Skill: ' + skill_id + '\n'
            'Matched by: ' + matched_by + '\n'
            'Reason: ' + reason + '\n\n'
            'Required action: Read ' + skill_path + ' first, then retry this tool.\n'
            '(Physical guardrail - cf001 / サクセス variant prevention. '
            'See .claude/rules/skills/skill-check-before-action.md)'
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
    else:
        sys.stderr.write('WARN: SKILL recommended (not blocking): ' + skill_id + ' - ' + reason + '\n')

sys.exit(0)
PYEOF
)

# Print decision JSON to stdout (Claude Code reads stdout for hookSpecificOutput)
if [ -n "$OUTPUT" ]; then
  echo "$OUTPUT"
fi

# Hook always exits 0; the permission decision is conveyed via JSON
exit 0
