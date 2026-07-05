#!/bin/bash
# SD003 Framework Deployment Script v3.2.0 (Bash)
# Usage: ./deploy.sh <target-project-path>

set -e

# Configuration
SD003_VERSION="3.2.0"
FRAMEWORK_VERSION="2.14.0"
SOURCE_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
TARGET_PROJECT="${1:?Error: Target project path required}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# --dry-run reports what would be overwritten (incl. local customizations) without changing anything
DRY_RUN=false
for a in "$@"; do case "$a" in --dry-run) DRY_RUN=true ;; esac; done

echo "=== SD003 Framework Deployment v${SD003_VERSION} ==="
echo "Framework: v${FRAMEWORK_VERSION}"
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_PROJECT"
echo ""

# ============================================================
# Phase 1: Validate
# ============================================================
if [ ! -d "$TARGET_PROJECT" ]; then
    echo "Error: Target project '$TARGET_PROJECT' not found"
    exit 1
fi
echo "[Phase 1/7] Target validated"

# ============================================================
# Opt-out manifest (.sd003-keep): framework files this project has
# INTENTIONALLY customized. deploy must NOT overwrite them.
# One relative path per line; supports exact paths, directory prefixes, and globs.
# '#' starts a comment. No file => every guard is a no-op (zero behavior change).
# ============================================================
KEEP_PATTERNS=()
KEEP_FILE="$TARGET_PROJECT/.sd003-keep"
if [ -f "$KEEP_FILE" ]; then
    first_line=true
    while IFS= read -r line; do
        if [ "$first_line" = true ]; then
            # Strip a leading UTF-8 BOM (EF BB BF) if the file was saved with one.
            # Without this, a first line "CLAUDE.md" registers as BOM+"CLAUDE.md"
            # (invisible extra bytes) and never matches -> protection silently fails.
            line="${line#$'\xef\xbb\xbf'}"
            first_line=false
        fi
        line="$(echo "$line" | sed 's/[[:space:]]*$//;s/^[[:space:]]*//')"
        [ -z "$line" ] && continue
        case "$line" in \#*) continue ;; esac
        KEEP_PATTERNS+=("${line%/}")
    done < "$KEEP_FILE"
    [ ${#KEEP_PATTERNS[@]} -gt 0 ] && echo "[.sd003-keep] ${#KEEP_PATTERNS[@]} protected pattern(s) loaded - these framework files are preserved"
fi

is_kept() {
    # Case-insensitive match (aligns with deploy.ps1's `-like`, and with Windows'
    # case-insensitive filesystem where this script mostly runs).
    local rel pat rel_lc pat_lc
    rel="${1#/}"
    rel_lc="$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')"
    for pat in "${KEEP_PATTERNS[@]}"; do
        pat_lc="$(printf '%s' "$pat" | tr '[:upper:]' '[:lower:]')"
        [ "$rel_lc" = "$pat_lc" ] && return 0
        case "$rel_lc" in "$pat_lc"/*) return 0 ;; esac
        case "$pat_lc" in *[\*\?]*) case "$rel_lc" in $pat_lc) return 0 ;; esac ;; esac
    done
    return 1
}

KEPT_LOG="$(mktemp)"; DIVERGED_LOG="$(mktemp)"

# ============================================================
# DRY-RUN: report what a real deploy WOULD overwrite, then exit (no changes).
# ============================================================
deploy_dry_run() {
    echo ""
    echo "=== DRY-RUN: what a real deploy would write (no changes made) ==="
    echo ""
    local diverged=0 kept=0 newc=0 same=0 d f sf projrel tgt
    local DIV=() KEP=()
    local gh gh_name gh_rel gh_tgt
    local scan_dirs=(".claude/commands" ".claude/rules" ".claude/skills" ".claude/hooks" ".agents/skills" ".codex" ".grok" ".sd/settings" ".sd/design" ".sd/ralph" ".sd/steering" ".handoff" "docs/troubleshooting")
    for d in "${scan_dirs[@]}"; do
        [ -d "$SOURCE_DIR/$d" ] || continue
        while IFS= read -r f; do
            projrel="${f#"$SOURCE_DIR"/}"
            if is_kept "$projrel"; then KEP+=("$projrel"); kept=$((kept+1)); continue; fi
            tgt="$TARGET_PROJECT/$projrel"
            if [ ! -f "$tgt" ]; then newc=$((newc+1)); continue; fi
            if ! cmp -s "$f" "$tgt"; then DIV+=("$projrel"); diverged=$((diverged+1)); else same=$((same+1)); fi
        done < <(find "$SOURCE_DIR/$d" -type f)
    done
    local scan_files=("antigravity.md" "AGENTS.md" "grok.md" ".claude/settings.json" "docs/quality-gates.md" "scripts/validate-test-data.ps1" "scripts/validate-test-data.sh" "scripts/sync-cli-commands.py" "scripts/verify-deployment.mjs" "tests/gas-fakes/setup.ts")
    for sf in "${scan_files[@]}"; do
        if is_kept "$sf"; then KEP+=("$sf"); kept=$((kept+1)); continue; fi
        [ -f "$SOURCE_DIR/$sf" ] || continue
        if [ ! -f "$TARGET_PROJECT/$sf" ]; then newc=$((newc+1)); continue; fi
        if ! cmp -s "$SOURCE_DIR/$sf" "$TARGET_PROJECT/$sf"; then DIV+=("$sf"); diverged=$((diverged+1)); else same=$((same+1)); fi
    done
    if is_kept "CLAUDE.md"; then KEP+=("CLAUDE.md"); kept=$((kept+1)); fi

    # Git hooks: source path (templates/git-hooks) differs from target path
    # (.git/hooks), so this can't use the generic scan_dirs/scan_files loops above.
    local gh_src_dir="$SOURCE_DIR/.claude/skills/sd-deploy/templates/git-hooks"
    if [ -d "$gh_src_dir" ]; then
        for gh in "$gh_src_dir"/*; do
            [ -f "$gh" ] || continue
            gh_name="$(basename "$gh")"
            gh_rel=".git/hooks/$gh_name"
            if is_kept "$gh_rel"; then KEP+=("$gh_rel"); kept=$((kept+1)); continue; fi
            gh_tgt="$TARGET_PROJECT/.git/hooks/$gh_name"
            if [ ! -f "$gh_tgt" ]; then newc=$((newc+1)); continue; fi
            if ! cmp -s "$gh" "$gh_tgt"; then DIV+=("$gh_rel"); diverged=$((diverged+1)); else same=$((same+1)); fi
        done
    fi

    if [ ${#DIV[@]} -gt 0 ]; then
        echo "WILL OVERWRITE - LOCAL CUSTOMIZATION WILL BE LOST (${#DIV[@]}):"
        printf '%s\n' "${DIV[@]}" | sort -u | sed 's/^/  ! /'
        echo ""
    fi
    if ! is_kept "CLAUDE.md"; then
        echo "WILL OVERWRITE - regenerated from template:"
        echo "  ~ CLAUDE.md  (add 'CLAUDE.md' to .sd003-keep to preserve a bespoke version)"
        echo ""
    fi
    if [ ${#KEP[@]} -gt 0 ]; then
        echo "KEPT via .sd003-keep (${#KEP[@]}) - preserved, not overwritten:"
        printf '%s\n' "${KEP[@]}" | sort -u | sed 's/^/  = /'
        echo ""
    fi
    echo "Summary: $diverged diverged, $kept kept, $newc new, $same unchanged"
    if [ $diverged -gt 0 ]; then
        echo ""
        echo "WARNING: $diverged file(s) with local changes will be overwritten on a real run."
        echo "         Add them to <target>/.sd003-keep to KEEP them."
    fi
}

if [ "$DRY_RUN" = true ]; then
    deploy_dry_run
    echo ""
    echo "[DRY-RUN] No changes made."
    rm -f "$KEPT_LOG" "$DIVERGED_LOG"
    exit 0
fi

# ============================================================
# Phase 2: Backup
# ============================================================
BACKUP_DIR="$TARGET_PROJECT/.sd003-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

for f in CLAUDE.md AGENTS.md antigravity.md grok.md; do
    [ -f "$TARGET_PROJECT/$f" ] && cp "$TARGET_PROJECT/$f" "$BACKUP_DIR/" 2>/dev/null || true
done

for d in .claude .codex .agents .grok .sd; do
    [ -d "$TARGET_PROJECT/$d" ] && cp -r "$TARGET_PROJECT/$d" "$BACKUP_DIR/" 2>/dev/null || true
done
echo "[Phase 2/7] Backup created: $BACKUP_DIR"

# ============================================================
# Phase 3: Create directory structure
# ============================================================
DIRS=(
    ".claude/commands/sd"
    ".claude/rules"
    ".claude/skills"
    ".claude/hooks"
    ".codex/skills"
    ".agents/skills"
    ".grok/skills"
    ".sd/specs"
    ".sd/steering"
    ".sessions"
    ".sd/settings"
    ".sd/ids"
    ".sd/traceability"
    ".sd/ai-coordination/workflow/templates"
    ".sd/ai-coordination/workflow/spec"
    ".sd/ai-coordination/workflow/review"
    ".sd/ai-coordination/workflow/log"
    ".sd/ai-coordination/handoff"
    ".handoff"
    ".sd/ralph"
    ".sd/refactor"
    "docs/troubleshooting/bug-reports"
    "materials/csv"
    "materials/excel"
    "materials/html"
    "materials/pdf"
    "materials/images"
    "materials/text"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$TARGET_PROJECT/$dir"
done
echo "[Phase 3/7] Directory structure created"

# ============================================================
# Phase 4: Dynamic copy (directory-based)
# ============================================================

# Counters
declare -A COPY_STATS

# Helper: copy directory tree (recursive)
copy_dir_tree() {
    local rel_path="$1"
    local label="$2"
    local filter="${3:-*}"
    local src="$SOURCE_DIR/$rel_path"
    local dst="$TARGET_PROJECT/$rel_path"
    local count=0

    if [ ! -d "$src" ]; then
        echo "  WARN: Source not found: $rel_path"
        COPY_STATS[$label]=0
        return
    fi

    # Copy entire tree preserving structure (skip .sd003-keep protected files)
    cd "$src"
    find . -type f -name "$filter" | while read -r file; do
        rel_in="${file#./}"
        projrel="$rel_path/$rel_in"
        if is_kept "$projrel"; then echo "$projrel" >> "$KEPT_LOG"; continue; fi
        dest_dir="$dst/$(dirname "$file")"
        destf="$dst/$rel_in"
        if [ -f "$destf" ] && ! cmp -s "$file" "$destf"; then echo "$projrel" >> "$DIVERGED_LOG"; fi
        mkdir -p "$dest_dir"
        cp "$file" "$dest_dir/"
    done
    cd "$SOURCE_DIR"

    count=$(find "$src" -type f -name "$filter" | wc -l | tr -d ' ')
    COPY_STATS[$label]=$count
}

# Helper: copy flat directory (files with extension)
copy_flat_dir() {
    local rel_path="$1"
    local label="$2"
    local ext="${3:-.md}"
    local src="$SOURCE_DIR/$rel_path"
    local dst="$TARGET_PROJECT/$rel_path"
    local count=0

    if [ ! -d "$src" ]; then
        echo "  WARN: Source not found: $rel_path"
        COPY_STATS[$label]=0
        return
    fi

    mkdir -p "$dst"
    count=0
    for f in "$src"/*"$ext"; do
        [ -f "$f" ] || continue
        bn="$(basename "$f")"
        projrel="$rel_path/$bn"
        if is_kept "$projrel"; then echo "$projrel" >> "$KEPT_LOG"; continue; fi
        if [ -f "$dst/$bn" ] && ! cmp -s "$f" "$dst/$bn"; then echo "$projrel" >> "$DIVERGED_LOG"; fi
        cp "$f" "$dst/"
        count=$((count+1))
    done
    COPY_STATS[$label]=$count
}

# 4-1: .claude/commands/*.md
copy_flat_dir ".claude/commands" "Commands" ".md"

# 4-2: .claude/commands/sd/*.md
copy_flat_dir ".claude/commands/sd" "Commands/sd" ".md"

# 4-3: .claude/rules/ (tree)
copy_dir_tree ".claude/rules" "Rules" "*.md"

# 4-4: .claude/skills/ (tree)
copy_dir_tree ".claude/skills" "Skills" "*"

# 4-5: .claude/hooks/ (tree)
copy_dir_tree ".claude/hooks" "Hooks" "*"

# 4-6: .agents/skills/ (tree) - Antigravity CLI (agy) reads slash commands here as SKILL.md
copy_dir_tree ".agents/skills" "Agents Skills (agy)" "*"

# 4-7: .codex/ (tree)
copy_dir_tree ".codex" "Codex" "*"

# 4-8: .grok/ (tree) - Grok CLI reads skills here as SKILL.md + GROK_SPEC.md
copy_dir_tree ".grok" "Grok" "*"

# 4-9: .sd/settings/ (tree)
copy_dir_tree ".sd/settings" "SD Settings" "*"

# 4-9b: .sd/design/ (tree) - design tokens (already scanned by --dry-run; was
# missing from the real copy path, so a real deploy silently skipped it while
# dry-run reported it as new/unchanged - parity fix with deploy.ps1's 4-11a)
copy_dir_tree ".sd/design" "Design Tokens" "*"

# 4-10: .sessions/session-template.md
if [ -f "$SOURCE_DIR/.sessions/session-template.md" ]; then
    cp "$SOURCE_DIR/.sessions/session-template.md" "$TARGET_PROJECT/.sessions/"
    COPY_STATS["Session Template"]=1
else
    echo "  WARN: session-template.md not found"
    COPY_STATS["Session Template"]=0
fi

# 4-11: .sd/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}
WF_SRC="$SOURCE_DIR/.sd/ai-coordination/workflow"
WF_DST="$TARGET_PROJECT/.sd/ai-coordination/workflow"
wf_count=0

for f in README.md CODEX_GUIDE.md; do
    if [ -f "$WF_SRC/$f" ]; then
        cp "$WF_SRC/$f" "$WF_DST/"
        wf_count=$((wf_count + 1))
    fi
done

if [ -d "$WF_SRC/templates" ]; then
    mkdir -p "$WF_DST/templates"
    for f in "$WF_SRC/templates"/*; do
        [ -f "$f" ] && cp "$f" "$WF_DST/templates/" && wf_count=$((wf_count + 1))
    done
fi
COPY_STATS["AI Coordination"]=$wf_count

# 4-11: docs/troubleshooting/
copy_dir_tree "docs/troubleshooting" "Docs/Troubleshooting" "*"

# 4-12: docs/quality-gates.md (overwrite unless protected by .sd003-keep)
if is_kept "docs/quality-gates.md"; then
    echo "  KEEP: docs/quality-gates.md preserved via .sd003-keep"
    echo "docs/quality-gates.md" >> "$KEPT_LOG"
    COPY_STATS["Docs/QualityGates"]=0
elif [ -f "$SOURCE_DIR/docs/quality-gates.md" ]; then
    mkdir -p "$TARGET_PROJECT/docs"
    if [ -f "$TARGET_PROJECT/docs/quality-gates.md" ] && ! cmp -s "$SOURCE_DIR/docs/quality-gates.md" "$TARGET_PROJECT/docs/quality-gates.md"; then echo "docs/quality-gates.md" >> "$DIVERGED_LOG"; fi
    cp "$SOURCE_DIR/docs/quality-gates.md" "$TARGET_PROJECT/docs/"
    COPY_STATS["Docs/QualityGates"]=1
else
    COPY_STATS["Docs/QualityGates"]=0
fi

# 4-13: .handoff/ (tree)
copy_dir_tree ".handoff" "Handoff" "*"



# 4-15a: scripts/validate-test-data.ps1 (single file - overwrite unless protected by .sd003-keep)
if is_kept "scripts/validate-test-data.ps1"; then
    echo "  KEEP: scripts/validate-test-data.ps1 preserved via .sd003-keep"
    echo "scripts/validate-test-data.ps1" >> "$KEPT_LOG"
    COPY_STATS["Validate Test Data (ps1)"]=0
elif [ -f "$SOURCE_DIR/scripts/validate-test-data.ps1" ]; then
    mkdir -p "$TARGET_PROJECT/scripts"
    if [ -f "$TARGET_PROJECT/scripts/validate-test-data.ps1" ] && ! cmp -s "$SOURCE_DIR/scripts/validate-test-data.ps1" "$TARGET_PROJECT/scripts/validate-test-data.ps1"; then echo "scripts/validate-test-data.ps1" >> "$DIVERGED_LOG"; fi
    cp "$SOURCE_DIR/scripts/validate-test-data.ps1" "$TARGET_PROJECT/scripts/"
    COPY_STATS["Validate Test Data (ps1)"]=1
else
    COPY_STATS["Validate Test Data (ps1)"]=0
fi

# 4-15b: scripts/validate-test-data.sh (single file - overwrite unless protected by .sd003-keep)
if is_kept "scripts/validate-test-data.sh"; then
    echo "  KEEP: scripts/validate-test-data.sh preserved via .sd003-keep"
    echo "scripts/validate-test-data.sh" >> "$KEPT_LOG"
    COPY_STATS["Validate Test Data (sh)"]=0
elif [ -f "$SOURCE_DIR/scripts/validate-test-data.sh" ]; then
    mkdir -p "$TARGET_PROJECT/scripts"
    if [ -f "$TARGET_PROJECT/scripts/validate-test-data.sh" ] && ! cmp -s "$SOURCE_DIR/scripts/validate-test-data.sh" "$TARGET_PROJECT/scripts/validate-test-data.sh"; then echo "scripts/validate-test-data.sh" >> "$DIVERGED_LOG"; fi
    cp "$SOURCE_DIR/scripts/validate-test-data.sh" "$TARGET_PROJECT/scripts/"
    COPY_STATS["Validate Test Data (sh)"]=1
else
    COPY_STATS["Validate Test Data (sh)"]=0
fi

# 4-15c: scripts/verify-deployment.mjs (single file - deploy content-verification gate - overwrite unless protected by .sd003-keep)
if is_kept "scripts/verify-deployment.mjs"; then
    echo "  KEEP: scripts/verify-deployment.mjs preserved via .sd003-keep"
    echo "scripts/verify-deployment.mjs" >> "$KEPT_LOG"
    COPY_STATS["Verify Deployment (mjs)"]=0
elif [ -f "$SOURCE_DIR/scripts/verify-deployment.mjs" ]; then
    mkdir -p "$TARGET_PROJECT/scripts"
    if [ -f "$TARGET_PROJECT/scripts/verify-deployment.mjs" ] && ! cmp -s "$SOURCE_DIR/scripts/verify-deployment.mjs" "$TARGET_PROJECT/scripts/verify-deployment.mjs"; then echo "scripts/verify-deployment.mjs" >> "$DIVERGED_LOG"; fi
    cp "$SOURCE_DIR/scripts/verify-deployment.mjs" "$TARGET_PROJECT/scripts/"
    COPY_STATS["Verify Deployment (mjs)"]=1
else
    COPY_STATS["Verify Deployment (mjs)"]=0
fi

# 4-16: scripts/sync-cli-commands.py (single file - the agy/codex skill generator - overwrite unless protected by .sd003-keep)
if is_kept "scripts/sync-cli-commands.py"; then
    echo "  KEEP: scripts/sync-cli-commands.py preserved via .sd003-keep"
    echo "scripts/sync-cli-commands.py" >> "$KEPT_LOG"
    COPY_STATS["Sync CLI"]=0
elif [ -f "$SOURCE_DIR/scripts/sync-cli-commands.py" ]; then
    mkdir -p "$TARGET_PROJECT/scripts"
    if [ -f "$TARGET_PROJECT/scripts/sync-cli-commands.py" ] && ! cmp -s "$SOURCE_DIR/scripts/sync-cli-commands.py" "$TARGET_PROJECT/scripts/sync-cli-commands.py"; then echo "scripts/sync-cli-commands.py" >> "$DIVERGED_LOG"; fi
    cp "$SOURCE_DIR/scripts/sync-cli-commands.py" "$TARGET_PROJECT/scripts/"
    COPY_STATS["Sync CLI"]=1
    # Regenerate agy/codex/grok skills in TARGET (copy alone leaves them stale). Guarded.
    if command -v python >/dev/null 2>&1; then
        ( cd "$TARGET_PROJECT" && python scripts/sync-cli-commands.py >/dev/null 2>&1 ) \
            && echo "  Regenerated agy/codex/grok skills (sync-cli-commands.py)" \
            || echo "  WARN: post-copy sync failed; run 'python scripts/sync-cli-commands.py' in target"
    else
        echo "  NOTE: python not found. Run 'python scripts/sync-cli-commands.py' in target to (re)generate skills."
    fi
else
    COPY_STATS["Sync CLI"]=0
fi

# 4-16: AGENTS.md (single file - overwrite unless protected by .sd003-keep)
if is_kept "AGENTS.md"; then
    echo "  KEEP: AGENTS.md preserved via .sd003-keep"
    echo "AGENTS.md" >> "$KEPT_LOG"
    COPY_STATS["AGENTS.md"]=0
elif [ -f "$SOURCE_DIR/AGENTS.md" ]; then
    if [ -f "$TARGET_PROJECT/AGENTS.md" ] && ! cmp -s "$SOURCE_DIR/AGENTS.md" "$TARGET_PROJECT/AGENTS.md"; then echo "AGENTS.md" >> "$DIVERGED_LOG"; fi
    cp "$SOURCE_DIR/AGENTS.md" "$TARGET_PROJECT/"
    COPY_STATS["AGENTS.md"]=1
else
    COPY_STATS["AGENTS.md"]=0
fi

# 4-17: .sd/ralph/ (tree)
copy_dir_tree ".sd/ralph" "Ralph" "*"

# 4-18: .sd/steering/ (tree)
copy_dir_tree ".sd/steering" "Steering" "*"

# 4-19: .sd/refactor/config.json (single file)
if [ -f "$SOURCE_DIR/.sd/refactor/config.json" ]; then
    mkdir -p "$TARGET_PROJECT/.sd/refactor"
    cp "$SOURCE_DIR/.sd/refactor/config.json" "$TARGET_PROJECT/.sd/refactor/"
    COPY_STATS["Refactor Config"]=1
else
    COPY_STATS["Refactor Config"]=0
fi

# 4-20: tests/gas-fakes/setup.ts (single file - overwrite unless protected by .sd003-keep)
GAS_FAKES_SRC="$SOURCE_DIR/tests/gas-fakes/setup.ts"
GAS_FAKES_DST="$TARGET_PROJECT/tests/gas-fakes/setup.ts"
if is_kept "tests/gas-fakes/setup.ts"; then
    echo "  KEEP: tests/gas-fakes/setup.ts preserved via .sd003-keep"
    echo "tests/gas-fakes/setup.ts" >> "$KEPT_LOG"
    COPY_STATS["Gas Fakes Setup"]=0
elif [ -f "$GAS_FAKES_SRC" ]; then
    mkdir -p "$TARGET_PROJECT/tests/gas-fakes"
    if [ -f "$GAS_FAKES_DST" ] && ! cmp -s "$GAS_FAKES_SRC" "$GAS_FAKES_DST"; then echo "tests/gas-fakes/setup.ts" >> "$DIVERGED_LOG"; fi
    cp "$GAS_FAKES_SRC" "$GAS_FAKES_DST"
    COPY_STATS["Gas Fakes Setup"]=1
else
    echo "  WARN: tests/gas-fakes/setup.ts not found"
    COPY_STATS["Gas Fakes Setup"]=0
fi

# 4-21: .git/hooks/ (from templates/git-hooks/) - overwrite unless protected by
# .sd003-keep. Existing hooks are backed up into BACKUP_DIR before overwrite
# (parity with deploy.ps1's Phase 2 backup, and with is_kept honored - was
# previously undistributed by deploy.sh entirely, an asymmetry vs deploy.ps1).
GIT_HOOKS_SRC="$SOURCE_DIR/.claude/skills/sd-deploy/templates/git-hooks"
GIT_HOOKS_DST="$TARGET_PROJECT/.git/hooks"
hook_count=0
if [ -d "$GIT_HOOKS_SRC" ]; then
    mkdir -p "$GIT_HOOKS_DST"
    for hook in "$GIT_HOOKS_SRC"/*; do
        [ -f "$hook" ] || continue
        hook_name="$(basename "$hook")"
        hook_projrel=".git/hooks/$hook_name"
        hook_target="$GIT_HOOKS_DST/$hook_name"
        if is_kept "$hook_projrel"; then
            echo "  KEEP: $hook_projrel preserved via .sd003-keep"
            echo "$hook_projrel" >> "$KEPT_LOG"
            continue
        fi
        if [ -f "$hook_target" ]; then
            mkdir -p "$BACKUP_DIR/.git/hooks"
            cp "$hook_target" "$BACKUP_DIR/.git/hooks/" 2>/dev/null || true
            if ! cmp -s "$hook" "$hook_target"; then echo "$hook_projrel" >> "$DIVERGED_LOG"; fi
        fi
        cp "$hook" "$hook_target"
        hook_count=$((hook_count + 1))
    done
    echo "  Git Hooks: $hook_count file(s) installed"
else
    echo "  WARN: templates/git-hooks/ not found"
fi
COPY_STATS["Git Hooks"]=$hook_count

echo "[Phase 4/7] Dynamic copy completed"
for key in "${!COPY_STATS[@]}"; do
    echo "  $key: ${COPY_STATS[$key]} files"
done

# ============================================================
# Phase 5: Generate files
# ============================================================
PROJECT_NAME=$(basename "$TARGET_PROJECT")

# 5-1: CLAUDE.md from template (overwrite unless protected by .sd003-keep)
# NOTE: former SKIP-if-SD003 branch removed (parity with deploy.ps1): an old
# SD003-based CLAUDE.md must be upgraded, not preserved. Bespoke versions are
# protected via .sd003-keep (same bug class as the settings.json fix 952ef66).
CLAUDE_TEMPLATE="$SOURCE_DIR/.claude/skills/sd-deploy/templates/CLAUDE.md.template"
if is_kept "CLAUDE.md"; then
    echo "  KEEP: CLAUDE.md preserved via .sd003-keep (bespoke version kept)"
    echo "CLAUDE.md" >> "$KEPT_LOG"
elif [ -f "$CLAUDE_TEMPLATE" ]; then
    # NOTE: the template stamps "SD003 v3.2.0" (not "v2.3.0" - that token never
    # existed in the template, so this substitution was previously dead code
    # and every deployed CLAUDE.md kept the hardcoded v3.2.0 forever). Match the
    # real token "SD003 v<version>" so the stamp actually becomes $FRAMEWORK_VERSION.
    sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s/{{DATE}}/$DATE/g" \
        -e "s/SD003 v[0-9][0-9.]*/SD003 v$FRAMEWORK_VERSION/g" \
        "$CLAUDE_TEMPLATE" > "$TARGET_PROJECT/CLAUDE.md"
else
    echo "  WARN: CLAUDE.md.template not found, skipping"
fi

# 5-2: antigravity.md (agy root config - overwrite unless protected by .sd003-keep)
if is_kept "antigravity.md"; then
    echo "  KEEP: antigravity.md preserved via .sd003-keep"
    echo "antigravity.md" >> "$KEPT_LOG"
elif [ -f "$SOURCE_DIR/antigravity.md" ]; then
    if [ -f "$TARGET_PROJECT/antigravity.md" ] && ! cmp -s "$SOURCE_DIR/antigravity.md" "$TARGET_PROJECT/antigravity.md"; then echo "antigravity.md" >> "$DIVERGED_LOG"; fi
    cp "$SOURCE_DIR/antigravity.md" "$TARGET_PROJECT/antigravity.md"
    echo "  UPDATE: antigravity.md (latest agy rules applied)"
else
    echo "  WARN: antigravity.md not found in source, skipping"
fi

# 5-2b: grok.md (Grok CLI root config - overwrite unless protected by .sd003-keep)
if is_kept "grok.md"; then
    echo "  KEEP: grok.md preserved via .sd003-keep"
    echo "grok.md" >> "$KEPT_LOG"
elif [ -f "$SOURCE_DIR/grok.md" ]; then
    if [ -f "$TARGET_PROJECT/grok.md" ] && ! cmp -s "$SOURCE_DIR/grok.md" "$TARGET_PROJECT/grok.md"; then echo "grok.md" >> "$DIVERGED_LOG"; fi
    cp "$SOURCE_DIR/grok.md" "$TARGET_PROJECT/grok.md"
    echo "  UPDATE: grok.md (latest Grok rules applied)"
else
    echo "  WARN: grok.md not found in source, skipping"
fi

# 5-3: session-current.md (skip if exists)
if [ -f "$TARGET_PROJECT/.sessions/session-current.md" ]; then
    echo "  SKIP: session-current.md already exists (preserving existing session)"
else
    cat > "$TARGET_PROJECT/.sessions/session-current.md" << EOF
# Session Record

## Session Info
- **Date**: $DATE
- **Project**: $PROJECT_NAME
- **Branch**: main
- **Latest Commit**: (initialized)

## Progress Summary

### Completed
- SD003 Framework v${FRAMEWORK_VERSION} deployed

### In Progress
- (none)

### Next Session Tasks
- P1 (Important): Run /sessionread to verify

### Notes
Initialized with SD003 v${FRAMEWORK_VERSION}.
EOF
fi

# 5-4: TIMELINE.md (skip if exists)
if [ -f "$TARGET_PROJECT/.sessions/TIMELINE.md" ]; then
    echo "  SKIP: TIMELINE.md already exists (preserving existing timeline)"
else
    cat > "$TARGET_PROJECT/.sessions/TIMELINE.md" << EOF
# $PROJECT_NAME - Project Timeline

## Overview
- **Project**: $PROJECT_NAME
- **Created**: $DATE
- **Framework**: SD003 v${FRAMEWORK_VERSION}

---

## Timeline

### $DATE - Project Initialized
- SD003 Framework v${FRAMEWORK_VERSION} deployed
EOF
fi

# 5-5: .claude/settings.json (OS-aware)
OS_TYPE="$(uname -s 2>/dev/null || echo 'Unknown')"
if [[ "$OS_TYPE" == *"MINGW"* ]] || [[ "$OS_TYPE" == *"MSYS"* ]] || [[ "$OS_TYPE" == *"CYGWIN"* ]]; then
    # Windows (Git Bash/MSYS)
    HOOK_CMD='powershell -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR\\.claude\\hooks\\sd003-stop-hook.ps1\"'
    CTX_CMD='powershell -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR\\.claude\\hooks\\context-monitor-hook.ps1\"'
else
    # Linux/Mac
    HOOK_CMD='bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/sd003-stop-hook.sh\"'
    CTX_CMD='bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/context-monitor-hook.sh\"'
fi

# settings.json: OVERWRITE with latest full wiring unless protected by .sd003-keep.
# WAS skip-if-exists, which left a stale/partial settings.json un-upgraded on
# re-deploy/upgrade -> guardrails stayed INACTIVE in already-deployed targets
# (e.g. nm002/at002). deploy.ps1 already overwrites; this aligns deploy.sh with it.
# IMPORTANT: generate the FULL guardrail wiring (PreToolUse/PostToolUse/SessionStart),
# not just the Stop hook. A minimal settings.json leaves copied guardrail hooks INACTIVE
# (block-edit-write-on-sd / enforce-skill-read / enforce-spec-location / etc.).
if is_kept ".claude/settings.json"; then
    echo "  KEEP: .claude/settings.json preserved via .sd003-keep"
    echo ".claude/settings.json" >> "$KEPT_LOG"
else
    SETTINGS_TMP="$(mktemp)"
    cat > "$SETTINGS_TMP" << EOF
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOOK_CMD",
            "timeout": 30
          }
        ]
      },
      {
        "matcher": ".*refactor.*",
        "hooks": [
          {
            "type": "command",
            "command": "$CTX_CMD",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/block-clasp-deploy.sh\"",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/block-sd-destructive.sh\"",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/block-commit-on-test-fail.sh\"",
            "timeout": 120
          },
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/block-write-to-protected-dirs.sh\"",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/workflow-gate.sh\"",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/block-write-to-protected-dirs.sh\"",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/block-edit-write-on-sd.sh\"",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Bash|Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/enforce-skill-read.sh\"",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/enforce-spec-location.sh\"",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/sd-watchdog.sh\"",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/clasp-deploy-tracker.sh\" Edit",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/clasp-deploy-tracker.sh\" Write",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/clasp-deploy-tracker.sh\" Bash",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/deploy-package-reminder.sh\"",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/agent-review.sh\"",
            "timeout": 600
          },
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/workflow-state-tracker.sh\"",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/track-skill-read.sh\"",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/session-skill-suggest.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  },
  "ralph-loop": {
    "description": "SD003 Ralph Loop configuration",
    "midpoint": {
      "hook": "sd003-stop-hook.ps1",
      "max_iterations": 20,
      "completion_promise": "ALL_TESTS_PASS"
    },
    "endgame": {
      "hook": "sd003-stop-hook-endgame.ps1",
      "max_same_error": 2,
      "escalation": "/dialogue-resolution"
    },
    "note": "Windows PowerShell version. Switch hooks manually based on phase."
  },
  "refactoring": {
    "description": "SD003 Refactoring System configuration",
    "context_monitor_hook": "context-monitor-hook.ps1",
    "config_path": ".sd/refactor/config.json",
    "skills": [
      "context-autonomy",
      "session-autosave",
      "rollback-guard"
    ],
    "commands": [
      "refactor-init",
      "refactor-plan",
      "refactor-batch",
      "refactor-rollback",
      "refactor-complete"
    ]
  }
}
EOF
    if [ -f "$TARGET_PROJECT/.claude/settings.json" ] && ! cmp -s "$SETTINGS_TMP" "$TARGET_PROJECT/.claude/settings.json"; then
        echo ".claude/settings.json" >> "$DIVERGED_LOG"
    fi
    mv "$SETTINGS_TMP" "$TARGET_PROJECT/.claude/settings.json"
    echo "  UPDATE: .claude/settings.json (latest guardrail wiring applied)"
