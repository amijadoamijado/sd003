---
description: AI協調ワークフロー - Gemini CLI実装実行（指示書→実行→復元を一括）
allowed-tools: Bash, Write, Read, Glob, Grep, Edit
---

# 実装実行: /workflow:impl

## 概要
IMPLEMENT_REQUESTに基づきGemini CLIを実行し、結果を検証してコミットする。
**指示書作成だけで止まることを防ぐための仕組み。**

## 使用方法
```
/workflow:impl {案件ID} {タスク番号}
```

## 引数
- `案件ID`: 対象案件のID（例: `20260207-002-coverage-fix`）
- `タスク番号`: 実装指示番号（3桁: 001, 002, ...）

## 前提条件
- IMPLEMENT_REQUEST_{タスク番号}.md が存在すること

## 実行手順（全自動・省略禁止）

### Step 1: 指示書の存在確認
```bash
cat .kiro/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md
```
存在しない場合はエラー終了。

### Step 2: 現在のgit状態を記録
```bash
git stash list
git log --oneline -1
```
未コミットの変更がある場合は警告を表示。

### Step 3: Gemini CLI実行
**必ずバックグラウンドで実行し、完了を待つ。**

```bash
cat .kiro/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md | gemini --yolo -p "上記の実装指示書に従って、全タスクを実装してください。完了後は検証手順に従ってビルド・テスト・ESLintを実行してください。"
```

⚠️ **コマンド順序注意**: `--yolo -p "..."` の順（`-p --yolo`だと`--yolo`がプロンプト値になる）

### Step 4: .kiro/ 復元
Geminiは`.kiro/`ディレクトリを削除する傾向があるため、必ず復元する。

```bash
git checkout -- .kiro/
```

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
  "from": "Gemini CLI",
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
- **.kiro/復元**: 完了
- **レビュー判定**: {Approve/Request Changes}
```

## エラー時の対応

| エラー | 対応 |
|--------|------|
| Gemini CLI実行失敗 | コマンド引数順序を確認。`--yolo -p "..."` の順 |
| テスト失敗 | Geminiの変更を`git diff`で確認し、手動修正またはリトライ |
| .kiro/ 削除 | `git checkout -- .kiro/` で復元 |
| ビルドエラー | `npx tsc --noEmit` のエラーを確認し修正 |

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従ってGemini CLIを実行してください。Step 1からStep 9まで全て実行すること。途中で止まることは禁止。
