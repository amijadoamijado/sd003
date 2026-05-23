---
name: workflow-test
description: Codex equivalent of the SD003 custom command `/workflow:test`. Use when the user invokes `/workflow:test`, `workflow-test`.
---

# テスト依頼: /workflow:test

この skill は Claude Code の `/workflow:test` を Codex で再現するためのものです。
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
# テスト依頼: /workflow:test

## 概要
Codexレビュー Approve 後、Antigravity に E2Eテストを依頼する。
**review Approve 後に自動で呼ばれる。手動実行も可能。**

## 使用方法
```
/workflow:test {案件ID} {タスク番号}
```

## 引数
- `案件ID`: 対象案件のID
- `タスク番号`: テスト対象の実装指示番号（3桁: 001, 002, ...）

## 前提条件
- IMPLEMENT_REQUEST_{タスク番号}.md が存在すること
- Codexレビューが Approve であること（推奨、強制ではない）

## 実行手順（全自動・省略禁止）

### Step 1: 実装指示・レビュー結果の読み込み
```bash
cat .sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md
cat .sd/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{タスク番号}.md
```
テスト対象のスコープとレビュー結果を把握する。

### Step 2: TEST_REQUEST_{タスク番号}.md 作成
テンプレート `.sd/ai-coordination/workflow/templates/TEST_REQUEST.md` をベースに作成。

保存先: `.sd/ai-coordination/workflow/spec/{案件ID}/TEST_REQUEST_{タスク番号}.md`

内容:
```markdown
# テスト依頼: {タスク名}

## メタデータ
| 項目 | 値 |
|------|-----|
| 案件ID | {案件ID} |
| テスト番号 | {タスク番号} |
| 発行日時 | {現在日時} |
| 発行者 | Claude Code |
| 宛先 | Antigravity |
| 関連実装指示 | ./IMPLEMENT_REQUEST_{タスク番号}.md |
| ステータス | Pending |

## 1. テスト目的
{実装内容に基づくテスト目的}

## 2. 対象環境
{本番/ステージング/ローカル}

## 3. テストケース
{実装指示・レビュー結果から導出したテストケース}

## 4. 証跡要件
{必要なスクリーンショット・動画}

## 5. 判定基準
{成功条件・ブロッカー条件}

## 6. 報告要件
TEST_REPORT_{タスク番号}.md として報告
```

### Step 3: handoff-log.json 更新
```json
{
  "timestamp": "{現在日時ISO形式}",
  "type": "test_request",
  "project_id": "{案件ID}",
  "from": "Claude Code",
  "to": "Antigravity",
  "file": "workflow/spec/{案件ID}/TEST_REQUEST_{タスク番号}.md",
  "note": "{テスト内容の要約}"
}
```

### Step 4: Antigravityディスパッチ試行
Antigravityが利用可能な場合:
- `scripts/agent-test.sh {案件ID} {タスク番号}` を実行
- または手動ディスパッチを案内

Antigravityが不在の場合:
- ステータスを「Pending」として記録
- ユーザーに通知: 「TEST_REQUESTを作成しました。Antigravityでテスト実行してください。」

### Step 5: TEST_REPORT 待機確認
以下のファイルを確認:
```
.sd/ai-coordination/workflow/review/{案件ID}/TEST_REPORT_{タスク番号}.md
```
存在する場合は読み込んで結果を報告する。
存在しない場合はPending状態で完了。

### Step 6: 完了報告
```
## E2Eテスト依頼完了

- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **TEST_REQUEST**: .sd/ai-coordination/workflow/spec/{案件ID}/TEST_REQUEST_{タスク番号}.md
- **ステータス**: {Pending / Dispatched / Completed}

## 次のアクション
{Pending: Antigravityでテスト実行}
{Dispatched: テスト結果待ち}
{Completed: 結果に基づく次アクション}
```

## エラー時の対応

| エラー | 原因 | 対応 |
|--------|------|------|
| IMPLEMENT_REQUEST未存在 | 実装未実施 | `/workflow:request` → `/workflow:impl` を先に実行 |
| テンプレート未存在 | ディレクトリ欠落 | テンプレートを手動作成 |
| Antigravity不在 | 環境未構築 | Pending記録、手動テストを案内 |
| handoff-log.json 書き込み失敗 | パーミッション | ディレクトリ確認・作成 |

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従ってテスト依頼を実行してください。Step 1からStep 6まで全て実行すること。途中で止まることは禁止。
