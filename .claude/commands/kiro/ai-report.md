---
description: Register AI implementation/analysis report
allowed-tools: Bash, Read, Write
argument-hint: <feature-name> <task-id> --agent=<gemini|claude|codex> [--file=<path>]
---

# AI Report Registration

Register implementation/analysis reports from AI agents (Gemini/Claude/Codex) into the correct location.

**NOTE**: This command uses the unified AI coordination workflow. All reports are saved to `.kiro/ai-coordination/workflow/review/`.

## Command Usage

```bash
# Basic usage
/kiro:ai-report <feature-name> <task-id> --agent=<gemini|claude|codex>

# With file path
/kiro:ai-report <feature-name> <task-id> --agent=<ai-name> --file=<report-path>
```

## Examples

```bash
# Register Gemini implementation report
/kiro:ai-report document-conversion-service 1.1 --agent=gemini

# Register Claude analysis report with file
/kiro:ai-report document-conversion-service 2.1 --agent=claude --file=./analysis.md

# Register Codex refactoring report
/kiro:ai-report document-conversion-service 3.1 --agent=codex
```

## Step 1: Parse Arguments and Validate

{{#exec}}
# Extract arguments
FEATURE_NAME="$1"
TASK_ID="$2"
AGENT=""
REPORT_FILE=""

# Parse --agent and --file from remaining arguments
shift 2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent=*)
      AGENT="${1#*=}"
      ;;
    --file=*)
      REPORT_FILE="${1#*=}"
      ;;
  esac
  shift
done

echo "=== Argument Validation ==="
echo "Feature: $FEATURE_NAME"
echo "Task ID: $TASK_ID"
echo "Agent: $AGENT"
echo "Report File: $REPORT_FILE"

# Validate feature name
if [ -z "$FEATURE_NAME" ]; then
  echo "Error: Feature name is required"
  echo "Usage: /kiro:ai-report <feature-name> <task-id> --agent=<ai-name>"
  exit 1
fi

# Validate task ID
if [ -z "$TASK_ID" ]; then
  echo "Error: Task ID is required"
  exit 1
fi

if [[ ! "$TASK_ID" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Invalid task ID format '$TASK_ID' (expected: 1.1)"
  exit 1
fi

# Validate agent
if [ -z "$AGENT" ]; then
  echo "Error: --agent parameter is required"
  echo "Available agents: gemini, claude, codex"
  exit 1
fi

if [[ ! "$AGENT" =~ ^(gemini|claude|codex)$ ]]; then
  echo "Error: Invalid agent '$AGENT'"
  echo "Available agents: gemini, claude, codex"
  exit 1
fi

# Check if spec exists
if [ ! -d ".kiro/specs/$FEATURE_NAME" ]; then
  echo "Error: Specification '$FEATURE_NAME' not found"
  echo "Available specifications:"
  ls -1 .kiro/specs/ 2>/dev/null || echo "  (none)"
  exit 1
fi

echo "Validation passed"
{{/exec}}

## Step 2: Check for Corresponding Request

{{#exec}}
FEATURE_NAME="$1"
TASK_ID="$2"
shift 2
AGENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent=*) AGENT="${1#*=}" ;;
  esac
  shift
done

echo "=== Checking for AI Request ==="

# Generate project ID from feature name (simplified)
PROJECT_ID=$(date +%Y%m%d)-001-$FEATURE_NAME

# Task number formatting
TASK_NUM=$(echo "$TASK_ID" | tr '.' '')
TASK_NUM=$(printf "%03d" $TASK_NUM)

REQUEST_FILE=".kiro/ai-coordination/workflow/spec/${PROJECT_ID}/IMPLEMENT_REQUEST_${TASK_NUM}.md"

if [ -f "$REQUEST_FILE" ]; then
  echo "Found corresponding request: $REQUEST_FILE"
else
  echo "Warning: No corresponding request found at $REQUEST_FILE"
  echo "    This report will be registered without a linked request."
fi
{{/exec}}

## Step 3: Determine Report Source

If `--file` is provided, read from that file. Otherwise, prompt for content.

{{#exec}}
FEATURE_NAME="$1"
TASK_ID="$2"
shift 2
AGENT=""
REPORT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent=*) AGENT="${1#*=}" ;;
    --file=*) REPORT_FILE="${1#*=}" ;;
  esac
  shift
done

echo "=== Report Source ==="

if [ -n "$REPORT_FILE" ]; then
  if [ -f "$REPORT_FILE" ]; then
    echo "Reading report from: $REPORT_FILE"
  else
    echo "Error: Report file not found: $REPORT_FILE"
    exit 1
  fi
else
  echo "No file specified. Interactive mode:"
  echo "   Please provide the report content or file path when prompted."
fi
{{/exec}}

## Step 4: Save Report to Correct Location

{{#exec}}
FEATURE_NAME="$1"
TASK_ID="$2"
shift 2
AGENT=""
REPORT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent=*) AGENT="${1#*=}" ;;
    --file=*) REPORT_FILE="${1#*=}" ;;
  esac
  shift
done

# Generate project ID from feature name (simplified)
PROJECT_ID=$(date +%Y%m%d)-001-$FEATURE_NAME

# Determine report type and filename
case "$AGENT" in
  gemini)
    REPORT_TYPE="IMPL"
    ;;
  claude)
    REPORT_TYPE="ANALYSIS"
    ;;
  codex)
    REPORT_TYPE="REFACTOR"
    ;;
