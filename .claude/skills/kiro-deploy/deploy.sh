#!/bin/bash
# SD003 Framework Deployment Script v3.1.0 (Bash)
# Usage: ./deploy.sh <target-project-path>

set -e

# Configuration
SD003_VERSION="3.1.0"
FRAMEWORK_VERSION="2.13.0"
SOURCE_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
TARGET_PROJECT="${1:?Error: Target project path required}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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
# Phase 2: Backup
# ============================================================
BACKUP_DIR="$TARGET_PROJECT/.sd003-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

for f in CLAUDE.md gemini.md; do
    [ -f "$TARGET_PROJECT/$f" ] && cp "$TARGET_PROJECT/$f" "$BACKUP_DIR/" 2>/dev/null || true
done

for d in .claude .gemini .kiro .antigravity; do
    [ -d "$TARGET_PROJECT/$d" ] && cp -r "$TARGET_PROJECT/$d" "$BACKUP_DIR/" 2>/dev/null || true
done
echo "[Phase 2/7] Backup created: $BACKUP_DIR"

# ============================================================
# Phase 3: Create directory structure
# ============================================================
DIRS=(
    ".claude/commands/kiro"
    ".claude/rules"
    ".claude/skills"
    ".claude/hooks"
    ".gemini/commands"
    ".kiro/specs"
    ".kiro/steering"
    ".kiro/sessions"
    ".kiro/settings"
    ".kiro/ids"
    ".kiro/traceability"
    ".kiro/ai-coordination/workflow/templates"
    ".kiro/ai-coordination/workflow/spec"
    ".kiro/ai-coordination/workflow/review"
    ".kiro/ai-coordination/workflow/log"
    ".kiro/ai-coordination/handoff"
    ".antigravity"
    ".handoff"
    ".kiro/ralph"
    ".kiro/refactor"
    "docs/troubleshooting/bug-reports"
    "materials/csv"
    "materials/excel"
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

    # Copy entire tree preserving structure
    cd "$src"
    find . -type f -name "$filter" | while read -r file; do
        local dest_dir="$dst/$(dirname "$file")"
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
    count=$(ls -1 "$src"/*"$ext" 2>/dev/null | wc -l | tr -d ' ')
    cp "$src"/*"$ext" "$dst/" 2>/dev/null || true
    COPY_STATS[$label]=$count
}

# 4-1: .claude/commands/*.md
copy_flat_dir ".claude/commands" "Commands" ".md"

# 4-2: .claude/commands/kiro/*.md
copy_flat_dir ".claude/commands/kiro" "Commands/kiro" ".md"

# 4-3: .claude/rules/ (tree)
copy_dir_tree ".claude/rules" "Rules" "*.md"

# 4-4: .claude/skills/ (tree)
copy_dir_tree ".claude/skills" "Skills" "*"

# 4-5: .claude/hooks/ (tree)
copy_dir_tree ".claude/hooks" "Hooks" "*"

# 4-6: .gemini/commands/ (flat, .toml)
copy_flat_dir ".gemini/commands" "Gemini Commands" ".toml"

# 4-7: .antigravity/ (tree)
copy_dir_tree ".antigravity" "Antigravity" "*"

# 4-8: .kiro/settings/ (tree)
copy_dir_tree ".kiro/settings" "Kiro Settings" "*"

# 4-9: .kiro/sessions/session-template.md
if [ -f "$SOURCE_DIR/.kiro/sessions/session-template.md" ]; then
    cp "$SOURCE_DIR/.kiro/sessions/session-template.md" "$TARGET_PROJECT/.kiro/sessions/"
    COPY_STATS["Session Template"]=1
else
    echo "  WARN: session-template.md not found"
    COPY_STATS["Session Template"]=0
fi

# 4-10: .kiro/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}
WF_SRC="$SOURCE_DIR/.kiro/ai-coordination/workflow"
WF_DST="$TARGET_PROJECT/.kiro/ai-coordination/workflow"
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

# 4-12: docs/quality-gates.md
if [ -f "$SOURCE_DIR/docs/quality-gates.md" ]; then
    mkdir -p "$TARGET_PROJECT/docs"
    cp "$SOURCE_DIR/docs/quality-gates.md" "$TARGET_PROJECT/docs/"
    COPY_STATS["Docs/QualityGates"]=1
else
    COPY_STATS["Docs/QualityGates"]=0
fi

# 4-13: .handoff/ (tree)
copy_dir_tree ".handoff" "Handoff" "*"

# 4-14: scripts/sync-codex-prompts.js (single file)
if [ -f "$SOURCE_DIR/scripts/sync-codex-prompts.js" ]; then
    mkdir -p "$TARGET_PROJECT/scripts"
    cp "$SOURCE_DIR/scripts/sync-codex-prompts.js" "$TARGET_PROJECT/scripts/"
    COPY_STATS["Sync Codex"]=1
else
    COPY_STATS["Sync Codex"]=0
fi

# 4-15a: scripts/validate-test-data.ps1 (single file)
if [ -f "$SOURCE_DIR/scripts/validate-test-data.ps1" ]; then
    mkdir -p "$TARGET_PROJECT/scripts"
    cp "$SOURCE_DIR/scripts/validate-test-data.ps1" "$TARGET_PROJECT/scripts/"
    COPY_STATS["Validate Test Data (ps1)"]=1
else
    COPY_STATS["Validate Test Data (ps1)"]=0
fi

# 4-15b: scripts/validate-test-data.sh (single file)
if [ -f "$SOURCE_DIR/scripts/validate-test-data.sh" ]; then
    mkdir -p "$TARGET_PROJECT/scripts"
    cp "$SOURCE_DIR/scripts/validate-test-data.sh" "$TARGET_PROJECT/scripts/"
    COPY_STATS["Validate Test Data (sh)"]=1
else
    COPY_STATS["Validate Test Data (sh)"]=0
fi

# 4-16: scripts/sync-gemini-features.js (single file)
if [ -f "$SOURCE_DIR/scripts/sync-gemini-features.js" ]; then
    mkdir -p "$TARGET_PROJECT/scripts"
    cp "$SOURCE_DIR/scripts/sync-gemini-features.js" "$TARGET_PROJECT/scripts/"
    COPY_STATS["Sync Gemini"]=1
else
    COPY_STATS["Sync Gemini"]=0
fi

# 4-16: AGENTS.md (single file)
if [ -f "$SOURCE_DIR/AGENTS.md" ]; then
    cp "$SOURCE_DIR/AGENTS.md" "$TARGET_PROJECT/"
    COPY_STATS["AGENTS.md"]=1
else
    COPY_STATS["AGENTS.md"]=0
fi

# 4-17: .kiro/ralph/ (tree)
copy_dir_tree ".kiro/ralph" "Ralph" "*"

# 4-18: .kiro/steering/ (tree)
copy_dir_tree ".kiro/steering" "Steering" "*"

# 4-19: .kiro/refactor/config.json (single file)
if [ -f "$SOURCE_DIR/.kiro/refactor/config.json" ]; then
    mkdir -p "$TARGET_PROJECT/.kiro/refactor"
    cp "$SOURCE_DIR/.kiro/refactor/config.json" "$TARGET_PROJECT/.kiro/refactor/"
    COPY_STATS["Refactor Config"]=1
else
    COPY_STATS["Refactor Config"]=0
fi

# 4-20: tests/gas-fakes/setup.ts (single file)
GAS_FAKES_SRC="$SOURCE_DIR/tests/gas-fakes/setup.ts"
if [ -f "$GAS_FAKES_SRC" ]; then
    mkdir -p "$TARGET_PROJECT/tests/gas-fakes"
    cp "$GAS_FAKES_SRC" "$TARGET_PROJECT/tests/gas-fakes/setup.ts"
    COPY_STATS["Gas Fakes Setup"]=1
else
    echo "  WARN: tests/gas-fakes/setup.ts not found"
    COPY_STATS["Gas Fakes Setup"]=0
fi

echo "[Phase 4/7] Dynamic copy completed"
for key in "${!COPY_STATS[@]}"; do
    echo "  $key: ${COPY_STATS[$key]} files"
done

# ============================================================
# Phase 5: Generate files
# ============================================================
PROJECT_NAME=$(basename "$TARGET_PROJECT")

# 5-1: CLAUDE.md from template
CLAUDE_TEMPLATE="$SOURCE_DIR/.claude/skills/kiro-deploy/templates/CLAUDE.md.template"
if [ -f "$CLAUDE_TEMPLATE" ]; then
    sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s/{{DATE}}/$DATE/g" \
        -e "s/v2\.3\.0/v$FRAMEWORK_VERSION/g" \
        "$CLAUDE_TEMPLATE" > "$TARGET_PROJECT/CLAUDE.md"
else
    echo "  WARN: CLAUDE.md.template not found, skipping"
fi

# 5-2: gemini.md from template
GEMINI_TEMPLATE="$SOURCE_DIR/.claude/skills/kiro-deploy/templates/gemini.md.template"
if [ -f "$GEMINI_TEMPLATE" ]; then
    sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s/{{DATE}}/$DATE/g" \
        -e "s/v2\.3\.0/v$FRAMEWORK_VERSION/g" \
        "$GEMINI_TEMPLATE" > "$TARGET_PROJECT/gemini.md"
else
    echo "  WARN: gemini.md.template not found, skipping"
fi

# 5-3: session-current.md (new)
cat > "$TARGET_PROJECT/.kiro/sessions/session-current.md" << EOF
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

# 5-4: TIMELINE.md (new)
cat > "$TARGET_PROJECT/.kiro/sessions/TIMELINE.md" << EOF
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

# 5-5: .claude/settings.json (OS-aware)
OS_TYPE="$(uname -s 2>/dev/null || echo 'Unknown')"
if [[ "$OS_TYPE" == *"MINGW"* ]] || [[ "$OS_TYPE" == *"MSYS"* ]] || [[ "$OS_TYPE" == *"CYGWIN"* ]]; then
    # Windows (Git Bash/MSYS)
    HOOK_CMD='powershell -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR\\.claude\\hooks\\sd003-stop-hook.ps1\"'
else
    # Linux/Mac
    HOOK_CMD='bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/sd003-stop-hook.sh\"'
fi

cat > "$TARGET_PROJECT/.claude/settings.json" << EOF
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
      }
    ]
  }
}
EOF

# 5-6: .kiro/ids/registry.json (new)
ISO_DATE=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
cat > "$TARGET_PROJECT/.kiro/ids/registry.json" << EOF
{
  "version": "1.0.0",
  "created": "$ISO_DATE",
  "project": "$PROJECT_NAME",
  "requirements": {},
  "specifications": {},
  "last_updated": "$ISO_DATE"
}
EOF

# 5-7: handoff-log.json (new)
cat > "$TARGET_PROJECT/.kiro/ai-coordination/handoff/handoff-log.json" << EOF
{
  "version": "2.0.0",
  "entries": []
}
EOF

# 5b: Inject gas-fakes into target package.json (if it exists)
TARGET_PKG="$TARGET_PROJECT/package.json"
if [ -f "$TARGET_PKG" ]; then
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
            fs.writeFileSync('$TARGET_PKG', JSON.stringify(pkg, null, 2) + '\n', 'utf8');
        " 2>/dev/null && echo "  [Phase 5b] gas-fakes injected into package.json" || echo "  WARN: Failed to inject gas-fakes into package.json"
    else
        echo "  [Phase 5b] gas-fakes already present in package.json, skipping"
    fi
else
    echo "  [Phase 5b] No package.json found, skipping gas-fakes injection"
fi

# 5-8: User-level CLAUDE.md (initial setup for ~/.claude/CLAUDE.md)
USER_CLAUDE_TEMPLATE="$SOURCE_DIR/.claude/skills/kiro-deploy/templates/user-claude.md.template"
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
verify_category "Commands/kiro" ".claude/commands/kiro" ".claude/commands/kiro" "*.md" "false"
verify_category "Rules" ".claude/rules" ".claude/rules" "*.md" "true"
verify_category "Skills" ".claude/skills" ".claude/skills" "*" "true"
verify_category "Hooks" ".claude/hooks" ".claude/hooks" "*" "true"
verify_category "Gemini Commands" ".gemini/commands" ".gemini/commands" "*.toml" "false"
verify_category "Antigravity" ".antigravity" ".antigravity" "*" "true"
verify_category "Kiro Settings" ".kiro/settings" ".kiro/settings" "*" "true"
verify_category "Handoff" ".handoff" ".handoff" "*" "true"
verify_category "Ralph" ".kiro/ralph" ".kiro/ralph" "*" "true"
verify_category "Steering" ".kiro/steering" ".kiro/steering" "*" "true"
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
    "gemini.md"
    ".kiro/sessions/session-current.md"
    ".kiro/sessions/TIMELINE.md"
    ".claude/settings.json"
    ".kiro/ids/registry.json"
    ".kiro/ai-coordination/handoff/handoff-log.json"
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
echo "  5. Start with /kiro:spec-init {feature}"
echo ""
echo "SD003 v${FRAMEWORK_VERSION} (deploy v${SD003_VERSION}) deployed successfully!"