fi

# 5-6: .sd/ids/registry.json (skip if exists)
if [ -f "$TARGET_PROJECT/.sd/ids/registry.json" ]; then
    echo "  SKIP: registry.json already exists (preserving existing IDs)"
else
    ISO_DATE=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
    cat > "$TARGET_PROJECT/.sd/ids/registry.json" << EOF
{
  "version": "1.0.0",
  "created": "$ISO_DATE",
  "project": "$PROJECT_NAME",
  "requirements": {},
  "specifications": {},
  "last_updated": "$ISO_DATE"
}
EOF
fi

# 5-7: handoff-log.json (skip if exists)
if [ -f "$TARGET_PROJECT/.sd/ai-coordination/handoff/handoff-log.json" ]; then
    echo "  SKIP: handoff-log.json already exists (preserving existing logs)"
else
    cat > "$TARGET_PROJECT/.sd/ai-coordination/handoff/handoff-log.json" << EOF
{
  "version": "2.0.0",
  "entries": []
}
EOF
fi

# 5b: Inject gas-fakes into target package.json (skip if protected by .sd003-keep)
TARGET_PKG="$TARGET_PROJECT/package.json"
if is_kept "package.json"; then
    echo "  KEEP: package.json preserved via .sd003-keep (gas-fakes injection skipped)"
    echo "package.json" >> "$KEPT_LOG"
