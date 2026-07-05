---
description: Rollback refactoring to a checkpoint
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# /refactor:rollback

リファクタリングの変更を特定のチェックポイントにロールバックする。

## Usage

```
/refactor:rollback [target]
```

**Arguments:**
- `target`: 以下のいずれか:
  - `last` - 直前のチェックポイントに戻す（デフォルト）
  - `checkpoint-{id}` - 特定のチェックポイントに戻す
  - `full` - セッション全体を初期状態に戻す
  - `list` - 利用可能なチェックポイント一覧を表示

## Execution Steps

### Step 1: List Checkpoints (if target = list)

```
Available checkpoints for session: refactor-20260101-160000

| ID | Timestamp | Batch | Files | Status |
|----|-----------|-------|-------|--------|
| checkpoint-000-init | 16:00:00 | - | - | available |
| checkpoint-001 | 16:15:00 | batch-001 | 2 | available |
| checkpoint-002 | 16:30:00 | batch-002 | 2 | current |

Use: /refactor:rollback checkpoint-001
```

### Step 2: Confirm Rollback

AskUserQuestionで確認（提案型、自動実行しない）:

```yaml
Question: "{target}にロールバックしますか？以下の変更が破棄されます: {affected_batches}"
Header: "確認"
Options:
  - label: "はい、ロールバック"
    description: "{target}に復元し、{N}ファイルの変更を破棄"
  - label: "いいえ、キャンセル"
    description: "現在の状態を維持"
  - label: "差分を表示"
    description: "失われる変更内容を表示"
```

### Step 3: Execute Rollback

#### Method: Git Stash Pop

```bash
# Find stash reference
stash_ref=$(cat .sd/refactor/checkpoints/{session-id}/{target}.json | jq -r '.stash_ref')

# Pop the stash
git stash pop $stash_ref
```

#### Method: Git Reset

```bash
# Find commit before changes
commit=$(cat .sd/refactor/checkpoints/{session-id}/{target}.json | jq -r '.commit_before')

# Hard reset
git reset --hard $commit
```

#### Method: Full Reset

```bash
# Reset to initial checkpoint
initial=$(cat .sd/refactor/checkpoints/{session-id}/checkpoint-000-init.json | jq -r '.commit_before')
git reset --hard $initial
```

### Step 4: Update State

After successful rollback:

1. Update batch manifest:

```json
{
  "batches": [
    {"id": "batch-001", "status": "rolled_back"},
    {"id": "batch-002", "status": "pending"}
  ]
}
```

2. Update session:

```bash
# Save new state
/sessionwrite
```

3. Log action:

```
[ROLLBACK] 2026-01-01T16:45:00 - Rolled back to checkpoint-001
[ROLLBACK] Discarded: batch-002 (2 files)
[ROLLBACK] Current state: After batch-001 completion
```

### Step 5: Next Steps

Output guidance:

```
REFACTOR_ROLLBACK_COMPLETE

Rolled back to: checkpoint-001
Discarded batches: batch-002
Current state: After batch-001 completion

Next options:
1. /refactor:batch --continue  (retry from batch-002)
2. /refactor:batch --batch-id batch-002  (retry specific batch)
3. /dialogue-resolution {issue}  (structured problem solving)
4. /refactor:complete --partial  (end with partial completion)
```

## Rollback Targets

| Target | Effect |
|--------|--------|
| `last` | Undo most recent batch only |
| `checkpoint-{id}` | Restore to specific checkpoint |
| `full` | Discard all session changes |

## Safety Checks

Before rollback:

1. **Verify checkpoint exists**
   ```bash
   test -f .sd/refactor/checkpoints/{session-id}/{target}.json
   ```

2. **Check git status**
   ```bash
   git status --porcelain
   # Warn if uncommitted changes exist
   ```

3. **Preserve current state**
   ```bash
   # Create emergency backup before rollback
   git stash push -m "pre-rollback-emergency-backup"
   ```

## Error Handling

| Error | Action |
|-------|--------|
| Checkpoint not found | List available checkpoints |
| Stash conflict | Offer merge or force options |
| Uncommitted changes | Warn, offer to stash first |
| Git error | Show error, suggest manual recovery |

## Recovery from Failed Rollback

If rollback itself fails:

```
Rollback failed: {error}

Recovery options:
1. git stash list  (check stash state)
2. git reflog  (find previous commits)
3. Emergency backup available: pre-rollback-emergency-backup

Manual recovery:
git stash pop stash@{N}  # or
git reset --hard {commit}
```

## Example Usage

### Rollback Last Batch

```
User: /refactor:rollback last

Claude:
Rollback to checkpoint-002?
This will discard: batch-003 (2 files)
- src/handlers/user-handler.ts
- src/handlers/api-handler.ts

[User confirms]

Executing rollback...
git reset --hard abc1234

REFACTOR_ROLLBACK_COMPLETE
Rolled back to: checkpoint-002
```

### List and Choose

```
User: /refactor:rollback list

Claude:
Available checkpoints:
| ID | Timestamp | Batch | Files |
|----|-----------|-------|-------|
| checkpoint-000-init | 16:00 | - | - |
| checkpoint-001 | 16:15 | batch-001 | 2 |
| checkpoint-002 | 16:30 | batch-002 | 2 |

User: /refactor:rollback checkpoint-001

Claude:
Rollback to checkpoint-001?
This will discard: batch-002, batch-003 (4 files total)
...
```

## Output Markers

| Marker | Meaning |
|--------|---------|
| `REFACTOR_ROLLBACK_COMPLETE` | Rollback successful |
| `REFACTOR_ROLLBACK_FAILED` | Rollback failed |
| `REFACTOR_ROLLBACK_CANCELLED` | User cancelled |
