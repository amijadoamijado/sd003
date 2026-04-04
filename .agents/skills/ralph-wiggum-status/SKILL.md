---
name: ralph-wiggum-status
description: Codex equivalent of the SD003 custom command `/ralph-wiggum:status`. Use when the user invokes `/ralph-wiggum:status`, `ralph-wiggum-status`.
---

# /ralph-wiggum:status - Execution Status

この skill は Claude Code の `/ralph-wiggum:status` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Original Command Body
# /ralph-wiggum:status - Execution Status

夜間実行の状況を確認する。

## Usage

```
/ralph-wiggum:status
```

## Output

### 実行中の場合

```markdown
## Ralph Wiggum Status: RUNNING

| 項目 | 値 |
|------|-----|
| 開始時刻 | 2026-01-04 23:00:00 |
| 現在の反復 | 25/60 |
| 完了タスク | 3/5 |
| 現在のタスク | TASK4 |

### 完了タスク
- [x] RALPH_TASK1_DONE
- [x] RALPH_TASK2_DONE
- [x] RALPH_TASK3_DONE

### 残りタスク
- [ ] TASK4 (in progress)
- [ ] TASK5

### 直近のエラー
- なし

### 品質ゲート状況
- build: pass
- test: pass
- lint: pass
```

### 完了済みの場合

```markdown
## Ralph Wiggum Status: COMPLETE

| 項目 | 値 |
|------|-----|
| 実行時刻 | 2026-01-04 23:00:00 - 03:45:00 |
| 使用反復 | 45/60 |
| 完了タスク | 5/5 |
| 成功率 | 100% |

### 完了マーカー
<promise>RALPH_NIGHTLY_COMPLETE</promise>

### 朝のレビュー
`.sd/ai-coordination/workflow/review/ralph/NIGHTLY_REPORT_20260104.md`
```

### ブロック済みの場合

```markdown
## Ralph Wiggum Status: BLOCKED

| 項目 | 値 |
|------|-----|
| 実行時刻 | 2026-01-04 23:00:00 - 02:30:00 |
| 使用反復 | 50/60 |
| 完了タスク | 3/5 |
| スキップ | 1 |

### ブロック理由
- TASK4: Pattern 7 - Recovery exhaustion

### 推奨アクション
1. `.sd/ralph/logs/20260104-blocked.md` を確認
2. 問題を手動で調査・修正
3. `/ralph-wiggum:run --resume` で再開
```

## Files Checked

- `.sd/ralph/.lock` - 実行ロック
- `.sd/ralph/recovery/checkpoints/latest.json` - 最新チェックポイント
- `.sd/ralph/logs/{date}-*.md` - 実行ログ

## Related Commands

- `/ralph-wiggum:run` - 夜間キュー実行
- `/ralph-wiggum:plan` - 週次計画作成

---

**Phase**: Any (Read-only status check)
