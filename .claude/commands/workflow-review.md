---
description: AI協調ワークフロー - Codexレビュー依頼作成・実行
allowed-tools: Bash, Write, Read, Glob, Grep, Edit
---

# レビュー依頼: /workflow:review

## 概要
Gemini CLI実装完了後、Codexにレビューを依頼する。
**impl完了後に自動で呼ばれる。手動実行も可能。**

## 使用方法
```
/workflow:review {案件ID} {タスク番号}
```

## 引数
- `案件ID`: 対象案件のID
- `タスク番号`: 実装指示番号（3桁: 001, 002, ...）

## 前提条件
- IMPLEMENT_REQUEST_{タスク番号}.md が存在すること
- Gemini CLIによる実装コミットが完了していること

## 実行手順（全自動・省略禁止）

### Step 1: 実装指示の読み込み
```bash
cat .sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md
```
レビュー対象のスコープを把握する。

### Step 2: 実装コミットの差分取得
```bash
git log --oneline -3
git diff HEAD~1 --stat
git diff HEAD~1
```
Geminiが実装した変更内容を取得する。

### Step 3: REVIEW_REQUEST_{タスク番号}.md 作成
保存先: `.sd/ai-coordination/workflow/spec/{案件ID}/REVIEW_REQUEST_{タスク番号}.md`

内容:
```markdown
# レビュー依頼

## 基本情報
- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **実装者**: Gemini CLI
- **レビュアー**: Codex
- **日時**: {現在日時}

## レビュー対象
- **実装指示**: IMPLEMENT_REQUEST_{タスク番号}.md
- **実装コミット**: {コミットハッシュ}
- **変更ファイル**: {ファイル一覧}

## 変更差分
{git diff の内容}

## レビュー観点
1. 実装指示との整合性
2. TypeScript型安全性
3. テストカバレッジ
4. コード品質（ESLint準拠）
5. エラーハンドリング
6. テストデータ品質
   - テストデータに空配列（`[]`）や空オブジェクト使用がないか
   - gas-fakesテストが本番相当のデータで検証しているか
   - `expect(true).toBe(true)` 等の無条件パスがないか
   - `npm run test:validate-data` の実行結果を確認

## 判定基準
- **Approve**: 全観点でOK → Phase 7（テスト）へ
- **Request Changes**: 修正必要 → Phase 6（修正）へ
```

### Step 4: Codex CLI実行
```bash
COMMIT_SHA=$(git rev-parse --short HEAD)
REVIEW_PROMPT=$(cat .sd/ai-coordination/workflow/spec/{案件ID}/REVIEW_REQUEST_{タスク番号}.md)
REVIEW_RESULT=$(codex review --commit "$COMMIT_SHA" "$REVIEW_PROMPT" 2>/dev/null)
```

- `codex review --commit <SHA>` で最新コミットを直接レビュー
- レビュー指示書はコマンド引数として渡すためstdinパイプ不要
- stderr混入・printfの対策不要で手順が簡潔になる

### Step 5: レビュー結果保存
Codexの出力を以下に保存:
```
.sd/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{タスク番号}.md
```

### Step 6: handoff-log.json 更新
```json
{
  "timestamp": "{現在日時ISO形式}",
  "type": "review_complete",
  "project_id": "{案件ID}",
  "from": "Codex",
  "to": "Claude Code",
  "file": "workflow/review/{案件ID}/REVIEW_IMPL_{タスク番号}.md",
  "note": "{Approve/Request Changes}"
}
```

### Step 7: PROJECT_STATUS.md 更新
- Approve → Phase 7（テスト）に進行
- Request Changes → Phase 6（修正対応）に移行

### Step 8: 完了報告
```
## Codexレビュー完了

- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **判定**: {Approve/Request Changes}
- **レビュー結果**: .sd/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{タスク番号}.md

## 次のアクション
{Approveの場合: テストフェーズへ（Step 9で自動連鎖）}
{Request Changesの場合: 修正内容のサマリーと対応方針}
```

### Step 9: 自動連鎖 - Antigravity E2Eテスト（Approve時のみ）

**Approve の場合のみ実行。Request Changes の場合はスキップ。**

レビュー結果が Approve の場合、`/workflow:test {案件ID} {タスク番号}` を自動実行する。
これにより TEST_REQUEST が自動作成され、Antigravity への E2E テスト依頼が発行される。

```
/workflow:test {案件ID} {タスク番号}
```

この自動連鎖により、パイプラインは以下の完全な流れとなる:
```
request → impl → review → test（Approve時）
```

## エラー時の対応

| エラー | 原因 | 対応 |
|--------|------|------|
| Codex CLI未インストール | 未セットアップ | `npm install -g @openai/codex` を案内 |
| `stdin is not a terminal` | 非インタラクティブ環境で `codex review` を直接実行 | `codex review --commit HEAD` や `--uncommitted` を使用 |
| `-p` がprofile扱いになる | v0.98.0で `-p` の意味が変更 | `codex review` ではプロンプトを引数で渡すため不要 |
| `unknown revision` | 旧 `codex --full-auto -p` では差分指定が難しい | `codex review --commit` でコミット差分を指定、`--uncommitted` で作業ツリーを対象 |
| Codex実行失敗（その他） | ネットワーク/API等 | 手動レビューに切り替え |
| レビュー結果が不明瞭 | 出力フォーマット不一致 | Claude Codeが補足レビュー |

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従ってCodexレビューを実行してください。Step 1からStep 9まで全て実行すること。途中で止まることは禁止。
