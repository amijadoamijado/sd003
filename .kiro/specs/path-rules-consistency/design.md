# Path Rules Consistency - Technical Design

## Architecture

### 階層構造

```
RULES.md (Single Source of Truth - 正規定義)
    │
    ├── CLAUDE.md (Claude Code - 参照 + 全パスルール)
    ├── AGENTS.md (Codex - 参照 + 全パスルール)
    └── gemini.md (Gemini CLI - 参照 + 関連パスルール)
```

### 設計方針

1. **RULES.md が正規定義**: 全パスルールの唯一の真実
2. **各AI設定は参照**: `MUST READ: .handoff/RULES.md` + パスルールテーブル（冗長だが明示的）
3. **テンプレートで展開**: deploy時にプレースホルダーを置換して生成

## パスルール定義（全カテゴリ）

### 仕様書

| ファイル | 保存先 |
|---------|--------|
| 要件定義書 | `.kiro/specs/{feature}/requirements.md` |
| 技術設計書 | `.kiro/specs/{feature}/design.md` |
| タスクリスト | `.kiro/specs/{feature}/tasks.md` |

### AI協調ワークフロー

| ファイル種別 | 保存先 |
|-------------|--------|
| 発注書 | `.kiro/ai-coordination/workflow/spec/{projectID}/WORK_ORDER.md` |
| 実装指示 | `.kiro/ai-coordination/workflow/spec/{projectID}/IMPLEMENT_REQUEST_{NNN}.md` |
| テスト依頼 | `.kiro/ai-coordination/workflow/spec/{projectID}/TEST_REQUEST_{NNN}.md` |
| レビュー結果 | `.kiro/ai-coordination/workflow/review/{projectID}/REVIEW_{type}_{NNN}.md` |
| テスト報告 | `.kiro/ai-coordination/workflow/review/{projectID}/TEST_REPORT_{NNN}.md` |

### セッション

| ファイル | 保存先 |
|---------|--------|
| 現在セッション | `.kiro/sessions/session-current.md` |
| タイムライン | `.kiro/sessions/TIMELINE.md` |
| セッション履歴 | `.kiro/sessions/session-YYYYMMDD-HHMMSS.md` |

### 配置禁止

- プロジェクトルート直下への新規ファイル作成
- `.antigravity/` への依頼書作成
- テンプレートなしの依頼書作成

## テンプレート設計

### プレースホルダー

| プレースホルダー | 説明 |
|-----------------|------|
| `{{PROJECT_NAME}}` | プロジェクト名 |
| `{{DATE}}` | 導入日（YYYY-MM-DD） |

### 共通セクション（全テンプレートに追加）

```markdown
## Common Rules

**MUST READ**: `.handoff/RULES.md`

## File Location Rules

| カテゴリ | ファイル | 保存先 |
|---------|---------|--------|
| 仕様書 | requirements.md | `.kiro/specs/{feature}/` |
| 仕様書 | design.md | `.kiro/specs/{feature}/` |
| 仕様書 | tasks.md | `.kiro/specs/{feature}/` |
| ワークフロー | WORK_ORDER.md | `.kiro/ai-coordination/workflow/spec/{projectID}/` |
| ワークフロー | IMPLEMENT_REQUEST | `.kiro/ai-coordination/workflow/spec/{projectID}/` |
| ワークフロー | TEST_REQUEST | `.kiro/ai-coordination/workflow/spec/{projectID}/` |
| ワークフロー | REVIEW | `.kiro/ai-coordination/workflow/review/{projectID}/` |
| ワークフロー | TEST_REPORT | `.kiro/ai-coordination/workflow/review/{projectID}/` |
| セッション | session-current.md | `.kiro/sessions/` |
| セッション | TIMELINE.md | `.kiro/sessions/` |
```

## 修正対象ファイル

| # | ファイル | 操作 |
|---|---------|------|
| 1 | `.handoff/RULES.md` | 更新: v2.0（パスルール追加） |
| 2 | `templates/AGENTS.md.template` | 新規: Codex用テンプレート |
| 3 | `templates/CLAUDE.md.template` | 更新: パスルール追加 |
| 4 | `templates/gemini.md.template` | 更新: パスルール追加 |
| 5 | `kiro-deploy/README.md` | 更新: AGENTS.md生成ステップ追加 |

---
Created: 2026-02-15