elif [ -f "$TARGET_PKG" ]; then
    # Check if gas-fakes is already present
    if ! grep -q '"@mcpher/gas-fakes"' "$TARGET_PKG"; then
        # Add @mcpher/gas-fakes to devDependencies using node
        node -e "
            const fs = require('fs');
            const pkg = JSON.parse(fs.readFileSync('$TARGET_PKG', 'utf8'));
            if (!pkg.devDependencies) pkg.devDependencies = {};
            pkg.devDependencies['@mcpher/gas-fakes'] = '^1.2.0';
            if (!pkg.scripts) pkg.scripts = {};
            if (!pkg.scripts['test:gas-fakes']) {
                pkg.scripts['test:gas-fakes'] = 'jest --testPathPatterns=tests/gas-fakes/ --setupFiles=./tests/gas-fakes/setup.ts --passWithNoTests';
            }
            if (!pkg.scripts['test:validate-data']) {
                pkg.scripts['test:validate-data'] = 'powershell -ExecutionPolicy Bypass -File scripts/validate-test-data.ps1';
            }
            fs.writeFileSync('$TARGET_PKG', JSON.stringify(pkg, null, 2) + '\n', 'utf8');
        " 2>/dev/null && echo "  [Phase 5b] gas-fakes injected into package.json" || echo "  WARN: Failed to inject gas-fakes into package.json"
    else
        echo "  [Phase 5b] gas-fakes already present in package.json, skipping"
    fi
