---
slug: refactor-batch
source: .claude/commands/refactor-batch.md
description: Execute refactoring in batched files with auto-checkpoint
claude_command: /refactor:batch
codex_skill: refactor-batch
gemini_file: refactor-batch.toml
allowed_tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite, Skill
---

# /refactor:batch

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Gemini CLI の TOML と Codex の skill はこのファイルから生成します。

## Original Body
# /refactor:batch

自動チェックポイントとセッション永続化でバッチ単位のリファクタリングを実行する。

## Usage

```
/refactor:batch [--continue] [--batch-id {id}]
```

**Arguments:**
- `--continue`: 未完了の最後のバッチから再開
- `--batch-id {id}`: 特定のバッチのみ実行

## Prerequisites

- `/refactor:plan`が正常に完了していること
- バッチマニフェストが`.sd/refactor/plans/{session-id}/batch-manifest.json`に存在すること

## Execution Flow

```
For each batch in manifest:
    |
    v
[1. Pre-batch checkpoint]
    |
    v
[2. Transform files]
    |
    v
[3. Run quality gates (lint, type)]
    |
    v
[4. Run tests via Ralph Loop]
    |
    +---> Pass: Continue to next batch
    |
    +---> Fail: rollback-guard activates
```

## Execution Steps

### Step 1: Load Batch Manifest

```javascript
const manifest = JSON.parse(
  read('.sd/refactor/plans/{session-id}/batch-manifest.json')
);

const currentBatch = manifest.batches.find(b => b.status !== 'completed');
```

### Step 2: Pre-Batch Checkpoint

Before each batch, create checkpoint:

```bash
# Create git stash checkpoint
git stash push -m "refactor-checkpoint-{batch-id}"

# Record checkpoint metadata
```

Write checkpoint JSON:

```json
{
  "id": "checkpoint-{batch-id}",
  "timestamp": "2026-01-01T16:30:00Z",
  "session_id": "refactor-20260101-160000",
  "batch_id": "batch-001",
  "method": "git-stash",
  "stash_ref": "stash@{0}",
  "commit_before": "abc1234",
  "files_to_change": ["src/interfaces/IUser.ts", "src/types/user.ts"]
}
```

Output: `CHECKPOINT_CREATED`

### Step 3: Execute Transformations

For each file in the batch:

1. Read file content
2. Apply refactoring transformation
3. Write modified content
4. Log change

```
Transforming: src/interfaces/IUser.ts
- Line 15: getUserById -> fetchUser
- Line 23: getUserById -> fetchUser
Changes: 2

Transforming: src/types/user.ts
- Line 8: getUserById -> fetchUser
Changes: 1
```

### Step 4: Quality Gates (Per Batch)

Run lint and type checks after transformation:

```bash
# ESLint
npm run lint -- --fix

# TypeScript
npm run typecheck
```

If lint/type fails:
- Attempt auto-fix
- If still failing, trigger rollback-guard

### Step 5: Test Execution (Ralph Loop)

Invoke Ralph Loop for test completion:

```
/sd003:loop-test
```

Wait for:
- `ALL_TESTS_PASS` - Continue to next batch
- Test failure - rollback-guard activates

### Step 6: Batch Completion

On success:

```
REFACTOR_BATCH_{id}_COMPLETE

Batch {id} complete:
- Files modified: 2
- Changes applied: 3
- Tests: PASS
- Time: 3m 45s

Session auto-saved.
Next: Batch {id+1} or /refactor:verify if final
```

Update manifest:

```json
{
  "batches": [
    {
      "id": "batch-001",
      "status": "completed",
      "completed_at": "2026-01-01T16:35:00Z",
      "changes_applied": 3
    }
  ]
}
```

Update TodoWrite:

```
1. [completed] Execute Batch 1: Core interfaces (2 files)
2. [in_progress] Execute Batch 2: Service layer (2 files)
...
```

### Step 7: Continue or Complete

If more batches remain:
- Automatically continue to next batch
- `context-autonomy` skill may trigger compact if needed

If all batches complete:
- Output `REFACTOR_ALL_BATCHES_COMPLETE`
- Suggest `/refactor:verify`

## Output Markers

| Marker | Meaning |
|--------|---------|
| `CHECKPOINT_CREATED` | Pre-batch checkpoint saved |
| `REFACTOR_BATCH_{id}_COMPLETE` | Batch finished successfully |
| `REFACTOR_ALL_BATCHES_COMPLETE` | All batches done |
| `REFACTOR_BATCH_FAILED` | Batch failed, rollback-guard active |

## Skill Integration

### context-autonomy

After each batch completion:
- Checks context usage
- May trigger `/sessionwrite` + `/compact` automatically

### session-autosave

On `REFACTOR_BATCH_{id}_COMPLETE`:
- Automatically runs `/sessionwrite`
- Updates checkpoint registry

### rollback-guard

On test failure:
- Proposes rollback options
- User decides: rollback, manual fix, or escalate

## Transformation Safety

### Before Any Edit

1. Verify file exists
2. Check file is in manifest
3. Confirm no unsaved changes

### During Edit

1. Use Edit tool with exact old_string match
2. For Japanese content: Use Read + Write pattern
3. Log all changes

### After Edit

1. Verify syntax (lint)
2. Verify types (typecheck)
3. Run affected tests

## Error Handling

| Error | Action |
|-------|--------|
| File not found | Skip file, warn user |
| Edit conflict | Retry with fresh read |
| Lint failure | Attempt auto-fix, then rollback-guard |
| Type failure | Rollback-guard proposes options |
| Test failure | Rollback-guard proposes options |

## Resume Capability

If session interrupted:

```
/refactor:batch --continue

Resuming refactoring session: refactor-20260101-160000
Last completed batch: batch-001
Resuming from: batch-002
```

## Context Efficiency

- Uses subagents for file analysis (preserves main context)
- Batches limit file count (prevents context bloat)
- Auto-compact between batches if threshold reached

## Example Session

```
User: /refactor:batch

Claude:
[1/3] Starting Batch 1: Core interfaces

Creating checkpoint: checkpoint-batch-001
CHECKPOINT_CREATED

Transforming src/interfaces/IUser.ts...
- getUserById -> fetchUser (2 occurrences)

Transforming src/types/user.ts...
- getUserById -> fetchUser (1 occurrence)

Running quality gates...
- ESLint: PASS
- TypeScript: PASS

Running tests via Ralph Loop...
ALL_TESTS_PASS

REFACTOR_BATCH_001_COMPLETE
Session auto-saved.

[2/3] Starting Batch 2: Service layer
...
```
