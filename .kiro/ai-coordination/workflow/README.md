# AI協調ワークフロー

## 概要
Claude Code（計画・工程管理）、Codex（レビュー）、Gemini CLI（実装）、Antigravity（E2Eテスト）の役割分担による相互チェック機構。

## 対応AI

| AI | 役割 | コマンド |
|----|------|---------|
| Claude Code | 計画・工程管理 | `/workflow:init`, `/workflow:order`, `/workflow:request`, `/workflow:test`, `/workflow:status` |
| Codex | レビュー・チェック | `/workflow:review`（自動連鎖） |
| Gemini CLI | 実装 | `/workflow:impl`（自動連鎖） |
| Antigravity | E2Eテスト・探索的調査 | `/workflow:test`（自動連鎖） |

## ディレクトリ構造

```
.kiro/ai-coordination/workflow/
├── README.md                 # このファイル
├── CODEX_GUIDE.md           # Codexレビュー運用ガイド
├── ANTIGRAVITY_GUIDE.md     # Antigravityテスト運用ガイド
├── templates/               # テンプレート
│   ├── WORK_ORDER.md        # 発注書テンプレート
│   ├── IMPLEMENT_REQUEST.md # 実装指示テンプレート
│   ├── REVIEW_REPORT.md     # レビュー結果テンプレート
│   ├── PROJECT_STATUS.md    # 工程ログテンプレート
│   ├── TEST_REQUEST.md      # テスト依頼テンプレート
│   └── TEST_REPORT.md       # テスト報告テンプレート
├── spec/                    # 案件別発注書・実装指示・テスト依頼
│   └── {案件ID}/
│       ├── WORK_ORDER.md
│       ├── IMPLEMENT_REQUEST_XXX.md
│       └── TEST_REQUEST_XXX.md
├── review/                  # 案件別レビュー結果・テスト報告
│   └── {案件ID}/
│       ├── REVIEW_WORK_ORDER.md
│       ├── REVIEW_IMPL_XXX.md
│       └── TEST_REPORT_XXX.md
└── log/                     # 案件別工程ログ
    └── {案件ID}/
        └── PROJECT_STATUS.md
```

## 運用フロー（8段階）

```
Phase 1: 発注書作成 (Claude Code)
    │ /workflow:order {案件ID}
    ▼
Phase 2: 発注書レビュー (Codex)
    │ 手動: CODEX_GUIDE.md参照
    ▼ Approve
Phase 3: 実装指示作成 (Claude Code)
    │ /workflow:request {案件ID} {タスク番号}
    ▼
Phase 4: 実装 (Gemini CLI)
    │ /workflow:impl {案件ID} {タスク番号}
    ▼
Phase 5: 実装レビュー (Codex)
    │ 手動: CODEX_GUIDE.md参照
    ▼ Approve / Request Changes → Phase 6
Phase 6: 修正対応 (Gemini CLI)
    │ 修正commit → Phase 5へ戻る
    ▼ Approve
Phase 7: E2Eテスト (Antigravity)
    │ /workflow:test {案件ID} {タスク番号}
    ▼ Pass
Phase 8: 工程完了 (Claude Code)
    │ /workflow:status {案件ID} --update
    ▼
    次タスクへ or 案件完了
```

## 命名規則

| 要素 | 規則 | 例 |
|------|------|-----|
| 案件ID | `YYYYMMDD-NNN-slug` | `20251230-001-auth` |
| 発注書 | `WORK_ORDER.md` | 固定 |
| 実装指示 | `IMPLEMENT_REQUEST_NNN.md` | `IMPLEMENT_REQUEST_001.md` |
| テスト依頼 | `TEST_REQUEST_NNN.md` | `TEST_REQUEST_001.md` |
| レビュー結果 | `REVIEW_{種別}_NNN.md` | `REVIEW_IMPL_001.md` |
| テスト報告 | `TEST_REPORT_NNN.md` | `TEST_REPORT_001.md` |
| 工程ログ | `PROJECT_STATUS.md` | 固定 |

## クイックスタート

### 1. 案件初期化
```bash
/workflow:init auth-feature
# → 案件ID: 20251230-001-auth-feature が生成される
```

### 2. 発注書作成
```bash
/workflow:order 20251230-001-auth-feature
# → spec/{案件ID}/WORK_ORDER.md が生成される
```

### 3. Codexに発注書レビュー依頼（手動）
CODEX_GUIDE.md の「発注書レビュー」セクション参照

### 4. 実装指示作成
```bash
/workflow:request 20251230-001-auth-feature 001
# → spec/{案件ID}/IMPLEMENT_REQUEST_001.md が生成される
```

### 5. Gemini CLIで実装
```bash
/workflow:impl 20251230-001-auth-feature 001
```

