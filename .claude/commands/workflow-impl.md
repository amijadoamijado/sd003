---
description: AI協調ワークフロー - Gemini/Codex実装実行（指示書→実行→復元を一括）
allowed-tools: Bash, Write, Read, Glob, Grep, Edit
---

# 実装実行: /workflow:impl

## 概要
IMPLEMENT_REQUESTに基づきGemini CLIまたはCodex CLIを実行し、結果を検証してコミットする。
**指示書作成だけで止まることを防ぐための仕組み。**

## 使用方法
```
/workflow:impl {案件ID} {タスク番号}              # デフォルト: Gemini CLI
/workflow:impl {案件ID} {タスク番号} --codex      # Codex CLIで実行
```

## 引数
- `案件ID`: 対象案件のID（例: `20260207-002-coverage-fix`）
- `タスク番号`: 実装指示番号（3桁: 001, 002, ...）
- `--codex`: Codex CLIで実行する（省略時はGemini CLI）

## AI選択基準

| 条件 | 推奨AI | 理由 |
|------|--------|------|
| 明確なゴール・局所的な実装 | **Codex** | 一発で高品質な出力 |
| 広範な変更・対話的な調整が必要 | **Gemini** | 既存の実績 |
| Gemini CLIが使えない・制限到達 | **Codex** | フォールバック |

## 前提条件
- IMPLEMENT_REQUEST_{タスク番号}.md が存在すること

## 実行手順（全自動・省略禁止）

### Step 1: 前提チェック

```bash
# 指示書の存在確認
cat .sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md

# CLI存在確認（--codex指定時）
command -v codex >/dev/null 2>&1 || { echo "ERROR: codex CLI not found"; exit 1; }

# CLI存在確認（デフォルト=Gemini時）
command -v gemini >/dev/null 2>&1 || { echo "ERROR: gemini CLI not found"; exit 1; }
```
指示書またはCLIが存在しない場合はエラー終了。

### Step 2: 現在のgit状態を記録
```bash
git stash list
git log --oneline -1
```
未コミットの変更がある場合は警告を表示。

### Step 3: 実装AI実行

引数に `--codex` が含まれるかどうかで分岐する。

#### 3a: Gemini CLI（デフォルト）

```bash
cat .sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md | gemini --yolo -p "上記の実装指示書に従って、全タスクを実装してください。完了後は検証手順に従ってビルド・テスト・ESLintを実行してください。"
```

⚠️ **コマンド順序注意**: `--yolo -p "..."` の順（`-p --yolo`だと`--yolo`がプロンプト値になる）

#### 3b: Codex CLI（--codex指定時）

公式プラグインの `/codex:rescue` で Codex にタスクを委譲する:

```
/codex:rescue implement the changes described in IMPLEMENT_REQUEST_{タスク番号}.md following the acceptance criteria
```

- `/codex:rescue` は Codex サブエージェントにタスクを委譲する公式コマンド
- `--background` で非同期実行可能（`/codex:status` で進捗、`/codex:result` で結果取得）
- Codex が作業ディレクトリから IMPLEMENT_REQUEST を直接読み取る

**フォールバック**: プラグインが利用不可の場合は native CLI で実行:
```bash
codex exec "$(cat .sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md)" 2>/dev/null
```

### Step 4: .sd/ 限定復元
実装AIが`.sd/`の設定ファイルを変更・削除する場合があるため、設定系のみ復元する。
**未コミットのワークフロー文書（ai-coordination/、sessions/）は復元対象外。**

```bash
# 設定系のみ復元（ワークフロー文書・セッション記録は除外）
git checkout -- .sd/specs/ .sd/ralph/ 2>/dev/null || true
```

⚠️ `.sd/ai-coordination/` と `.sessions/` は復元しない（未コミットの依頼書・レビュー結果・セッション記録を保護）

### Step 5: 結果検証
```bash
npx tsc --noEmit
npx jest --no-coverage
```

### Step 6: 変更差分の確認
```bash
git status --short
git diff --stat
```

Geminiが変更したファイルを確認し、対象ファイルのみをステージング。

### Step 7: コミット
```bash
git add {変更ファイル}
git commit -m "{適切なコミットメッセージ}

案件: {案件ID}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Step 8: handoff-log.json 更新
実行結果を記録:
```json
{
  "timestamp": "{現在日時ISO形式}",
  "type": "implement_complete",
  "project_id": "{案件ID}",
  "from": "{Gemini CLI または Codex CLI}",
  "to": "Claude Code",
  "file": "workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md",
  "note": "{実行結果サマリー}"
}
```

### Step 9: Codexレビュー自動実行（省略禁止）
**実装・コミット完了後、必ず `/workflow:review {案件ID} {タスク番号}` を実行する。**
Gemini実装が終わっただけで止まることは禁止。レビュー依頼まで含めて1つのワークフロー。

### Step 10: 完了報告
```
## Gemini実装 → Codexレビュー完了

- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **テスト結果**: {パス数}/{全体数}
- **コミット**: {ハッシュ}
- **.sd/復元**: 完了
- **レビュー判定**: {Approve/Request Changes}
```

## エラー時の対応

| エラー | 対応 |
|--------|------|
| Gemini CLI実行失敗 | コマンド引数順序を確認。`--yolo -p "..."` の順 |
| テスト失敗 | Geminiの変更を`git diff`で確認し、手動修正またはリトライ |
| .sd/ 削除 | `git checkout -- .sd/` で復元 |
| ビルドエラー | `npx tsc --noEmit` のエラーを確認し修正 |

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従ってGemini CLIを実行してください。Step 1からStep 9まで全て実行すること。途中で止まることは禁止。
