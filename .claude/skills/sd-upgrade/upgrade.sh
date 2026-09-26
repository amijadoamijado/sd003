#!/bin/bash
# SD003 Safe Framework Upgrade (Bash)
# Replaces an OLDER SD003 install with the latest framework, removing deprecated
# artifacts WITHOUT touching the project's own code/data.
#
# Usage:
#   ./upgrade.sh <target-project> [--execute] [--include-optional]
#   (default = DRY-RUN. Add --execute to apply.)

set -e

TARGET_PROJECT=""
EXECUTE=false
INCLUDE_OPTIONAL=false
for arg in "$@"; do
    case "$arg" in
        --execute) EXECUTE=true ;;
        --include-optional) INCLUDE_OPTIONAL=true ;;
        *) [ -z "$TARGET_PROJECT" ] && TARGET_PROJECT="$arg" ;;
    esac
done
[ -z "$TARGET_PROJECT" ] && { echo "Error: target project path required"; exit 1; }

SOURCE_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
DEPLOY_SH="$SOURCE_DIR/.claude/skills/sd-deploy/deploy.sh"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MODE=$([ "$EXECUTE" = true ] && echo "EXECUTE" || echo "DRY-RUN")

# Deprecated dirs/files. `.agent` (singular) and `.codex/skills` are deprecated;
# `.agents/skills` is the shared canonical Codex/agy path.
DEPRECATED_DIRS=(".gemini" ".cursor" ".windsurf" ".qwen" ".agent" ".kiro" ".codex/prompts" ".codex/skills" ".antigravity/commands" ".antigravity/skills" ".claude/skills/notebooklm-memory" ".agents/skills/notebooklm-memory" ".grok/skills/notebooklm-memory")
DEPRECATED_FILES=("GEMINI.md" "gemini.md" "scripts/sync-gemini-features.js" "scripts/migrate-kiro-to-sd.ps1" ".antigravity/rules.md")

# Over-engineering artifacts removed from SD003 on 2026-07-05 (Ralph Loop / refactor
# system / 7-stage workflow / context-autonomy). They were archived out of the framework
# body, but deploy only COPIES+overwrites — it never prunes files that no longer exist in
# source. Without purging these here, every upgraded project keeps ORPHANED command/skill/
# rule files that reference deleted rules. Matched across ALL known roots (.claude, the
# generated skill dirs .agents/.grok, and the .sd generated mirrors). .gemini mirror
# copies are already covered by the wholesale .gemini removal above.
OVERENG_CMD_NAMES=("ralph-wiggum-plan" "ralph-wiggum-run" "ralph-wiggum-status" "refactor-batch" "refactor-complete" "refactor-init" "refactor-plan" "refactor-rollback" "sd003-loop-lint" "sd003-loop-test" "sd003-loop-type" "workflow-impl")
OVERENG_SKILL_NAMES=("context-autonomy" "rollback-guard" "session-autosave")
OVERENG_EXTRA=(".claude/hooks/context-monitor-hook.ps1" ".claude/rules/ralph-loop.md" ".claude/rules/refactoring" ".sd/ralph" ".sd/refactor")

# Lean migration (2026-07-26): 17 always-loaded rule files moved to docs/rules-reference/
# in SD003. Archive-moved (reversible) unless protected by .sd003-keep / .sd003-profile.
# Spec: .sd/specs/lean-deploy-propagation/spec.md
LEAN_LEGACY_RULES=(
    ".claude/rules/git/branch-strategy.md"
    ".claude/rules/global/artifact-confirmation.md"
    ".claude/rules/global/fullpath-display.md"
    ".claude/rules/global/known-unknowns.md"
    ".claude/rules/global/output-primacy.md"
    ".claude/rules/global/project-branching.md"
    ".claude/rules/global/quiz-gate.md"
    ".claude/rules/global/real-data-first.md"
    ".claude/rules/global/segmented-sequencing.md"
    ".claude/rules/global/silent-interior.md"
    ".claude/rules/global/work-first.md"
    ".claude/rules/session/memory-nudge.md"
    ".claude/rules/skills/learning-nudge.md"
    ".claude/rules/troubleshooting/bug-quick.md"
    ".claude/rules/troubleshooting/dialogue-resolution.md"
    ".claude/rules/troubleshooting/root-cause-first.md"
    ".claude/rules/workflow/artifact-output-location.md"
)

