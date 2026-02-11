---
name: rollback-guard
description: |
  Proposal-based rollback system for refactoring safety.
  Triggers: Test failure after batch, same error 2nd occurrence.
  Actions: Propose rollback options via AskUserQuestion (NOT auto-execute).
allowed-tools: Bash, Read, Write, AskUserQuestion, Skill
---

# Rollback Guard Skill

## Purpose

Detect refactoring failures and PROPOSE rollback options to the user. This skill does NOT auto-execute rollbacks - it requires user confirmation for safety.

## Design Philosophy

| Action Type | Autonomous? | Rationale |
|-------------|-------------|-----------|
| Context management | Yes | Low risk, reversible |
| Session persistence | Yes | Low risk, additive |
| **Rollback** | **No (Proposal)** | **High risk, destructive** |

## Trigger Conditions

This skill activates when:

1. **Test Failure After Batch**: Tests fail after `REFACTOR_BATCH_*_COMPLETE`
2. **Same Error 2nd Time**: Identical error pattern detected twice
3. **Build Failure**: TypeScript or ESLint fails after refactoring
4. **Manual Request**: User explicitly requests rollback evaluation

## Proposal-Based Actions

### On Test Failure Detection

```
1. [AUTO] Log: "Rollback guard triggered: Test failure detected"
2. [AUTO] Execute: /sessionwrite (preserve current state)
3. [AUTO] Analyze: Identify available checkpoints
4. [PROPOSAL] AskUserQuestion with rollback options
5. [WAIT] User selects option
6. [EXECUTE] Perform selected action
```

### AskUserQuestion Format

```yaml
Question: "Refactoring batch failed. How would you like to proceed?"
Header: "Rollback"
Options:
  - label: "Rollback to last checkpoint"
    description: "Restore to checkpoint-{N} ({timestamp}). Discards current batch changes."
  - label: "Rollback to specific checkpoint"
    description: "Choose from checkpoint history. Shows all available restore points."
  - label: "Continue manual fix"
    description: "Keep current state and attempt manual repair."
  - label: "Escalate to dialogue-resolution"
    description: "Switch to structured problem-solving mode."
```

## Checkpoint Management

### Checkpoint Structure

```
.kiro/refactor/checkpoints/{session-id}/
├── checkpoint-000-init.json
├── checkpoint-001-batch-a.json
└── checkpoint-002-batch-b.json
```

### Checkpoint JSON Format

```json
{
  "id": "checkpoint-001-batch-a",
  "timestamp": "2026-01-01T15:30:00Z",
  "session_id": "refactor-20260101-150000",
  "method": "git-stash",
  "stash_ref": "stash@{0}",
  "branch": "refactor/feature-x",
  "commit_before": "abc1234",
  "files_changed": [
    "src/handlers/auth.ts",
    "src/handlers/user.ts"
  ],
  "test_status": "pass",
  "quality_gate": {
    "lint": "pass",
    "type": "pass",
    "test": "pass"
  }
}
```

### Rollback Execution

#### Option 1: Last Checkpoint

```bash
# Read checkpoint metadata
checkpoint=$(cat .kiro/refactor/checkpoints/{session-id}/checkpoint-{latest}.json)
stash_ref=$(echo $checkpoint | jq -r '.stash_ref')

# Apply rollback
git stash pop $stash_ref
# OR if stash was cleared
git reset --hard $(echo $checkpoint | jq -r '.commit_before')
```

#### Option 2: Specific Checkpoint

```bash
# List available checkpoints
ls -la .kiro/refactor/checkpoints/{session-id}/

# User selects checkpoint-{N}
# Execute rollback to that point
git reset --hard {commit_from_checkpoint}
```

#### Option 3: Continue Manual

```
# No rollback executed
# Log decision for traceability
echo "Manual fix selected at $(date)" >> .kiro/refactor/decisions.log
```

#### Option 4: Escalate

```
# Invoke dialogue-resolution
/dialogue-resolution "Refactoring failure: {error_description}"
```

## Error Pattern Tracking

### Pattern Detection

Track error signatures to detect repeated failures:

```
.kiro/refactor/.error-patterns.log

Format:
{timestamp}|{error_signature}|{occurrence_count}
```

### Same Error 2nd Time Rule

```
1st occurrence: Log, allow retry
2nd occurrence: Trigger rollback-guard proposal
3rd occurrence: Strongly recommend dialogue-resolution
```

## Integration with Ralph Loop

### Escalation Flow

```
Ralph Loop (test failure)
    |
    v
[1st occurrence] -> Ralph auto-fix attempt
    |
    v
[2nd same error] -> rollback-guard activates
    |                    |
    v                    v
[Proposal to user]  [session-autosave runs first]
    |
    v
[User decision]
    |
    +---> Rollback to checkpoint
    +---> Continue manual fix
    +---> Escalate to dialogue-resolution
```

## Logging Format

```
[ROLLBACK-GUARD] {timestamp} - {action}
```

Examples:
```
[ROLLBACK-GUARD] 2026-01-01T15:45:00 - Triggered: Test failure after batch-002
[ROLLBACK-GUARD] 2026-01-01T15:45:01 - Session saved before proposal
[ROLLBACK-GUARD] 2026-01-01T15:45:02 - Proposing rollback options to user
[ROLLBACK-GUARD] 2026-01-01T15:45:30 - User selected: Rollback to checkpoint-001
[ROLLBACK-GUARD] 2026-01-01T15:45:35 - Rollback complete: reset to abc1234
```

## Configuration

In `.kiro/refactor/config.json`:

```json
{
  "rollback_guard": {
    "enabled": true,
    "auto_execute": false,
    "error_tracking": true,
    "max_same_error": 2,
    "escalation_command": "/dialogue-resolution"
  }
}
```

## Safety Guarantees

1. **Never auto-rollback**: Always requires user confirmation
2. **Always save first**: `/sessionwrite` before any rollback proposal
3. **Preserve options**: Keep all checkpoints until session complete
4. **Traceability**: Log all decisions and actions

## Dependencies

- Git for stash/reset operations
- `/sessionwrite` command
- `/dialogue-resolution` command for escalation
- `.kiro/refactor/checkpoints/` directory
