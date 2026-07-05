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

# Deprecated dirs/files. `.agent` (singular) is deprecated; `.agents` (plural) is
# the CURRENT agy skills path and is NEVER listed here.
DEPRECATED_DIRS=(".gemini" ".cursor" ".windsurf" ".qwen" ".agent" ".kiro" ".codex/prompts" ".antigravity/commands" ".antigravity/skills")
DEPRECATED_FILES=("GEMINI.md" "gemini.md" "scripts/sync-gemini-features.js" "scripts/migrate-kiro-to-sd.ps1" ".antigravity/rules.md")

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
if [ ${#DEL_DIRS[@]} -eq 0 ] && [ ${#DEL_FILES[@]} -eq 0 ] && [ ${#STUBS[@]} -eq 0 ]; then
    echo "  (none — no deprecated artifacts found)"
else
    for d in "${DEL_DIRS[@]}"; do echo "  [dir]  $d"; done
    for f in "${DEL_FILES[@]}"; do echo "  [file] $f"; done
    for s in "${STUBS[@]}"; do echo "  [stub] $s"; done
fi
echo ""
echo "Will DEPLOY latest framework via deploy.sh (overwrites framework, preserves data)."
echo "PROTECTED (never deleted): src/, tests/, .sd/specs/, .sd/ai-coordination/, .sessions history, materials/, .clasp.json, .git/, node_modules/, dist/, .env*, .agents/skills/ (current agy path)"
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