else
    echo "  [Phase 5b] No package.json found, skipping gas-fakes injection"
fi

# 5-8: User-level CLAUDE.md (initial setup for ~/.claude/CLAUDE.md)
USER_CLAUDE_TEMPLATE="$SOURCE_DIR/.claude/skills/sd-deploy/templates/user-claude.md.template"
USER_CLAUDE_DIR="$HOME/.claude"
USER_CLAUDE_FILE="$USER_CLAUDE_DIR/CLAUDE.md"
if [ -f "$USER_CLAUDE_TEMPLATE" ]; then
    if [ ! -f "$USER_CLAUDE_FILE" ]; then
        mkdir -p "$USER_CLAUDE_DIR"
        cp "$USER_CLAUDE_TEMPLATE" "$USER_CLAUDE_FILE"
        echo "  [Phase 5-8] User CLAUDE.md created: $USER_CLAUDE_FILE"
    else
        echo "  [Phase 5-8] User CLAUDE.md already exists, skipping: $USER_CLAUDE_FILE"
    fi
else
    echo "  WARN: user-claude.md.template not found, skipping"
fi

echo "[Phase 5/7] Generated files created"

# ============================================================
# Phase 6: Verification
# ============================================================
echo ""
echo "=== Verification ==="

ALL_PASSED=true

