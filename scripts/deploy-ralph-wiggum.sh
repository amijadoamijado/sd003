#!/bin/bash
# Ralph Wiggum Deployment Script
# Deploys Ralph Wiggum night-mode autonomous execution system to target project
#
# Usage:
#   ./scripts/deploy-ralph-wiggum.sh /path/to/target/project
#   ./scripts/deploy-ralph-wiggum.sh /path/to/target/project --with-specs
#
# Options:
#   --with-specs    Include specification documents
#   --dry-run       Preview without copying
#   --help          Show this help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory (SD002 root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SD002_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
TARGET_DIR=""
WITH_SPECS=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --with-specs)
            WITH_SPECS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Ralph Wiggum Deployment Script"
            echo ""
            echo "Usage:"
            echo "  $0 /path/to/target/project [options]"
            echo ""
            echo "Options:"
            echo "  --with-specs    Include specification documents"
            echo "  --dry-run       Preview without copying"
            echo "  --help          Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 ../my-project --with-specs"
            exit 0
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Validate target directory
if [ -z "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Target directory not specified${NC}"
    echo "Usage: $0 /path/to/target/project [--with-specs] [--dry-run]"
    exit 1
fi

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN] Would create: $TARGET_DIR${NC}"
    else
        mkdir -p "$TARGET_DIR"
    fi
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Ralph Wiggum Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Source:  ${GREEN}$SD002_ROOT${NC}"
echo -e "Target:  ${GREEN}$TARGET_DIR${NC}"
echo -e "Options: with-specs=${WITH_SPECS}, dry-run=${DRY_RUN}"
echo ""

# Function to copy with dry-run support
copy_item() {
    local src="$1"
    local dest="$2"
    local type="$3"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN] Would copy $type: $src -> $dest${NC}"
    else
        if [ -d "$src" ]; then
            mkdir -p "$(dirname "$dest")"
            cp -r "$src" "$dest"
            echo -e "${GREEN}[COPIED] $type: $dest${NC}"
        elif [ -f "$src" ]; then
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
            echo -e "${GREEN}[COPIED] $type: $dest${NC}"
        else
            echo -e "${RED}[SKIP] Not found: $src${NC}"
        fi
    fi
}

echo -e "${BLUE}Step 1: Deploying .sd/ralph/ directory...${NC}"
copy_item "$SD002_ROOT/.sd/ralph" "$TARGET_DIR/.sd/ralph" "directory"

echo ""
echo -e "${BLUE}Step 2: Deploying commands...${NC}"
mkdir -p "$TARGET_DIR/.claude/commands" 2>/dev/null || true
for cmd in ralph-wiggum-run.md ralph-wiggum-status.md ralph-wiggum-plan.md; do
    copy_item "$SD002_ROOT/.claude/commands/$cmd" "$TARGET_DIR/.claude/commands/$cmd" "command"
done

echo ""
echo -e "${BLUE}Step 3: Deploying rules...${NC}"
if [ -f "$TARGET_DIR/.claude/rules/ralph-loop.md" ]; then
    echo -e "${YELLOW}[INFO] ralph-loop.md already exists, appending Night Mode section...${NC}"
    if [ "$DRY_RUN" = false ]; then
        # Extract Night Mode section from source
        sed -n '/^## Night Mode/,$p' "$SD002_ROOT/.claude/rules/ralph-loop.md" >> "$TARGET_DIR/.claude/rules/ralph-loop.md"
    fi
else
    copy_item "$SD002_ROOT/.claude/rules/ralph-loop.md" "$TARGET_DIR/.claude/rules/ralph-loop.md" "rule"
fi

if [ "$WITH_SPECS" = true ]; then
    echo ""
    echo -e "${BLUE}Step 4: Deploying specifications...${NC}"
    copy_item "$SD002_ROOT/.sd/specs/ralph-wiggum" "$TARGET_DIR/.sd/specs/ralph-wiggum" "specs"
fi

echo ""
echo -e "${BLUE}Step 5: Deploying deployment guide...${NC}"
copy_item "$SD002_ROOT/docs/ralph-wiggum-deployment.md" "$TARGET_DIR/docs/ralph-wiggum-deployment.md" "docs"

echo ""
echo -e "${BLUE}========================================${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY-RUN COMPLETE - No files were copied${NC}"
else
    echo -e "${GREEN}DEPLOYMENT COMPLETE${NC}"
fi
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Review deployed files in $TARGET_DIR"
echo "  2. Update CLAUDE.md with Ralph Wiggum reference"
echo "  3. Create weekly plan: /ralph-wiggum:plan"
echo "  4. Setup nightly queue: .sd/ralph/nightly-queue.md"
echo ""
echo "Documentation: $TARGET_DIR/docs/ralph-wiggum-deployment.md"