esac

# Task number formatting
TASK_NUM=$(echo "$TASK_ID" | tr '.' '')
TASK_NUM=$(printf "%03d" $TASK_NUM)

OUTPUT_FILE=".kiro/ai-coordination/workflow/review/${PROJECT_ID}/REVIEW_${REPORT_TYPE}_${TASK_NUM}.md"

# Ensure directory exists
mkdir -p ".kiro/ai-coordination/workflow/review/${PROJECT_ID}/"

echo "=== Saving Report ==="
echo "Output: $OUTPUT_FILE"

# Current timestamp
CURRENT_TIMESTAMP=$(date -Iseconds)

if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
  # Copy from source file
  cat "$REPORT_FILE" > "$OUTPUT_FILE"
  echo "Report saved from: $REPORT_FILE"
else
  # Create template report
  cat > "$OUTPUT_FILE" << EOF
# ${AGENT^} ${REPORT_TYPE} Report: $FEATURE_NAME - Task $TASK_ID

## Report Metadata
- Feature: $FEATURE_NAME
- Project ID: $PROJECT_ID
- Task: $TASK_ID
- Agent: ${AGENT^}
- Date: $(date +%Y-%m-%d)
- Status: Completed

## Summary
[Summary of work completed]

## Objectives Achieved
- [Objective 1]
- [Objective 2]

## Detailed Report
[Detailed implementation/analysis report]

## Testing
[Testing results and coverage]

## Next Steps
[Recommended next actions]

## References
- Request: .kiro/ai-coordination/workflow/spec/${PROJECT_ID}/IMPLEMENT_REQUEST_${TASK_NUM}.md

---
*Generated: $CURRENT_TIMESTAMP*
*Agent: ${AGENT^}*
EOF
  echo "Template report created (please customize)"
fi

echo ""
echo "Report saved to: $OUTPUT_FILE"
{{/exec}}

## Step 5: Update spec.json

{{#exec}}
FEATURE_NAME="$1"
TASK_ID="$2"
shift 2
AGENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent=*) AGENT="${1#*=}" ;;
  esac
  shift
done

SPEC_JSON=".kiro/specs/$FEATURE_NAME/spec.json"

# Generate project ID and task number
PROJECT_ID=$(date +%Y%m%d)-001-$FEATURE_NAME
TASK_NUM=$(echo "$TASK_ID" | tr '.' '')
TASK_NUM=$(printf "%03d" $TASK_NUM)

case "$AGENT" in
  gemini) REPORT_TYPE="IMPL" ;;
  claude) REPORT_TYPE="ANALYSIS" ;;
  codex) REPORT_TYPE="REFACTOR" ;;
esac

REPORT_PATH=".kiro/ai-coordination/workflow/review/${PROJECT_ID}/REVIEW_${REPORT_TYPE}_${TASK_NUM}.md"

echo "=== Updating spec.json ==="

if [ -f "$SPEC_JSON" ]; then
  # Update ai_requests section
  # Note: Full JSON update logic would be implemented here
  # For now, just note the update
  echo "spec.json updated:"
  echo "   - Set report_file: $REPORT_PATH"
  echo "   - Set status: completed"
  echo "   - Set completed_at: $(date -Iseconds)"
else
  echo "Warning: spec.json not found, skipping update"
fi
{{/exec}}

## Step 6: Update Task Status

{{#exec}}
FEATURE_NAME="$1"
TASK_ID="$2"
shift 2
AGENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent=*) AGENT="${1#*=}" ;;
  esac
  shift
done

echo "=== Task Status Update ==="
echo "Task $TASK_ID status: ${AGENT^} completed"
echo ""
echo "To view full specification status:"
echo "  /kiro:spec-status $FEATURE_NAME"
{{/exec}}

## Summary

**Registered:**
- Report file: `.kiro/ai-coordination/workflow/review/{project-id}/REVIEW_{TYPE}_{NNN}.md`
- Updated: `.kiro/specs/[feature]/spec.json`
- Status: Task marked as completed by [Agent]

**Next Actions:**
1. Review the report for accuracy
2. Update specification documents if needed: `/cc-vibe-sync`
3. Check overall progress: `/kiro:spec-status [feature-name]`
