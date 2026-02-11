# Skip and Continue

タスク {task_id} を解決できませんでした。
このタスクをスキップして次へ進みます。

## スキップ理由の記録

以下の形式でスキップ理由を記録してください:

```markdown
## Skipped Task Report

- **Task ID**: {task_id}
- **Attempts**: 3
- **Last Error**: {error}
- **Patterns Tried**: [1, 2, ...]
- **Recommended Action**:
  - [ ] 手動対応が必要
  - [ ] 設計見直しが必要
  - [ ] 外部依存の確認が必要
```

## 記録先

`.kiro/ralph/logs/{date}-blocked.md` に追記

## 次のアクション

1. 上記レポートを記録
2. チェックポイント保存
3. 次のタスク {next_task_id} に進む

## エスカレーション

Pattern 7（リカバリー試行過多）に該当する場合:
- `escalate: true` フラグを設定
- 朝のレビューで手動確認が必要
