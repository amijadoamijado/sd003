# SD003 Framework - AI Development Command Center

## Project Memory

**Session Start**: Run `/sessionread` (reads all 4 files automatically)

| Order | File | Purpose |
|-------|------|---------|
| 1 | `D:\claudecode\CLAUDE.md` | Global settings (UTF-8 constraints) |
| 2 | `./CLAUDE.md` | Project settings (SD003 rules) |
| 3 | `.kiro/sessions/session-current.md` | Current session (short-term) |
| 4 | `.kiro/sessions/TIMELINE.md` | Project history (long-term) |

**Crash Recovery**: `claude --continue` + `/sessionread`

---

## Common Rules

**ALL AI MODELS MUST FOLLOW**: `.handoff/RULES.md`

このファイルは、全AIモデル（Claude Code、Codex、Gemini CLI、Antigravity）に共通の開発作法を定義します。

| 内容 | 場所 |
|------|------|
| 共通ルール | `.handoff/RULES.md` |
| タスク指示テンプレート | `.handoff/ORDER.template.md` |
| 完了報告テンプレート | `.handoff/DONE.template.md` |

## Handoff Pack（引き継ぎパック）

作業終了時は、必ず **DONE.md** を出力してください。

```bash
# 作業完了時
cp .handoff/DONE.template.md .handoff/DONE.md
# 内容を埋めて保存
```

モデルを切り替える場合は、前のDONE.mdを次のモデルに渡してください。

---

## Overview
SD003: Spec-Driven Development framework integrating SD001 and GA001.

**Tech Stack**: TypeScript (strict) + Google Apps Script + Env Interface Pattern

---

## AI Coordination Workflow (MANDATORY)

**Detailed rules: `.claude/rules/workflow/ai-coordination.md`**

### Claude Code's Role
| Role | Description |
|------|-------------|
| Planning | Work order creation, task breakdown |
| Coordination | Dispatch requests to other AIs |
| Status | Track project progress |

### Trigger Keywords (AUTO-EXECUTE)

| Keyword | Action |
|---------|--------|
| "...to Antigravity", "test request" | Create TEST_REQUEST |
| "...to Gemini", "implement" | Create IMPLEMENT_REQUEST |
| "...to Codex", "review" | Create review request |
| "work order", "create order" | Create WORK_ORDER |

### Japanese Triggers

| Keyword | Action |
|---------|--------|
| "Antigravityに依頼", "テストを依頼" | Create TEST_REQUEST |
| "Geminiに依頼", "実装を依頼" | Create IMPLEMENT_REQUEST |
| "指示書を作成", "作業指示" | Create request document |

### File Location Rules

**ALL documents in `.kiro/ai-coordination/`**

| Type | Location |
|------|----------|
| Requests | `workflow/spec/{projectID}/` |
| Reports | `workflow/review/{projectID}/` |
| Templates | `workflow/templates/` |

**PROHIBITED**: Creating in `.antigravity/` or project root

---

## Basic Commands

### Build & Test
```bash
npm run build && npm test && npm run lint
npm run test:gas-fakes   # Tier-2 gas-fakes tests only
```

### Spec-Driven Development
```
/kiro:spec-init {feature}
/kiro:spec-requirements {feature}
/kiro:spec-design {feature}
/kiro:spec-tasks {feature}
/kiro:spec-impl {feature}
```

### AI Coordination
```
/workflow:init {slug}
/workflow:order {projectID}
/workflow:request {projectID} {num}    # → impl → review → test 自動連鎖
/workflow:impl {projectID} {num}       # → review → test 自動連鎖
/workflow:review {projectID} {num}     # → test 自動連鎖（Approve時）
/workflow:test {projectID} {num}       # Antigravity E2Eテスト依頼
/workflow:status {projectID}
```

### Ralph Loop (Daytime)
```
/sd003:loop-test    # Test completion loop
/sd003:loop-lint    # ESLint completion loop
/sd003:loop-type    # TypeScript type-check loop
```

### Ralph Wiggum (Nighttime)
```
/ralph-wiggum:run     # Execute nightly queue
/ralph-wiggum:status  # Check execution status
/ralph-wiggum:plan    # Create weekly plan
```

---

## Critical Rules

**Required Settings** (`.claude/settings.local.json`):
```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  }
}
```

