---
name: ralph-wiggum-run
description: Codex equivalent of the SD003 custom command `/ralph-wiggum:run`. Use when the user invokes `/ralph-wiggum:run`, `ralph-wiggum-run`.
---

# /ralph-wiggum:run - Night Mode Execution

この skill は Claude Code の `/ralph-wiggum:run` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Original Command Body
# /ralph-wiggum:run - Night Mode Execution

夜間自律実行キューを実行する。

## Usage

```
/ralph-wiggum:run [options]
```

## Options

| Option | Description |
|--------|-------------|
| `--queue <file>` | 実行するキューファイル（デフォルト: nightly-queue.md） |
| `--max-iterations <n>` | 最大反復数（デフォルト: 60） |
| `--resume` | graceful-exitから再開 |
| `--dry-run` | 実行せずにキュー内容を確認 |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_MAX_ITERATIONS` | 60 | 最大反復数 |
| `RALPH_COMPLETION_PROMISE` | `RALPH_NIGHTLY_COMPLETE` | 全体完了マーカー |
| `RALPH_BLOCKED_PROMISE` | `RALPH_NIGHTLY_BLOCKED` | ブロック時マーカー |

## Execution Flow

```
1. ロック取得 (.sd/ralph/.lock)
     ↓
2. キューファイル読み込み
     ↓
3. タスクループ（優先度順）
   ├── タスク開始
   ├── 品質ゲート実行
   ├── エラー時 → リカバリー戦略
   ├── 完了マーカー出力
   ├── チェックポイント保存
   └── 次のタスクへ
     ↓
4. 完了/ブロック判定
     ↓
5. 朝のレビュー用レポート生成
     ↓
6. ロック解放
```

## Recovery Patterns

| Pattern | Description |
|---------|-------------|
| 1 | Build Error - 型エラー自動修正 |
| 2 | Test Failure - 実装/テスト修正 |
| 3 | Lint Error - --fix + 手動修正 |
| 4 | Infinite Loop - 適応的検知 + スキップ |
| 5 | External Dependency - サーキットブレーカー |
| 6 | Unexpected - graceful-exit |
| 7 | Recovery Exhaustion - スキップ + エスカレーション |

## Output

### 成功時
```
<promise>RALPH_NIGHTLY_COMPLETE</promise>
```

### ブロック時
```
<promise>RALPH_NIGHTLY_BLOCKED</promise>
```

## Files

| File | Purpose |
|------|---------|
| `.sd/ralph/nightly-queue.md` | 実行キュー |
| `.sd/ralph/recovery/checkpoints/` | チェックポイント |
| `.sd/ralph/logs/{date}-*.md` | 実行ログ |
| `.sd/ai-coordination/workflow/review/ralph/` | 朝のレビューレポート |

## Related Commands

- `/ralph-wiggum:status` - 実行状況確認
- `/ralph-wiggum:plan` - 週次計画作成

## Specification

- `.sd/specs/ralph-wiggum/requirements.md`
- `.sd/specs/ralph-wiggum/design.md`

---

**Phase**: Nighttime (Autonomous)
**Completion Promise**: `RALPH_NIGHTLY_COMPLETE` / `RALPH_NIGHTLY_BLOCKED`