# .sd003-keep protects every archive move, including deprecated artifacts.
# A directory containing a protected descendant must also remain in place.
UP_KEEP_PATTERNS=()
if [ -f "$TARGET_PROJECT/.sd003-keep" ]; then
    up_first=true
    while IFS= read -r line; do
        if [ "$up_first" = true ]; then line="${line#$'\xef\xbb\xbf'}"; up_first=false; fi
        line="$(echo "$line" | sed 's/[[:space:]]*$//;s/^[[:space:]]*//')"
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        UP_KEEP_PATTERNS+=("${line%/}")
    done < "$TARGET_PROJECT/.sd003-keep"
fi
up_is_kept() {
    local rel pat rel_lc pat_lc
    rel="${1#/}"
    rel_lc="$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')"
    for pat in "${UP_KEEP_PATTERNS[@]}"; do
        pat_lc="$(printf '%s' "$pat" | tr '[:upper:]' '[:lower:]')"
        [ "$rel_lc" = "$pat_lc" ] && return 0
        case "$rel_lc" in "$pat_lc"/*) return 0 ;; esac
        case "$pat_lc" in *[\*\?]*) case "$rel_lc" in $pat_lc) return 0 ;; esac ;; esac
    done
    return 1
}

up_is_kept_move() {
    local rel="${1#/}" pat child child_rel rel_lc pat_lc
    up_is_kept "$rel" && return 0
    if [ -d "$TARGET_PROJECT/$rel" ]; then
        rel_lc="$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')"
        for pat in "${UP_KEEP_PATTERNS[@]}"; do
            pat_lc="$(printf '%s' "$pat" | tr '[:upper:]' '[:lower:]')"
            case "$pat_lc" in "$rel_lc"/*) return 0 ;; esac
        done
        while IFS= read -r -d '' child; do
            child_rel="${child#"$TARGET_PROJECT"/}"
            up_is_kept "$child_rel" && return 0
        done < <(find "$TARGET_PROJECT/$rel" -mindepth 1 -print0)
    fi
    return 1
}

# .sd003-profile: per-project tuning (plain key=value, '#' comments)
#   lean-migration = standard | additive | off      (default: standard)
#   keep-always-loaded = <relpath under .claude/rules/>   (repeatable)
#   settings-merge = on | off   (default: off) kept settings.json is realigned by deploy
LEAN_MODE="standard"
KEEP_ALWAYS=()
SETTINGS_MERGE=off
if [ -f "$TARGET_PROJECT/.sd003-profile" ]; then
    pf_first=true
    while IFS= read -r line; do
        if [ "$pf_first" = true ]; then line="${line#$'\xef\xbb\xbf'}"; pf_first=false; fi
        line="$(echo "$line" | sed 's/[[:space:]]*$//;s/^[[:space:]]*//')"
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        case "$line" in
            lean-migration*=*) LEAN_MODE="$(echo "${line#*=}" | tr -d ' ' | tr '[:upper:]' '[:lower:]')" ;;
            keep-always-loaded*=*) KEEP_ALWAYS+=("$(echo "${line#*=}" | tr -d ' ')") ;;
            settings-merge*=*) SETTINGS_MERGE="$(echo "${line#*=}" | sed 's/#.*//' | tr -d ' ' | tr '[:upper:]' '[:lower:]')" ;;
        esac
    done < "$TARGET_PROJECT/.sd003-profile"
    echo "[.sd003-profile] lean-migration=$LEAN_MODE, keep-always-loaded: ${#KEEP_ALWAYS[@]} entries, settings-merge=$SETTINGS_MERGE"
fi

echo "=== SD003 Safe Upgrade ($MODE) ==="
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_PROJECT"
echo ""

# Phase 1: validate
[ ! -d "$TARGET_PROJECT" ] && { echo "Error: target not found"; exit 1; }
[ ! -d "$TARGET_PROJECT/.git" ] && echo "WARN: target is not a git repo. 'git init' recommended for rollback safety."
[ ! -f "$DEPLOY_SH" ] && { echo "Error: deploy.sh not found at $DEPLOY_SH"; exit 1; }

# Phase 2: detect
DEL_DIRS=(); for d in "${DEPRECATED_DIRS[@]}"; do [ -e "$TARGET_PROJECT/$d" ] && ! up_is_kept_move "$d" && DEL_DIRS+=("$d"); done
DEL_FILES=(); for f in "${DEPRECATED_FILES[@]}"; do [ -e "$TARGET_PROJECT/$f" ] && ! up_is_kept_move "$f" && DEL_FILES+=("$f"); done

# Expand over-engineering artifacts to concrete relative paths across all roots; keep present ones.
OVERENG_ALL=()
for c in "${OVERENG_CMD_NAMES[@]}"; do
    OVERENG_ALL+=(".claude/commands/$c.md" ".sd/commands/specs/$c.md" ".agents/skills/$c" ".grok/skills/$c")
done
for s in "${OVERENG_SKILL_NAMES[@]}"; do
    OVERENG_ALL+=(".claude/skills/$s" ".agents/skills/$s" ".grok/skills/$s")
done
OVERENG_ALL+=("${OVERENG_EXTRA[@]}")
DEL_OVERENG=(); for p in "${OVERENG_ALL[@]}"; do [ -e "$TARGET_PROJECT/$p" ] && ! up_is_kept_move "$p" && DEL_OVERENG+=("$p"); done

# Retired hooks: removed only when the target's settings.json will not still call them
# (regenerated from the template, or not mentioning the hook). A kept settings.json that
# still registers one would error on every tool call if the file disappeared.
RETIRED_HOOKS=(".claude/hooks/workflow-gate.sh" ".claude/hooks/workflow-state-tracker.sh")
RETIRED_HOOKS_BLOCKED=()
for h in "${RETIRED_HOOKS[@]}"; do
    [ -e "$TARGET_PROJECT/$h" ] || continue
    up_is_kept_move "$h" && continue
    # settings-merge=on: deploy rewrites the kept registration away, so the file can go.
    if up_is_kept ".claude/settings.json" && [ "$SETTINGS_MERGE" != on ] && [ -f "$TARGET_PROJECT/.claude/settings.json" ] && grep -qF "$(basename "$h")" "$TARGET_PROJECT/.claude/settings.json"; then
        RETIRED_HOOKS_BLOCKED+=("$h")
    else
        DEL_OVERENG+=("$h")
    fi
done

# Lean migration detection (keep/profile-aware; honesty: flag local edits)
LEAN_MIGRATE=(); LEAN_KEPT=(); LEAN_CUSTOMIZED=()
if [ "$LEAN_MODE" != "off" ]; then
    for r in "${LEAN_LEGACY_RULES[@]}"; do
        [ -e "$TARGET_PROJECT/$r" ] || continue
        short="${r#.claude/rules/}"
        kept=false
        up_is_kept "$r" && kept=true
        for ka in "${KEEP_ALWAYS[@]}"; do [ "$ka" = "$short" ] && kept=true; done
        if [ "$kept" = true ]; then LEAN_KEPT+=("$r"); continue; fi
        LEAN_MIGRATE+=("$r")
        ref="$SOURCE_DIR/docs/rules-reference/$short"
        if [ -f "$ref" ] && ! cmp -s "$TARGET_PROJECT/$r" "$ref"; then LEAN_CUSTOMIZED+=("$r"); fi
    done
fi

# claude-mem stub CLAUDE.md (nested, content-marked), excluding root + vcs/deps/backups
STUBS=()
while IFS= read -r file; do
    rel="${file#"$TARGET_PROJECT"/}"
    [ "$rel" = "CLAUDE.md" ] && continue
    case "$rel" in .git/*|*/.git/*|node_modules/*|*/node_modules/*|.sd003-backup*|*/.sd003-backup*|.sd003-upgrade-backup*|*/.sd003-upgrade-backup*) continue ;; esac
    up_is_kept_move "$rel" && continue
    if grep -q '<claude-mem-context>' "$file" 2>/dev/null; then STUBS+=("$rel"); fi
done < <(find "$TARGET_PROJECT" -type f -name "CLAUDE.md" 2>/dev/null)

VER="(unknown)"
[ -f "$TARGET_PROJECT/CLAUDE.md" ] && VER=$(grep -oE 'SD003 v[0-9.]+' "$TARGET_PROJECT/CLAUDE.md" 2>/dev/null | head -1 || echo "(unknown)")

echo "[Detect] Current version marker: $VER"
echo ""
echo "Will REMOVE (archived to backup first):"
if [ ${#DEL_DIRS[@]} -eq 0 ] && [ ${#DEL_FILES[@]} -eq 0 ] && [ ${#STUBS[@]} -eq 0 ] && [ ${#DEL_OVERENG[@]} -eq 0 ]; then
    echo "  (none — no deprecated artifacts found)"
else
    for d in "${DEL_DIRS[@]}"; do echo "  [dir]  $d"; done
    for f in "${DEL_FILES[@]}"; do echo "  [file] $f"; done
    for s in "${STUBS[@]}"; do echo "  [stub] $s"; done
    for o in "${DEL_OVERENG[@]}"; do echo "  [oeng] $o"; done
fi
for h in "${RETIRED_HOOKS_BLOCKED[@]}"; do
    echo "  [hook] $h left in place: the kept .claude/settings.json still registers it. Remove that registration, then re-run."
done
echo ""
echo "[Lean migration] mode=$LEAN_MODE - legacy always-loaded rules (moved to docs/rules-reference/ in SD003 2026-07-26):"
if [ "$LEAN_MODE" = "off" ]; then
    echo "  (skipped by .sd003-profile: lean-migration = off)"
elif [ ${#LEAN_MIGRATE[@]} -eq 0 ] && [ ${#LEAN_KEPT[@]} -eq 0 ]; then
    echo "  (none present - already migrated or never deployed)"
else
    for m in "${LEAN_MIGRATE[@]}"; do
        flagged=false
        for c in "${LEAN_CUSTOMIZED[@]}"; do [ "$c" = "$m" ] && flagged=true; done
        if [ "$flagged" = true ]; then
            echo "  [lean] $m  <- LOCAL EDITS (differs from reference copy; preserved in backup)"
        else
            echo "  [lean] $m"
        fi
    done
    for k in "${LEAN_KEPT[@]}"; do echo "  [keep] $k (protected via .sd003-keep / keep-always-loaded - left in place)"; done
    if [ "$LEAN_MODE" = "additive" ] && [ ${#LEAN_MIGRATE[@]} -gt 0 ]; then
        echo "  mode=additive: files are LEFT IN PLACE (still always-loaded). Set 'lean-migration = standard' in .sd003-profile to archive-move."
    elif [ ${#LEAN_MIGRATE[@]} -gt 0 ]; then
        echo "  mode=standard: these will be archive-moved to the upgrade backup (reversible)."
    fi
fi
echo ""
echo "Will DEPLOY latest framework via deploy.sh (overwrites framework, preserves data)."
echo "PROTECTED (never deleted): src/, tests/, .sd/specs/, .sd/ai-coordination/, .sessions history, materials/, .clasp.json, .git/, node_modules/, dist/, .env*, .agents/skills/ (shared Codex/agy path)"
echo ""

if [ "$EXECUTE" != true ]; then
    # Delegate to deploy.sh --dry-run so the human sees EXACTLY which framework files
    # would be overwritten (incl. local customizations) and which .sd003-keep preserves.
    echo ""
    echo "[Deploy dry-run] Scanning framework files deploy would write ..."
    bash "$DEPLOY_SH" "$TARGET_PROJECT" --dry-run
    echo ""
    echo "[DRY-RUN] No changes made. Re-run with --execute to apply."
    echo "Tip: to preserve bespoke framework files, list them in '$TARGET_PROJECT/.sd003-keep' BEFORE --execute."
    exit 0
fi

# Phase 3: backup (archive-then-remove)
BACKUP_DIR="$TARGET_PROJECT/.sd003-upgrade-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
echo "[Backup] $BACKUP_DIR"

move_to_backup() {
    local rel="$1"
    if up_is_kept_move "$rel"; then echo "  KEEP: $rel (protected archive move)"; return 0; fi
    local src="$TARGET_PROJECT/$rel"
    [ ! -e "$src" ] && return
    local dest="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$src" "$dest"
    echo "  archived+removed: $rel"
}

for d in "${DEL_DIRS[@]}"; do move_to_backup "$d"; done
for f in "${DEL_FILES[@]}"; do move_to_backup "$f"; done
for s in "${STUBS[@]}"; do move_to_backup "$s"; done
for o in "${DEL_OVERENG[@]}"; do move_to_backup "$o"; done

# Lean migration: archive-move legacy always-loaded rules (standard mode only)
if [ "$LEAN_MODE" = "standard" ] && [ ${#LEAN_MIGRATE[@]} -gt 0 ]; then
    echo "  [Lean migration] archiving legacy always-loaded rules ..."
    for m in "${LEAN_MIGRATE[@]}"; do move_to_backup "$m"; done
fi

# Remove .antigravity if now empty
if ! up_is_kept_move ".antigravity" && [ -d "$TARGET_PROJECT/.antigravity" ] && [ -z "$(ls -A "$TARGET_PROJECT/.antigravity" 2>/dev/null)" ]; then
    rmdir "$TARGET_PROJECT/.antigravity"
    echo "  removed empty .antigravity/"
fi

# Phase 4: deploy
echo ""
echo "[Deploy] Running deploy.sh ..."
# NOTE: deploy.sh (bash) only parses --dry-run; it has no --include-optional
# support (unlike deploy.ps1's -IncludeOptional). Passing --include-optional
# here used to be silently ignored by deploy.sh, and on failure this block
# would blindly re-run an IDENTICAL deploy.sh invocation, hiding the real
# failure behind what looked like a distinct "fallback" attempt. Run once,
# and warn if optional-skills inclusion was requested but isn't honored.
if [ "$INCLUDE_OPTIONAL" = true ]; then
    echo "[WARN] --include-optional is not supported by deploy.sh (bash) - only deploy.ps1 implements -IncludeOptional. Running standard deploy."
fi
DEPLOY_EXIT=0
bash "$DEPLOY_SH" "$TARGET_PROJECT" || DEPLOY_EXIT=$?

# Phase 4b: prune accumulated backup folders (ps1 twin: upgrade.ps1 "[Prune]").
# This phase existed ONLY in upgrade.ps1 until 2026-09-07 - the bash twin let
# .sd003-backup-*, .sd003-upgrade-backup- and legacy .sd002-backup-* directories
# pile up forever (8+ observed in cf001). Stale ones are MOVED to
# <project>/.sd003-archive/<YYYYMMDD>/, never deleted.
# Destination is intentionally OUTSIDE .sd/ - .sd/ is git-tracked and gets copied
# into every future backup, so archiving inside it caused nested bloat and pulled
# old backups into git commits.
if [ "$DEPLOY_EXIT" -ne 0 ]; then
    # Fail fast, as this script always has under `set -e`. The prune is skipped so a
    # failed/unconfirmed deploy never causes backups to be pruned (same rule as the ps1 twin).
    echo ""
    echo "[Prune] [SKIP] deploy.sh exited nonzero ($DEPLOY_EXIT) - skipping prune so existing backups stay intact."
    exit "$DEPLOY_EXIT"
fi

echo ""
echo "[Prune] Checking for accumulated backup folders ..."
ARCHIVE_DIR="$TARGET_PROJECT/.sd003-archive/$(date +%Y%m%d)"
PRUNED=false
PRUNE_FAIL_COUNT=0
PRUNE_FAIL_LIST=""
for pattern in ".sd003-backup-" ".sd003-upgrade-backup-" ".sd002-backup-"; do
    # Sort by the yyyyMMdd_HHmmss timestamp embedded in the DIRECTORY NAME, not by
    # mtime: restoring a single file out of an old backup bumps that directory's
    # mtime and would make an mtime sort misidentify the real newest backup.
    found=()
    while IFS= read -r line; do
        [ -n "$line" ] && found+=("${line#* }")
    done < <(
        for path in "$TARGET_PROJECT/${pattern}"*; do
            [ -d "$path" ] || continue
            name=$(basename "$path")
            key=$(printf '%s' "$name" | grep -oE '[0-9]{8}_[0-9]{6}$' || true)
            [ -n "$key" ] || key="00000000_000000"
            printf '%s %s
' "$key" "$name"
        done | sort -r
    )
    if [ "${#found[@]}" -ge 2 ]; then
        PRUNED=true
        echo "  [${pattern}*] ${#found[@]} found. Keeping newest (by embedded timestamp): ${found[0]}"
        for old in "${found[@]:1}"; do
            dest="$ARCHIVE_DIR/$old"
            [ -e "$dest" ] && dest="$ARCHIVE_DIR/${old}_$(date +%H%M%S)"
            # Create the archive dir lazily so a fully failed prune leaves no empty dir,
            # and report a failed move loudly. The ps1 twin used to swallow this: on
            # 2026-09-05 in er001 a locked file made every move fail, the script still
            # reported success, and the only trace was an empty .sd003-archive/<date>/.
            if mkdir -p "$ARCHIVE_DIR" && mv "$TARGET_PROJECT/$old" "$dest"; then
                echo "    archived (not deleted): $old -> $dest"
            else
                PRUNE_FAIL_COUNT=$((PRUNE_FAIL_COUNT + 1))
                PRUNE_FAIL_LIST="${PRUNE_FAIL_LIST}    - ${old}
"
                echo "    [WARN] archive FAILED (left in place): $old"
            fi
        done
    fi
done
if [ "$PRUNED" != true ]; then
    echo "  (none - fewer than 2 backups per pattern, nothing to prune)"
fi
if [ "$PRUNE_FAIL_COUNT" -gt 0 ]; then
    echo ""
    echo "  [WARN] $PRUNE_FAIL_COUNT backup folder(s) could not be archived and are still at project root:"
    printf '%s' "$PRUNE_FAIL_LIST"
    echo "  Nothing was lost. Close other CLI sessions/editors and re-run, or move them by hand."
fi

# Phase 5: verify
echo ""
echo "=== Upgrade Verification ==="
OK=true
if [ -d "$TARGET_PROJECT/.agents/skills" ]; then
    n=$(find "$TARGET_PROJECT/.agents/skills" -maxdepth 1 -type d | wc -l | tr -d ' ')
    echo "  [PASS] .agents/skills present ($((n-1)) skills)"
else
    echo "  [FAIL] .agents/skills missing"; OK=false
fi
for d in "${DEPRECATED_DIRS[@]}"; do
    [ -e "$TARGET_PROJECT/$d" ] && echo "  [WARN] deprecated still present: $d"
done
echo ""
if [ "$OK" = true ]; then
    echo "Result: UPGRADE COMPLETE. Deprecated-artifact backup: $BACKUP_DIR"
    echo ""
    echo "IMPORTANT: review the deploy report above for 'OVERWROTE local divergence' warnings."
    echo "  Those framework files had LOCAL edits that were overwritten (deploy backup: .sd003-backup-*)."
    echo "  If any were intentional, restore them and add to '$TARGET_PROJECT/.sd003-keep'."
else
    echo "Result: issues found - review above. Backup: $BACKUP_DIR"
fi
echo ""
echo "Next: cd $TARGET_PROJECT && npm install; restart agy and run /skills to confirm commands."