verify_category() {
    local label="$1"
    local src_path="$2"
    local dst_path="$3"
    local filter="${4:-*}"
    local recurse="${5:-true}"

    local src_count dst_count

    if [ "$recurse" = "true" ]; then
        src_count=$(find "$SOURCE_DIR/$src_path" -type f -name "$filter" 2>/dev/null | wc -l | tr -d ' ')
        dst_count=$(find "$TARGET_PROJECT/$dst_path" -type f -name "$filter" 2>/dev/null | wc -l | tr -d ' ')
    else
        src_count=$(ls -1 "$SOURCE_DIR/$src_path"/$filter 2>/dev/null | wc -l | tr -d ' ')
        dst_count=$(ls -1 "$TARGET_PROJECT/$dst_path"/$filter 2>/dev/null | wc -l | tr -d ' ')
    fi

    if [ "$dst_count" -ge "$src_count" ] 2>/dev/null; then
        echo "  [PASS] $label: $dst_count/$src_count"
    else
        echo "  [FAIL] $label: $dst_count/$src_count"
        ALL_PASSED=false
    fi
}

verify_category "Commands" ".claude/commands" ".claude/commands" "*.md" "false"
verify_category "Commands/sd" ".claude/commands/sd" ".claude/commands/sd" "*.md" "false"
verify_category "Rules" ".claude/rules" ".claude/rules" "*.md" "true"
verify_category "Skills" ".claude/skills" ".claude/skills" "*" "true"
verify_category "Hooks" ".claude/hooks" ".claude/hooks" "*" "true"
verify_category "Agents Skills (agy)" ".agents/skills" ".agents/skills" "*" "true"
verify_category "Codex" ".codex" ".codex" "*" "true"
verify_category "Grok" ".grok" ".grok" "*" "true"
verify_category "SD Settings" ".sd/settings" ".sd/settings" "*" "true"
verify_category "Handoff" ".handoff" ".handoff" "*" "true"
verify_category "Design" ".sd/design" ".sd/design" "*" "true"
verify_category "Ralph" ".sd/ralph" ".sd/ralph" "*" "true"
verify_category "Steering" ".sd/steering" ".sd/steering" "*" "true"
# Gas Fakes: only setup.ts is deployed (test files are project-specific)
if [ -f "$TARGET_PROJECT/tests/gas-fakes/setup.ts" ]; then
    echo "  [PASS] Gas Fakes Setup: 1/1"
