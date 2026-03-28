---
name: context-autonomy
description: |
  Autonomous context window management for refactoring sessions.
  Triggers: After batch operations, on completion markers, periodically.
  Actions: Auto-compact at 70%, auto-clear at 85%, always preserves session first.
allowed-tools: Bash, Write, Read, Skill
---

# Context Autonomy Skill

## Purpose

Automatically manage context window usage during refactoring sessions to prevent context exhaustion and ensure session continuity.

## Trigger Conditions

This skill activates when ANY of these conditions are detected in the transcript:

1. **Batch Completion**: `REFACTOR_BATCH_*_COMPLETE` marker detected
2. **Test Pass**: `ALL_TESTS_PASS` marker detected
3. **Quality Gate Pass**: `LINT_CLEAN`, `TYPE_CHECK_PASS` markers
4. **Context Warning**: Claude mentions context usage percentage

## Autonomous Actions

### Threshold-Based Response

| Context Usage | Action | User Confirmation |
|---------------|--------|-------------------|
| < 50% | Continue normally | None |
| 50-69% | Log status silently | None |
| 70-84% | Execute `/sessionwrite` then `/compact` | **None (autonomous)** |
| >= 85% | Execute `/sessionwrite` then `/clear` then `/sessionread` | **None (autonomous)** |

### Action Sequence

#### At 70% Threshold (Compact Cycle)

```
1. [AUTO] Log: "Context at ~70%. Initiating autonomous compact cycle."
2. [AUTO] Execute: /sessionwrite
3. [AUTO] Wait for session save confirmation
4. [AUTO] Execute: /compact
5. [AUTO] Log: "Compact complete. Session preserved."
```

#### At 85% Threshold (Clear Cycle)

```
1. [AUTO] Log: "Context at ~85%. Initiating autonomous clear cycle."
2. [AUTO] Execute: /sessionwrite
3. [AUTO] Wait for session save confirmation
4. [AUTO] Execute: /clear
5. [AUTO] Execute: /sessionread
6. [AUTO] Log: "Context cleared. Session restored from: session-current.md"
```

## Context Estimation Method

Since programmatic context API is not available, estimate usage by:

1. **Transcript Length**: Count approximate tokens in conversation
2. **Tool Call Count**: Each tool call consumes ~500-2000 tokens
3. **File Read Size**: Large files significantly impact context
4. **Pattern Detection**: Look for Claude's own context warnings

### Estimation Formula

```
estimated_usage = (transcript_chars / 800000) * 100

# Rough mapping:
# 200K chars ~ 50% usage
# 280K chars ~ 70% usage
# 340K chars ~ 85% usage
```

## Integration with Refactoring Workflow

### During `/refactor:batch`

After each batch completion:
1. Check estimated context usage
2. If threshold exceeded, trigger appropriate cycle
3. Resume batch processing after cycle completes

### Session Preservation Guarantees

- **Never lose work**: Always `/sessionwrite` before any clear/compact
- **Seamless resume**: `/sessionread` restores full context after clear
- **Checkpoint sync**: Update checkpoint registry in session file

## Logging Format

All autonomous actions are logged with this prefix:

```
[CONTEXT-AUTONOMY] {timestamp} - {action}
```

Examples:
```
[CONTEXT-AUTONOMY] 2026-01-01T15:30:00 - Context estimated at 72%. Initiating compact cycle.
[CONTEXT-AUTONOMY] 2026-01-01T15:30:05 - Session saved: session-20260101-153005.md
[CONTEXT-AUTONOMY] 2026-01-01T15:30:10 - Compact complete. Resumed refactoring.
```

## Error Handling

| Error | Recovery |
|-------|----------|
| sessionwrite fails | Retry once, then warn user |
| compact fails | Skip compact, continue with warning |
| clear fails | Critical - stop and ask user |
| sessionread fails | Critical - show manual recovery steps |

## Manual Override

User can disable autonomous context management by setting in `.sd/refactor/config.json`:

```json
{
  "context_autonomy": {
    "enabled": false
  }
}
```

## Dependencies

- `/sessionwrite` command must be available
- `/sessionread` command must be available
- `.sd/sessions/` directory must exist