**Required**:
- `ENABLE_TOOL_SEARCH=true` (MCP最適化、トークン85%削減)
- GAS API via Env Interface only
- Test coverage 80%+
- ESLint errors = 0
- TypeScript strict mode

**Prohibited**:
- Node.js APIs (`fs`, `path`, `process`)
- Unauthorized spec changes
- Creating requests outside `.kiro/ai-coordination/`
- **テストのためのテスト（本番エラー発見以外の目的のテスト）**
  - テストの唯一の目的は「本番環境のエラーを発見し修正すること」
  - モックデータ・ダミーデータ・空データでの検証は禁止
  - フォールバック付きテスト（失敗時にスキップ/デフォルト値で通過）は禁止
  - カバレッジ数値のためだけのテストは禁止
  - 本番データ（またはそのコピー）で検証すること
  - 詳細: `.claude/rules/testing/testing-standards.md`
- **フロントエンドをユーザーに見せずに次に進む**
  - UI実装後は必ずユーザーに画面を見せて確認を取る
  - ユーザー確認なしでバックエンド統合やデプロイに進むことは禁止
  - 「動くはず」ではなく「実際に見せて確認」が必須

---

## Skills Ecosystem

SD003は [skills.sh](https://skills.sh/) エコシステムと連携し、58,000+のオープンスキルを検索・インストール可能。

### コマンド
```
/skills:find {query}    # スキル検索
/skills:add {owner/repo} [--skill name]  # スキルインストール
/skills:list            # インストール済み一覧
```

### スキル信頼ポリシー

| 信頼レベル | ソース | 扱い |
|-----------|--------|------|
| **Trusted** | `anthropics/skills`, `vercel-labs/skills`, `vercel-labs/agent-skills` | 自由にインストール可 |
| **Caution** | その他のリポジトリ | SKILL.md確認後にインストール |

詳細: `.claude/rules/skills/skill-trust-policy.md`

---

## Rule Reference

| Category | Location |
|---------|--------|
| **AI Coordination** | `rules/workflow/ai-coordination.md` |
| **Architecture** | `rules/architecture/adapter-core-pattern.md` |
| **Ralph Loop/Wiggum** | `rules/ralph-loop.md` |
| **Skills Trust Policy** | `rules/skills/skill-trust-policy.md` |
| Quality Standards | `rules/global/quality-standards.md` |
| GAS Development | `rules/gas/` |
| Testing | `rules/testing/` |

---

## Debugging Tools (3-Tier System)

```
Bug occurs
    |
    v
/bug-quick (5-15 min)     <-- First pass: Flow comparison
    |
    +-- Resolved --> Done
    |
    +-- Complex --> /bug-trace (30-60 min)  <-- Deep 3-Agent investigation
                        |
                        +-- Unresolved --> /dialogue-resolution  <-- AI reasoning check
```

| Tool | Time | Use When |
|------|------|----------|
| `/bug-quick` | 5-15 min | Compare your flow understanding vs code behavior |
| `/bug-trace` | 30-60 min | Complex bugs, multiple files, need root cause |
| `/dialogue-resolution` | Variable | AI keeps misunderstanding, circular reasoning |

**Escalation Triggers**:
- bug-quick -> bug-trace: Multiple differences, unclear root cause
- bug-trace -> dialogue-resolution: Same error 2x, AI reasoning seems off

---

## Ralph Wiggum (Night Mode)

夜間自律実行システム。詳細: `.kiro/ralph/README.md`

| 項目 | 日中 | 夜間 |
|------|------|------|
| コマンド | `/sd003:loop-*` | `/ralph-wiggum:*` |
| 環境変数 | `SD003_*` | `RALPH_*` |
| リカバリー | dialogue-resolution | 7パターン自動 |

仕様書: `.kiro/specs/ralph-wiggum/`

---

## Deployment to Other Projects

**🚨 絶対条件**: `/kiro:deploy` コマンドを使用すること

```bash
/kiro:deploy /path/to/your-project
```

**手動デプロイは非推奨**。詳細: `README.md` の Deployment セクション

### 必須ファイル数（検証用）

| カテゴリ | ファイル数 |
|---------|-----------|
| Commands直下 | 30 |
| Commands/kiro | 18 |
| Rules | 17 |
| Skills | 12 |
| Tests/gas-fakes | 1 |
| 合計 | 78 |

---
SD003 v2.13.0 | Updated: 2026-02-15