else
    echo "  [FAIL] Gas Fakes Setup: 0/1"
    ALL_PASSED=false
fi

# Verify generated files
echo ""
echo "  Generated files:"
GENERATED_FILES=(
    "CLAUDE.md"
    "antigravity.md"
    "grok.md"
    ".sessions/session-current.md"
    ".sessions/TIMELINE.md"
    ".claude/settings.json"
    ".sd/ids/registry.json"
    ".sd/ai-coordination/handoff/handoff-log.json"
)

for f in "${GENERATED_FILES[@]}"; do
    if [ -f "$TARGET_PROJECT/$f" ]; then
        echo "    [PASS] $f"
    else
        echo "    [FAIL] $f"
        ALL_PASSED=false
    fi
done

echo "[Phase 6/7] Verification completed"

# ============================================================
# Phase 6b: Content verification gate (single Node verifier; hard-fail)
# Catches mis-wired settings.json / unsubstituted template vars / deprecated
# tokens / mojibake / invalid JSON that Phase 6's count+existence check misses.
# ============================================================
echo ""
echo "=== Content Verification (Phase 6b) ==="
if [ "$DRY_RUN" = true ]; then
    echo "  [SKIP] dry-run: nothing generated to verify"
else
    VERIFY_SCRIPT="$SOURCE_DIR/scripts/verify-deployment.mjs"
    if ! command -v node >/dev/null 2>&1; then
        echo "  [FAIL] node not found on PATH - cannot run content verification"
        ALL_PASSED=false
    elif [ ! -f "$VERIFY_SCRIPT" ]; then
        echo "  [FAIL] verifier not found: $VERIFY_SCRIPT"
        ALL_PASSED=false
    else
        if ! node "$VERIFY_SCRIPT" "$TARGET_PROJECT" "$SOURCE_DIR"; then
            ALL_PASSED=false
        fi
    fi
