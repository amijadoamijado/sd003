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
DEPRECATED_DIRS=(".gemini" ".cursor" ".windsurf" ".qwen" ".agent" ".kiro" ".codex/prompts" ".codex/skills" ".antigravity/commands" ".antigravity/skills")
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

# .sd003-keep (same semantics as deploy.sh, incl. BOM strip) - lean migration ONLY;
# pre-existing deprecated/overeng removal behavior intentionally unchanged.
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

# .sd003-profile: per-project tuning (plain key=value, '#' comments)
#   lean-migration = standard | additive | off      (default: standard)
#   keep-always-loaded = <relpath under .claude/rules/>   (repeatable)
LEAN_MODE="standard"
KEEP_ALWAYS=()
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
        esac
    done < "$TARGET_PROJECT/.sd003-profile"
    echo "[.sd003-profile] lean-migration=$LEAN_MODE, keep-always-loaded: ${#KEEP_ALWAYS[@]} entries"
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
DEL_DIRS=(); for d in "${DEPRECATED_DIRS[@]}"; do [ -e "$TARGET_PROJECT/$d" ] && DEL_DIRS+=("$d"); done
DEL_FILES=(); for f in "${DEPRECATED_FILES[@]}"; do [ -e "$TARGET_PROJECT/$f" ] && DEL_FILES+=("$f"); done

# Expand over-engineering artifacts to concrete relative paths across all roots; keep present ones.
OVERENG_ALL=()
for c in "${OVERENG_CMD_NAMES[@]}"; do
    OVERENG_ALL+=(".claude/commands/$c.md" ".sd/commands/specs/$c.md" ".agents/skills/$c" ".grok/skills/$c")
done
for s in "${OVERENG_SKILL_NAMES[@]}"; do
    OVERENG_ALL+=(".claude/skills/$s" ".agents/skills/$s" ".grok/skills/$s")
done
OVERENG_ALL+=("${OVERENG_EXTRA[@]}")
DEL_OVERENG=(); for p in "${OVERENG_ALL[@]}"; do [ -e "$TARGET_PROJECT/$p" ] && DEL_OVERENG+=("$p"); done

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
if [ -d "$TARGET_PROJECT/.antigravity" ] && [ -z "$(ls -A "$TARGET_PROJECT/.antigravity" 2>/dev/null)" ]; then
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
bash "$DEPLOY_SH" "$TARGET_PROJECT"

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
