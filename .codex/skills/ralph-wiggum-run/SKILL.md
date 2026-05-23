---
name: ralph-wiggum-run
description: Codex equivalent of the SD003 custom command `/ralph-wiggum:run`. Use when the user invokes `/ralph-wiggum:run`, `ralph-wiggum-run`.
---

# /ralph-wiggum:run - Night Mode Execution

この skill は Claude Code の `/ralph-wiggum:run` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Codex Runtime Rules
- `.claude/commands/**/*.md` はClaude Code側のauthoring sourceです。直接変更せず、CodexではこのSkillを実行仕様として扱います。
- Claude Codeのスラッシュコマンド、`Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Codexの通常手順に翻訳します。
- Codex内で `/codex:review`、`/codex:rescue` などのCodexプラグインコマンドを再帰的に呼ばないでください。必要な読取・差分確認・編集・検証・報告をCodex自身で実施します。
- 人間向け出力、レビュー報告、質問、完了報告は日本語で書きます。
- `.sd/ai-coordination/` に依頼書・報告書を書く場合は、既存の案件ID配下に限定し、プロジェクトルートへ散らさないでください。
- Windows環境ではPowerShellで実行できるコマンドを優先し、bash専用の例はWSLやGit Bashが使える場合だけ採用します。

## Codex Native Execution Contract
このセクションはCodex実行時に `Original Command Body` より優先します。

- Claude Codeのスラッシュコマンド、`/workflow:*`、`/codex:*`、`Agent(...)`、`AskUserQuestion` は文字通り実行しない。
- Codex自身がファイル読取、差分確認、編集、検証、報告を直接行う。
- `.claude/commands/**/*.md` はauthoring sourceとして読むだけにし、Codex改善のために直接編集しない。
- 案件IDがない相談・レビューでは `.sd/ai-coordination/` に報告書を作らず、会話内で完結する。
- `.sd/ai-coordination/` に書くのは、案件IDが明示された正式Workflowの場合だけにする。
- WindowsではPowerShellで実行できるコマンドを優先し、bash例はWSL/Git Bashが使える場合だけ採用する。
- `.sd/` が存在しない場合は、その事実を報告し、可能なら軽量レビューまたは直接実装へ縮退する。

## Original Command Body
# /ralph-wiggum:run - Night Mode Execution

夜間自律実行キューを実行する。

## ⛔ スコープ制限（柱4 Segmented Sequencing）

> **夜間モードは「非ブロッキングタスクのみ」実行する。**
> 夜中にユーザー確認できないため、UI変更を含む案件や User Confirmation Gate が必要な案件はキューから拒否される。

### 夜間実行 OK（非ブロッキング）

| タスク種別 | 例 |
|-----------|-----|
| 内部リファクタ | 型修正、命名統一、未使用コード削除 |
| 依存更新 | npm audit fix、バージョン更新 |
| ドキュメント生成 | 既存コードからのコメント抽出 |
| テスト修正 | 既に実データで再現済みのバグに対する最小テスト追加 |
| ESLint 自動修正 | `eslint --fix` |

### 夜間実行 NG（ユーザー確認必須）

| タスク種別 | 理由 |
|-----------|------|
| UI実装・UI変更 | User Confirmation Gate が必須（柱1 + 柱4）。夜中に確認不能 |
| 設計判断を含む変更 | ユーザー承認必須 |
| 外部サービス連携の新規追加 | 本番影響確認必須 |
| デプロイ | 本番反映はユーザー承認必須 |

これらは日中の `/workflow:impl` 経由で実行する。

### キュー受理時のチェック

`nightly-queue.md` のタスクエントリに以下のいずれかがある場合、**キュー拒否**:

- `type: ui-change`
- `requires_user_confirmation: true`
- `deploy: true`
- `IMPLEMENT_REQUEST Section 2` に「画面」が含まれる案件

朝のレビューで:
- 夜間完了 → そのままコミット済み
- 未完了（UI含むためスキップ） → 日中実行タスクとして引き継ぎ

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
- `.sd/specs/ralph-wiggum/spec.md`

---

**Phase**: Nighttime (Autonomous)
**Completion Promise**: `RALPH_NIGHTLY_COMPLETE` / `RALPH_NIGHTLY_BLOCKED`
