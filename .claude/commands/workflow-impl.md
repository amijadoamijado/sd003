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

### Step 5: 結果検証（非ブロッキング連続実行ゾーン・柱4）

> **原則**: Step 5a〜5e は AI が連続実行する。ユーザー待ちは発生しない。
> 任意のステップが失敗した場合、**即停止してユーザーに報告する**（省略禁止）。

#### Step 5a: TypeScript strict 通過
```bash
npx tsc --noEmit
```
失敗 → 停止・報告。成功 → 5b へ。

#### Step 5b: ESLint 0 件
```bash
npm run lint 2>/dev/null || npx eslint . --ext .ts,.tsx,.js,.jsx
```
エラー件数 > 0 → 停止・報告。0 件 → 5c へ。

#### Step 5c: テスト + VTD 通過
```bash
npx jest --no-coverage
npm run test:validate-data 2>/dev/null || true   # スクリプト未整備プロジェクトはskip
```
テスト失敗 or VTD 失敗 → 停止・報告。成功 → 5d へ。

#### Step 5d: dev server 起動 + 疎通（該当stack のみ）

Web Frontend / GAS Web App / その他 UI を持つ案件のみ実施:

```bash
# 例（stack によって変わる）:
# Next.js
npm run dev &
DEV_PID=$!
sleep 5
curl -sf http://localhost:3000 >/dev/null || { kill $DEV_PID; echo "dev server not reachable"; exit 1; }

# GAS: clasp push 後に @HEAD URL に curl
```

CLI ツールやライブラリ等、UI を持たない案件はこのステップをスキップ可（IMPLEMENT_REQUEST Section 2 で「CLI 出力」等を選択した案件）。

#### Step 5e: ブラウザで主要画面疎通 + スクショ取得

IMPLEMENT_REQUEST Section 2 の「確認URL / ファイルパス」にアクセスし、
主要画面をブラウザ（chrome-devtools-mcp / claude-in-chrome / Playwright）で開いてスクリーンショットを取得:

```
保存先: materials/images/{案件ID}/{YYYYMMDD}-{タスク番号}-*.png
```

スクショ取得失敗 → 停止・報告。成功 → Step 6 へ。

---

### Step 6: User Confirmation Gate（ユーザーブロッキング・柱4）⭐ 必須

> **原則**: ここが本ワークフロー唯一のユーザーブロッキング点。
> **省略禁止**。ここで AskUserQuestion を発火し、ユーザーの判断を仰ぐ。

以下をユーザーに提示してから AskUserQuestion を発火:

```
## 画面確認のお願い

- **案件**: {案件ID} / タスク {タスク番号}
- **変更ファイル**: {変更ファイル数} 件
- **確認URL**: {IMPLEMENT_REQUEST Section 2 の URL}
- **スクショ**: materials/images/{案件ID}/{スクショファイル名}

内部検証（5a〜5e）は全通過しました。画面を見て問題なければ Codex レビューに進みます。
```

AskUserQuestion の選択肢:
- **OK、レビューに進む** → Step 7 へ
- **NG、修正が必要**（指摘内容を自由記述） → Step 5 の該当箇所に戻る（3b or 5a-5e の再実行）
- **Escalate**（判断不能） → 停止し、ユーザーと対話

**Confirmation record 保存**（T3 Workflow Stop-Hook 向け）:

```bash
mkdir -p .sd/ai-coordination/workflow/confirmations/{案件ID}
cat > .sd/ai-coordination/workflow/confirmations/{案件ID}/CONFIRM_{タスク番号}.md <<EOF
# User Confirmation Record

- Task: {案件ID}/{タスク番号}
- Timestamp: $(date -Iseconds)
- Screenshot: materials/images/{案件ID}/{スクショ}
- User Decision: {OK / NG / Escalate}
- Notes: {ユーザーからのコメント}
EOF
```

このファイルが存在しない状態で workflow-review を実行すると、将来の T3 Stop-Hook が Approve をブロックする。

---

### Step 7: 変更差分の確認
```bash
git status --short
git diff --stat
```

Geminiが変更したファイルを確認し、対象ファイルのみをステージング。

### Step 8: コミット
```bash
git add {変更ファイル}
git commit -m "{適切なコミットメッセージ}

案件: {案件ID}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Step 9: handoff-log.json 更新
実行結果を記録:
```json
{
  "timestamp": "{現在日時ISO形式}",
  "type": "implement_complete",
  "project_id": "{案件ID}",
  "from": "{Gemini CLI または Codex CLI}",
  "to": "Claude Code",
  "file": "workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md",
  "note": "{実行結果サマリー}",
  "user_confirmation": "{OK / NG / Escalate}",
  "screenshot": "materials/images/{案件ID}/{スクショ}"
}
```

### Step 10: Codexレビュー自動実行（省略禁止）
**Step 6 で OK 判定が記録された場合のみ**、`/workflow:review {案件ID} {タスク番号}` を実行する。
NG/Escalate の場合は Step 5 に戻るか、ユーザーと対話を継続。

### Step 11: 完了報告
```
## Gemini実装 → 画面確認 → Codexレビュー完了

- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **内部検証**: tsc/lint/test/VTD 全通過
- **画面確認**: {OK/NG/Escalate} (user)
- **スクショ**: materials/images/{案件ID}/{ファイル名}
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
