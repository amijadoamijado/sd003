#!/bin/bash
# recover-agy-artifacts.sh — Recover agy (Antigravity CLI) deliverables that were
# saved into the AppData hidden per-conversation dir instead of the project tree.
#
# agy writes generated reports/documents to ~/.gemini/antigravity-cli/brain/<uuid>/
# (a hidden, per-conversation git repo). CLI users cannot find them. This sweeps
# recent deliverable files from there into the project so they are visible.
#
# NON-DESTRUCTIVE: copies (never moves/deletes). Originals in brain/ are untouched.
# See .claude/rules/workflow/artifact-output-location.md
#
# Usage:
#   bash scripts/recover-agy-artifacts.sh              # last 48h -> materials/_agy-recovered/<date>/
#   bash scripts/recover-agy-artifacts.sh --hours 6    # last 6h
#   bash scripts/recover-agy-artifacts.sh --dry-run    # preview only

set -u

HOURS=48
DRYRUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --hours) HOURS="${2:-48}"; shift 2 ;;
    --dry-run|-n) DRYRUN=1; shift ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Project root: prefer CLAUDE_PROJECT_DIR, else git toplevel, else cwd.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

BRAIN="$HOME/.gemini/antigravity-cli/brain"
if [ ! -d "$BRAIN" ]; then
  echo "agy brain dir not found: $BRAIN (nothing to recover)"
  exit 0
fi

# Date-stamped inbox. NOTE: date only (no time) so a same-day re-run reuses the
# folder; the runtime forbids Date.now-style calls only in workflow scripts, not
# here, so `date` is fine in a shell tool.
STAMP="$(date '+%Y%m%d')"
DEST="$PROJECT_DIR/materials/_agy-recovered/$STAMP"

# Find deliverable files: recent, excluding git internals / agy system logs.
mapfile -t FILES < <(
  find "$BRAIN" -type f -mmin "-$((HOURS*60))" 2>/dev/null \
    | grep -v '/\.git/' \
    | grep -v '/\.system_generated/' \
    | grep -v '/scratch/' \
    | grep -viE '/transcript\.jsonl$|/\.gitignore$'
)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No agy deliverables modified in the last ${HOURS}h under $BRAIN"
  exit 0
fi

echo "Found ${#FILES[@]} candidate file(s) in the last ${HOURS}h."
echo "Destination: $DEST"
[ "$DRYRUN" -eq 1 ] && echo "(--dry-run: no files will be copied)"
echo

copied=0
for src in "${FILES[@]}"; do
  # brain/<uuid>/....  -> prefix basename with short conversation id to avoid clashes
  rel="${src#"$BRAIN"/}"
  convo="${rel%%/*}"
  short="${convo:0:8}"
  base="$(basename "$src")"
  out="$DEST/${short}__${base}"
  if [ "$DRYRUN" -eq 1 ]; then
    echo "would copy: $src"
    echo "        -> $out"
  else
    mkdir -p "$DEST"
    if cp -p "$src" "$out" 2>/dev/null; then
      echo "recovered: $out"
      copied=$((copied+1))
    else
      echo "FAILED to copy: $src" >&2
    fi
  fi
done

echo
if [ "$DRYRUN" -eq 1 ]; then
  echo "Preview complete. Re-run without --dry-run to copy into the project."
else
  echo "Recovered $copied file(s) into: $DEST"
  echo "Review and move each into its proper home (materials/text, docs/, the right project, etc.)."
fi
exit 0
