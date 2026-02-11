# Nightly Queue

> 夜間自律実行キュー（テンプレート）

## メタ情報

| 項目 | 値 |
|------|-----|
| 作成日 | YYYY-MM-DD |
| 実行予定 | YYYY-MM-DD 23:00 |
| 最大反復 | 60 |
| 最終完了マーカー | RALPH_NIGHTLY_COMPLETE |

## 実行設定

```yaml
ralph_config:
  max_iterations: 60
  completion_promise: "RALPH_NIGHTLY_COMPLETE"
  blocked_promise: "RALPH_NIGHTLY_BLOCKED"
  timeout_behavior: "log_and_continue"
  git_commit_frequency: "per_task"
  quality_gates:
    - "npm run build"
    - "npm test"
    - "npm run lint"
```

## 実行キュー

### [P1] タスク名（優先度最高）

優先度: 最高
推定反復: 20-25
推定時間: 1.5-2時間

#### 仕様参照
- requirements: .kiro/specs/{feature}/requirements.md
- design: .kiro/specs/{feature}/design.md
- tasks: .kiro/specs/{feature}/tasks.md

#### 対象タスク
- [ ] #1: タスク詳細1
- [ ] #2: タスク詳細2

#### 完了条件
- 全タスクのチェックボックス完了
- npm test 通過
- カバレッジ 80%以上

#### 完了マーカー
<promise>RALPH_TASK1_DONE</promise>

#### 依存関係
- 前提: なし
- 後続: [P2] タスク

---

### [P2] タスク名（優先度高）

優先度: 高
推定反復: 15-20
推定時間: 1-1.5時間

#### 対象タスク
- [ ] #1: タスク詳細

#### 完了条件
- npm test 通過

#### 完了マーカー
<promise>RALPH_TASK2_DONE</promise>

---

## 行き詰まり時の指示

### 50反復到達時
1. 現在の進捗状況を記録
2. ログファイルに出力: `.kiro/ralph/logs/{date}-blocked.md`
3. 終了マーカー出力: `<promise>RALPH_NIGHTLY_BLOCKED</promise>`

### 特定タスクで3回失敗時（Pattern 7）
- そのタスクをスキップ
- スキップ理由をログに記録
- 次のタスクへ進む

### 品質ゲート失敗時
- エラー内容を分析
- 自動修正を試行（最大3回）
- 修正不可の場合はログに記録して次へ

---

## 朝の確認チェックリスト

### 必須確認
- [ ] git log でコミット履歴確認
- [ ] 各完了マーカーの出力確認
- [ ] npm run build 成功
- [ ] npm test 成功
- [ ] npm run lint エラー0

### 成果物確認
- [ ] 新規作成ファイルの確認
- [ ] 変更ファイルのdiff確認
- [ ] テストカバレッジレポート確認

---

## 履歴

| 日付 | 結果 | 完了タスク | 備考 |
|------|------|-----------|------|
| - | - | - | - |
