# AGENTS.md - Codex CLI Configuration (SD003)

## 役割の明確化

このファイルは**Codex CLI全体の設定**を定義します。

コードレビュー時の詳細な手順は `.handoff/AGENTS.md` を参照してください。

| ファイル | 役割 |
|---------|------|
| `AGENTS.md`（このファイル） | Codex全体の設定・AI Coordination・Work Order Review |
| `.handoff/AGENTS.md` | コードレビュー専用の4段階手順 |

---

## 言語設定（必須）

**レビュー報告・ユーザーとのやりとりは全て日本語で対応すること。**
英語での回答は禁止。コード内のコメントや変数名は英語のままでよいが、
レビューコメント、報告書、質問への回答など、人間向けのテキストは日本語で出力する。

---

## Core Principles
- Always start complex tasks in plan mode. Iterate on the plan until
  it's solid before executing.
- After any correction, confirm with user before updating configuration
  to prevent repetition.
- Challenge changes: Justify every edit, prove it works, and compare
  against main/master branch.
- Use subagents for parallel compute and to keep main context clean.
  Offload subtasks like verification or cleanup.

## Workflow Orchestration
- Run parallel sessions using git worktrees for isolation.
- For bugs: Provide full context (e.g., logs) and
  delegate end-to-end.
- Use reusable skills/commands for daily repeats.

## Environment
- Environment: Windows 11, UTF-8 (BOM), CRLF.
- Context management: 10% remaining -> save session, 5% -> emergency save.

---

## CRITICAL: AI Coordination Workflow

**Detailed rules: `.claude/rules/workflow/ai-coordination.md`**

### Codex's Role
| Role | Description |
|------|-------------|
| Code Review | Review implementation quality |
| Work Order Review | Approve/reject work orders |
| Quality Gate Check | Verify all gates pass |

### Trigger Keywords (AUTO-EXECUTE)

| Keyword | Action |
|---------|--------|
| "review", "check" | Read request, create REVIEW_REPORT |
| "approved", "approve" | Create approval report |
| "request changes" | Create change request report |

### File Location Rules

**ALL documents in `.sd/ai-coordination/`**

| Read From | Write To |
|-----------|----------|
| `workflow/spec/{projectID}/` | `workflow/review/{projectID}/` |

**PROHIBITED**: Creating files in project root

---

## Task Completion Reporting (MANDATORY)

Every task must end with a report:
```
## Task Completion Report

### Summary
[Completion summary]

### Changes Made
| File | Action | Description |

### Verification Commands
npm test && npm run lint

### Next Steps
- [ ] Next action
```

---

## Development Guidelines

### Core Principles
1. **Spec-Driven Development**: Requirements -> Design -> Tasks -> Implementation
2. **Env Interface Pattern**: GAS API abstraction
3. **8-Stage Quality Gates**: All gates must pass

### Critical Rules
- No Node.js APIs (`fs`, `path`, `process`)
- GAS API via Env Interface only
- Test coverage >=80%
- ESLint errors = 0
- TypeScript strict mode
- **.sd/ safe commit**: .sd/ファイルの変更は同一bashコマンド内でgit add+commitまで完了すること。分割するとClaude Codeランタイムが.sd/を消す。詳細: `.claude/rules/git/sd-safe-commit.md`
- **settings.json**: `.claude/settings.json`はgit管理外（.gitignore）にすること

### GASデプロイルール（厳守）
- **`clasp push` のみ許可。`clasp deploy` / `clasp undeploy` はユーザー明示指示なしに実行禁止**
- 引数なし `clasp deploy` は新規デプロイメントを作成する（既存URLが増える）
- `clasp undeploy` は固定URLを消す（復旧不可能）
- 固定URL更新が必要でも、まずユーザーに確認すること
- 詳細: `.handoff/RULES.md` / `.claude/rules/gas/gas-constraints.md`

---

## Workflow Commands

**注意**: Codex CLI は Claude Code の `.claude/commands/*.md` 型スラッシュコマンドを直接読まない。
SD003 では `.claude/commands/**/*.md` を authoring source とし、`python scripts/sync-cli-commands.py` で以下を生成する。

- `.sd/commands/specs/*.md`（共通正本）
- `.agents/skills/*/SKILL.md`（Codex）
- `.gemini/commands/*.toml`（Gemini CLI）

Claude 以外の生成物は直接手編集せず、`.claude/commands/` を修正して再同期すること。

### Specification
```
$workflow-init {案件略称}
$workflow-order {案件ID}
$workflow-request {案件ID} {タスク番号}
$workflow-status {案件ID}
$workflow-review {案件ID}
$workflow-impl {案件ID} {タスク番号}
$workflow-test {案件ID} {タスク番号}
```

### Session Skills
```
$sessionread
$sessionwrite
$sessionhistory
```

### Utility Skills
```
$bug-quick
$bug-trace
$cleanup
$refactor-plan
$skills-find
$sd-deploy
```

---

## Reference
- **AI Coordination**: `.claude/rules/workflow/ai-coordination.md`
- **Quality Gates**: `docs/quality-gates.md`
- **Templates**: `.sd/ai-coordination/workflow/templates/`

---
SD003 Framework v2.14.0 | Updated: 2026-04-02
