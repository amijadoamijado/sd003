---
name: session-autosave
description: |
  Automatic session persistence for refactoring workflows.
  Triggers: Batch completion, test pass, quality gate pass, checkpoint creation.
  Actions: Execute /sessionwrite, update checkpoint registry.
allowed-tools: Bash, Write, Read, Skill
---

# Session Autosave Skill

## Purpose

Automatically persist session state during refactoring to ensure no work is lost and enable seamless recovery from interruptions.

## Trigger Conditions

This skill activates when ANY of these markers are detected:

| Marker | Description |
|--------|-------------|
| `REFACTOR_BATCH_{id}_COMPLETE` | Batch processing finished |
| `ALL_TESTS_PASS` | All tests passed |
| `LINT_CLEAN` | ESLint passed with 0 errors |
| `TYPE_CHECK_PASS` | TypeScript strict mode passed |
| `CHECKPOINT_CREATED` | New checkpoint was created |
| `REFACTOR_SESSION_INIT` | Refactoring session started |

## Autonomous Actions

### On Trigger Detection

```
1. [AUTO] Log: "Session autosave triggered by: {marker}"
2. [AUTO] Execute: /sessionwrite
3. [AUTO] Verify: session-current.md updated
4. [AUTO] Update: Checkpoint registry (if applicable)
5. [AUTO] Log: "Session saved: {session-file}"
```

### Checkpoint Registry Update

When a checkpoint is involved, also update the session file:

```markdown
## Checkpoint Registry
| ID | Timestamp | Status | Files Changed |
|----|-----------|--------|---------------|
| checkpoint-000 | 2026-01-01T15:00:00 | superseded | - |
| checkpoint-001 | 2026-01-01T15:30:00 | active | src/handlers/* |
```

## Session Template Extension

The autosave adds refactoring-specific fields to the session:

```markdown
# Session Continuation Record

## Session Info
- Date: {current_date}
- Project: SD003
- Branch: {current_branch}
- Latest Commit: {commit_hash}
- **Session Type**: Refactoring
- **Refactor Scope**: {scope_description}

## Refactoring Progress
### Completed Batches
- [x] Batch A: {files} ({count} files)
- [x] Batch B: {files} ({count} files)

### Current Batch
- [ ] Batch C: {files} ({remaining} files remaining)

### Pending Batches
- Batch D: {description}
- Batch E: {description}

## Checkpoint Registry
| ID | Timestamp | Method | Status |
|----|-----------|--------|--------|
| checkpoint-000 | ... | git-stash | superseded |
| checkpoint-001 | ... | git-stash | active |

## Quality Gate Status
| Gate | Status | Details |
|------|--------|---------|
| Lint | PASS | 0 errors |
| Type | PASS | strict mode |
| Test | IN_PROGRESS | 45/50 passing |

## Recovery Instructions
If session interrupted:
1. Run `/sessionread`
2. If tests failing: `/refactor:rollback checkpoint-{latest}`
3. Resume with `/refactor:batch --continue`
```

## Integration Points

### With context-autonomy

Session autosave is always called BEFORE compact/clear:

```
[context-autonomy triggers at 70%]
    |
    v
[session-autosave executes /sessionwrite]  <-- This skill
    |
    v
[context-autonomy executes /compact]
```

### With rollback-guard

Session is saved BEFORE rollback proposal:

```
[rollback-guard detects test failure]
    |
    v
[session-autosave executes /sessionwrite]  <-- This skill
    |
    v
[rollback-guard proposes options to user]
```

### With refactor:batch

After each batch completion:

```
[refactor:batch completes batch N]
    |
    v
[Outputs: REFACTOR_BATCH_N_COMPLETE]
    |
    v
[session-autosave triggers]  <-- This skill
    |
    v
[Continue to batch N+1]
```

## Logging Format

```
[SESSION-AUTOSAVE] {timestamp} - {action}
```

Examples:
```
[SESSION-AUTOSAVE] 2026-01-01T15:30:00 - Triggered by: REFACTOR_BATCH_001_COMPLETE
[SESSION-AUTOSAVE] 2026-01-01T15:30:02 - Session saved: session-20260101-153002.md
[SESSION-AUTOSAVE] 2026-01-01T15:30:03 - Checkpoint registry updated: checkpoint-001 -> active
```

## Error Handling

| Error | Recovery |
|-------|----------|
| sessionwrite fails | Retry once with delay |
| Disk full | Warn user, continue without save |
| Permission denied | Critical - stop and inform user |

## Configuration

In `.sd/refactor/config.json`:

```json
{
  "session_autosave": {
    "enabled": true,
    "triggers": [
      "REFACTOR_BATCH_*_COMPLETE",
      "ALL_TESTS_PASS",
      "LINT_CLEAN",
      "TYPE_CHECK_PASS"
    ],
    "include_checkpoint_registry": true
  }
}
```

## Manual Override

Disable autosave (not recommended):

```json
{
  "session_autosave": {
    "enabled": false
  }
}
```

## Dependencies

- `/sessionwrite` command must be available
- `.sessions/` directory must exist
- `.sd/refactor/checkpoints/` directory for checkpoint registry
