---
description: AI協調ワークフロー - 実装指示（IMPLEMENT_REQUEST）作成
allowed-tools: Bash, Write, Read, Glob, Grep
---

# 実装指示作成: /workflow:request

## 概要
特定タスクの実装指示（IMPLEMENT_REQUEST.md）を作成します。

## 使用方法
```
/workflow:request {案件ID} {タスク番号}
```

## 引数
- `案件ID`: 対象案件のID
- `タスク番号`: WORK_ORDER.md で定義したタスク番号（3桁: 001, 002, ...）

## 前提条件
- WORK_ORDER.md が存在すること
- 発注書レビューが Approve されていること
- 依存タスクが完了していること（該当する場合）

## 実行手順

### 1. 発注書の読み込み
```
.sd/ai-coordination/workflow/spec/{案件ID}/WORK_ORDER.md
```
から該当タスクの詳細を抽出。

### 2. レビュー結果の確認
```
.sd/ai-coordination/workflow/review/{案件ID}/REVIEW_WORK_ORDER.md
```
が存在し、判定が Approve であることを確認。

### 3. 依存タスクの状態確認
WORK_ORDER.md のタスク一覧から依存タスクを特定し、
PROJECT_STATUS.md で完了状態を確認。

### 4. 実装指示の詳細生成（テンプレート駆動・必須欄検証）

テンプレートを**そのままコピー**して具体化:
- **テンプレート実体（正本・tracked）**: `.claude/templates/workflow/IMPLEMENT_REQUEST.md`
- **コピー先（案件ごとの実体）**: `.sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{NNN}.md`

> 注: 以前は `.sd/ai-coordination/workflow/templates/` を正本パスとしていたが、`.sd/` は gitignore 対象（post-commit hook で wipe される）のため、正本を `.claude/templates/workflow/` に移行済み。

**⛔ 重要ルール（柱1〜4 の入口ガードレール）**:
- **Section 0（Quality Prerequisites）は改変・削除禁止**。全 IMPLEMENT_REQUEST に自動挿入される
- **Section 2（ユーザーが見る画面・受け取るもの）は必須**。空の場合は**作成を中止**してユーザーに確認すること
- **Section 7（段取り）のUI-First順序は削除禁止**

#### 4a. stack 検出（必須・自動）

package.json を読み取り以下を判定:
- `dependencies.react` / `next` / `vue` → Web Frontend
- `.claspignore` 存在 or `@types/google-apps-script` → GAS
- `bin` フィールド or entry-point のみ → CLI
- それ以外 → Vanilla or library

検出結果を Section 1 の `stack` 欄に記入。該当時は Section 0.6（GAS 追加項目）をチェック対象として残す。

#### 4b. 必須欄バリデーション（空なら拒否）

以下が空の場合、IMPLEMENT_REQUEST を作成せず、ユーザーに必要情報を確認する:

| Section | 必須内容 | 空の場合の対処 |
|---------|---------|---------------|
| 2. ゴール（ユーザーが見る画面・受け取るもの） | 画面URL、ファイルパス、または stdout 例 | 作成停止、ユーザーに「ユーザーが最終的に見るものは？」と質問 |
| 2. 成果物の種類 | 最低1つチェック | 同上 |
| 3.1 変更可能ファイル | 最低1件 | WORK_ORDER を再確認 |

#### 4c. 項目具体化

以下を具体化:
- **ブランチ名**: `feature/{案件ID}/{タスク番号}-{slug}`
- **変更可能ファイル**: 発注書から特定
- **禁止領域**: フレームワークファイル、仕様書等
- **テストケース**: 発注書のテスト要件から展開（ただし「テストのためのテスト」は書かない）
- **コミット方針**: 標準形式を適用

### 5. IMPLEMENT_REQUEST_{タスク番号}.md 作成
保存先: `.sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md`

### 6. PROJECT_STATUS.md 更新
- フェーズ3（実装指示作成）完了、フェーズ4（実装）へ
- 該当タスクを「進行中」に更新
- タイムラインに記録追加

### 7. handoff-log.json 更新
```json
{
  "handoff_history": [
    {
      "id": "HO-{連番}",
      "project_id": "{案件ID}",
      "from": "Claude Code",
      "to": "Gemini CLI",
      "type": "implement_request",
      "artifact": ".sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md",
      "timestamp": "{現在日時ISO形式}",
      "status": "pending",
      "result": null
    }
  ]
}
```

### 8. Gemini CLI 自動実行（省略禁止）
**指示書作成後、必ず `/workflow:impl {案件ID} {タスク番号}` を実行する。**
指示書を作っただけで止まることは禁止。実装実行まで含めて1つのワークフロー。

### 9. 完了報告
```
## 実装指示作成 → Gemini実行完了

- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **実装指示**: .sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md
- **Gemini実行結果**: {パス/失敗}
- **コミット**: {ハッシュ}
```

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従って実装指示を作成してください。発注書の該当タスクを詳細に展開し、Gemini CLIが迷わず実装できる具体的な指示を作成すること。
