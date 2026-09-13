#!/bin/bash
# prune-skill-state.sh - Roll up expired per-session skill-read logs
# SessionStart hook for Claude Code
#
# track-skill-read.sh (PostToolUse/Read) writes one log per session:
#   ~/.claude/state/sd003/read-skills-<session_id>.log
# enforce-skill-read.sh (PreToolUse) reads only the CURRENT session's file, so
# every other file is dead weight the moment its session ends. Nothing ever
# removed them: by 2026-09-14 the directory held 3,949 files and `ls` on it was
# useless, which is how the stale-state problem stayed invisible.
#
# This hook is the guardrail for that. It is NOT a rule asking anyone to tidy up.
#
# Design constraints:
#   - Runs at SessionStart only (never per-Read): enforce/track hooks fire on
#     every tool call and must not pay for a directory scan.
#   - Throttled to once per 24h via a marker file, so repeated session starts
#     (crash recovery, --continue) cost one `stat`.
#   - Expired logs are rolled into a single tar.gz, not deleted outright, so the
#     data stays recoverable (SD003 rm禁止 / アーカイブ移動 の趣旨に合わせる).
#     One archive per prune run = at most ~365/year instead of thousands/month.
#   - Fail-open and silent: this hook must never block or noise up a session.
#   - Never touches read-skills.log (legacy shared fallback, no session id) or
#     intake-marker.json — the glob requires the "read-skills-" prefix.

# SessionStart delivers JSON on stdin; drain it so the writer never sees SIGPIPE.
cat >/dev/null 2>&1

RETENTION_DAYS=14
THROTTLE_SECONDS=86400

STATE_DIR="$HOME/.claude/state/sd003"
ARCHIVE_DIR="$STATE_DIR/archive"
MARKER="$STATE_DIR/.prune-last"

[ -d "$STATE_DIR" ] || exit 0

# --- throttle: at most one prune per 24h ---
if [ -f "$MARKER" ]; then
  last=$(stat -c %Y "$MARKER" 2>/dev/null || echo 0)
  now=$(date +%s)
  if [ $((now - last)) -lt "$THROTTLE_SECONDS" ]; then
    exit 0
  fi
fi

# --- collect expired per-session logs ---
list_file=$(mktemp 2>/dev/null) || exit 0
trap 'rm -f "$list_file" 2>/dev/null' EXIT

find "$STATE_DIR" -maxdepth 1 -type f -name 'read-skills-*.log' \
     -mtime +"$RETENTION_DAYS" -printf '%f\n' 2>/dev/null > "$list_file"

count=$(wc -l < "$list_file" 2>/dev/null || echo 0)
if [ "$count" -eq 0 ]; then
  touch "$MARKER" 2>/dev/null
  exit 0
fi

# --- roll up, then remove only what the archive actually contains ---
mkdir -p "$ARCHIVE_DIR" 2>/dev/null || exit 0
stamp=$(date +%Y%m%d-%H%M%S)
archive="$ARCHIVE_DIR/read-skills-pruned-${stamp}.tar.gz"

if ! tar --force-local -czf "$archive" -C "$STATE_DIR" -T "$list_file" 2>/dev/null; then
  rm -f "$archive" 2>/dev/null
  exit 0
fi

# Verify the archive is readable and non-empty before deleting the originals.
if ! tar --force-local -tzf "$archive" >/dev/null 2>&1 || [ ! -s "$archive" ]; then
  rm -f "$archive" 2>/dev/null
  exit 0
fi

# Delete via xargs, NOT a per-file `rm` loop. MSYS2/Git Bash pays ~30-67ms per
# process spawn, so a loop over a few thousand files costs ~90s and would stall
# session start; xargs packs hundreds of names into each rm. (2026-09-14 実測:
# 2,784件で 89秒 → 1秒未満)
(cd "$STATE_DIR" 2>/dev/null && xargs -a "$list_file" -d '\n' rm -f 2>/dev/null)

touch "$MARKER" 2>/dev/null
exit 0
