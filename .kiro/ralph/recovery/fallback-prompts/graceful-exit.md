# Graceful Exit

予期しないエラーにより継続が困難です。
安全に終了するため、以下を実行してください。

## 終了手順

### 1. 現在の作業内容をコミット

```bash
git add -A
git commit -m "WIP: Ralph Wiggum graceful exit - {timestamp}"
```

### 2. チェックポイント保存

```json
{
  "version": "1.1",
  "timestamp": "{now}",
  "reason": "graceful-exit",
  "canResume": true,
  "lastSuccessfulTask": "{task_id}",
  "remainingTasks": [...],
  "gitState": {
    "commit_hash": "{hash}",
    "uncommitted_changes": false
  }
}
```

保存先: `.kiro/ralph/recovery/checkpoints/graceful-exit-{timestamp}.json`

### 3. エラーログ出力

```markdown
## Graceful Exit Report

- **Timestamp**: {now}
- **Last successful task**: {task_id}
- **Error type**: Unexpected
- **Details**: {error_details}
- **Stack trace**: {stack_trace}

## Recovery Instructions

1. 確認: `.kiro/ralph/recovery/checkpoints/graceful-exit-{timestamp}.json`
2. 問題調査: {suggested_investigation}
3. 再開: `/ralph-wiggum:run --resume`
```

保存先: `.kiro/ralph/logs/{date}-graceful-exit.md`

### 4. 終了マーカー出力

```
<promise>RALPH_NIGHTLY_BLOCKED</promise>
```

## 再開方法

朝の確認後、問題を解決したら:

```
/ralph-wiggum:run --resume
```

これにより、graceful-exitのチェックポイントから再開します。