### 6. Codexに実装レビュー依頼（手動）
CODEX_GUIDE.md の「実装レビュー」セクション参照

### 7. E2Eテスト依頼
```bash
/workflow:test 20251230-001-auth-feature 001
# → spec/{案件ID}/TEST_REQUEST_001.md が生成される
```

### 8. 工程状況確認
```bash
/workflow:status 20251230-001-auth-feature
```

## 自動連鎖ルール

コマンド間の自動連鎖は仕組みとして強制される。

| トリガー | 自動実行 | 説明 |
|---------|---------|------|
| `/workflow:request` 完了 | → `/workflow:impl` | 実装指示後、Gemini実行は必須 |
| `/workflow:impl` 完了 | → `/workflow:review` | 実装後、Codexレビューは必須 |
| `/workflow:review` Approve | → `/workflow:test` | Approve時、Antigravityテスト依頼は必須 |

## 品質基準との統合

このワークフローは SD003 の 8段階品質ゲートと統合されています：

| Phase | 関連品質ゲート |
|-------|--------------|
| Phase 4（実装） | Gate 1-5（構文、型、リント、セキュリティ、テスト） |
| Phase 5（レビュー） | Gate 4-7（セキュリティ、テスト、パフォーマンス、ドキュメント） |
| Phase 7（E2Eテスト） | Gate 8（統合検証） |

## Non-Interactive Agent Pipeline（パイプ実行）

### 概要
Gemini CLIの非インタラクティブモード（パイプ入力）を活用し、
IMPLEMENT_REQUESTを自動で実装させるスクリプト群。

### スクリプト

| Script | 役割 | 実行方法 |
|--------|------|---------|
| `scripts/agent-implement.sh` | Gemini CLIへの実装依頼（単体） | パイプ実行 |
| `scripts/agent-test.sh` | Antigravity E2Eテスト（単体） | パイプ実行 |
| `scripts/agent-pipeline.sh` | 4-Agent統合パイプライン | 順次パイプ |

### Pipeline フロー

```
Phase 3: 実装指示作成 (Claude Code)
    │ /workflow:request {案件ID} {タスク番号}
    ▼
Phase 4a: 自動実装 (Gemini CLI - パイプ)
    │ scripts/agent-implement.sh {案件ID} {タスク番号}
    │   → echo "IMPLEMENT_REQUEST内容" | gemini
    ▼
Phase 4b: コード適用 & コミット
    │ 出力ファイルからコードを適用、git commit
    ▼
Phase 5a: 自動レビュー (Codex - パイプ)
    │ scripts/agent-pipeline.sh --skip-review なしで実行
    │   → echo "レビュー依頼" | codex
    ▼
Phase 5b: 判断 (Claude Code)
    │ レビュー結果を読んで Approve / Request Changes
    ▼ Approve
Phase 6a: E2Eテスト依頼 (Claude Code)
    │ /workflow:test {案件ID} {タスク番号}
    │   → TEST_REQUEST自動作成
    ▼
Phase 6b: E2Eテスト実行 (Antigravity)
    │ scripts/agent-test.sh {案件ID} {タスク番号}
    │   → TEST_REPORT作成
    ▼
Phase 6c: テスト結果判断 (Claude Code)
    │ Pass → 次タスクへ / Fail → 修正対応
    ▼
    次タスクへ or 修正対応
```

### 使い方

```bash
# 単体: Gemini実装のみ
./scripts/agent-implement.sh 20260101-001-auth 001

# 統合: 実装 + レビュー + テスト（4-Agent）
./scripts/agent-pipeline.sh 20260101-001-auth 001

# テストスキップ
./scripts/agent-pipeline.sh 20260101-001-auth 001 --skip-test

# プレビュー（実行なし）
./scripts/agent-pipeline.sh 20260101-001-auth 001 --dry-run
```

### 出力ファイル

| ファイル | 保存先 |
|---------|--------|
| Gemini実装出力 | `workflow/log/{案件ID}/gemini-output-{NNN}.md` |
| Codexレビュー結果 | `workflow/review/{案件ID}/REVIEW_IMPL_{NNN}.md` |
| テスト依頼 | `workflow/spec/{案件ID}/TEST_REQUEST_{NNN}.md` |
| テスト報告 | `workflow/review/{案件ID}/TEST_REPORT_{NNN}.md` |
| パイプラインログ | `workflow/log/{案件ID}/pipeline-{NNN}.log` |

---

## 関連ドキュメント

- `docs/quality-gates.md` - 8段階品質ゲート詳細
- `.kiro/sessions/` - セッション管理
- `.kiro/specs/` - 仕様書駆動開発
- `GEMINI.md` - Gemini CLI設定・パイプ実行ガイド
- `ANTIGRAVITY_GUIDE.md` - Antigravityテスト運用ガイド

---
最終更新: 2026-02-15