fi
echo "[Phase 6b/7] Content verification completed"

# ============================================================
# Phase 7: Report
# ============================================================
echo ""
echo "=== SD003 Framework Deployment Report ==="
echo ""

total_copied=0
for key in "${!COPY_STATS[@]}"; do
    total_copied=$((total_copied + ${COPY_STATS[$key]}))
done

echo "  Files copied: $total_copied"
echo "  Files generated: ${#GENERATED_FILES[@]}"
echo "  Backup: $BACKUP_DIR"
echo ""

# Honest reporting: kept (opt-out) and overwritten-divergence (potential data loss)
KEPT_UNIQ=$(sort -u "$KEPT_LOG" 2>/dev/null || true)
DIV_UNIQ=$(sort -u "$DIVERGED_LOG" 2>/dev/null || true)
if [ -n "$KEPT_UNIQ" ]; then
    echo "  Kept via .sd003-keep (not overwritten):"
    echo "$KEPT_UNIQ" | sed 's/^/    = /'
    echo ""
fi
if [ -n "$DIV_UNIQ" ]; then
    echo "  OVERWROTE local divergence (backed up in $BACKUP_DIR):"
    echo "$DIV_UNIQ" | sed 's/^/    ! /'
    echo "  -> If any were intentional customizations, restore from backup and add them to .sd003-keep."
    echo ""
fi
rm -f "$KEPT_LOG" "$DIVERGED_LOG"

if [ "$ALL_PASSED" = true ]; then
    echo "  Result: ALL PASSED"
else
    echo "  Result: SOME FAILURES - check above"
fi

echo ""
echo "Next Steps:"
echo "  1. cd $TARGET_PROJECT"
echo "  2. npm install  (to install @mcpher/gas-fakes and other dependencies)"
echo "  3. Review CLAUDE.md"
echo "  4. Run /sessionread to verify"
echo "  5. Start with /sd:spec-init {feature}"
echo ""
if [ "$ALL_PASSED" != true ]; then
    echo "SD003 deployment FAILED verification - fix the issues above and re-run."
    echo "(Deployed files remain in place; nothing was rolled back.)"
    exit 1
fi
echo "SD003 v${FRAMEWORK_VERSION} (deploy v${SD003_VERSION}) deployed successfully!"
