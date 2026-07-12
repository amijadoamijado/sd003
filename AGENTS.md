# AGENTS.md - Codex CLI Configuration (SD003)

## 役割の明確化

このファイルは**Codex CLI全体の設定**を定義します。

コードレビュー時の詳細な手順は `.handoff/AGENTS.md` を参照してください。

| ファイル | 役割 |
|---------|------|
| `AGENTS.md`（このファイル） | Codex全体の設定・AI Coordination・Work Order Review |
| `.codex/CODEX_SPEC.md` | Codex固有の実行仕様・Claude Code非破壊ルール |
| `.codex/CODEX_NATIVE.md` | Codex nativeの軽量レビュー・引継ぎ・直接実装ルール |
| `.grok/GROK_NATIVE.md` | Grok Lead mode（Session Lead）の直接実装・引継ぎルール |
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
| Session Lead | `docs/orchestrator-contract.md` に従い、役割割当・状態遷移・完了判定を統合 |

### Trigger Keywords (AUTO-EXECUTE)

以下はAI Coordination文脈で依頼書・レビュー対象が明示されている場合に適用する。
一般的な相談や改善提案では、ユーザーが成果物作成を求めていない限りREVIEW_REPORTを作成しない。

案件IDや正式な依頼書がない `review` / `check` / `見て` は `.codex/CODEX_NATIVE.md` の Fast Review として扱う。
この場合、`.sd/ai-coordination/` へ報告書を作らず、会話内で重大度順に報告する。

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
- Tests only to reproduce production bugs (coverage target abolished; VTD-001〜005 + real-data verification)
- ESLint errors = 0
- TypeScript strict mode
- **.sd/ safe commit**: .sd/変更後は早めにcommit（同一bashが最も安全）。未commitの.sd/変更はwipe時にL4で復元されない。詳細: `.claude/rules/git/sd-safe-commit.md`
- **settings.json**: `.claude/settings.json`はgit管理外（.gitignore）にすること
- **Codex追加仕様**: `.codex/CODEX_SPEC.md` を参照すること。Claude Codeの正本仕様を置き換えず、Codex側の実行変換だけを追加する。
- **Codex native運用**: `.codex/CODEX_NATIVE.md` を参照すること。Codex内で `/codex:*` や `/workflow:*` を再帰実行せず、Codex自身の読取・編集・検証に置き換える。
- **Grok Lead mode**: `.grok/GROK_NATIVE.md` を参照すること。ユーザーが Grok を直接起動した場合、Session Lead は Grok（Claude 固定ではない）。Assist のみ `grok-dispatch`。

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
- `.codex/skills/*/SKILL.md`（Codex）
- `.agents/skills/*/SKILL.md`（Antigravity CLI / agy。agyはSKILL.md形式のみ読み込む。`.toml`は不可）

Claude 以外の生成物は直接手編集せず、`.claude/commands/` を修正して再同期すること。
`.agents/skills/` は agy（Antigravity CLI）が起動時にスキャンする正規スキルパス（コマンド・実スキル両方を配置）。Codex仕様は `.codex/` 配下に置く。

### Available Codex Skills
```
$ai-suspect
$blueprint-gate
$bug-quick
$bug-trace
$cleanup
$cleanup-history
$cleanup-restore
$dialogue-resolution
$grillme
$jobs-review
$sd-deploy
$session-read
$session-search
$session-write
$sessionread
$sessionwrite
$sessionhistory
$skills-add
$skills-find
$skills-list
$spec-archive
$spec-history
```

---

## Reference
- **AI Coordination**: `.claude/rules/workflow/ai-coordination.md`
- **Codex Spec**: `.codex/CODEX_SPEC.md`
- **Codex Native**: `.codex/CODEX_NATIVE.md`
- **Grok Native (Lead)**: `.grok/GROK_NATIVE.md`
- **Grok Guide**: `.sd/ai-coordination/workflow/GROK_GUIDE.md`
- **Quality Gates**: `docs/quality-gates.md`
- **AI協調の依頼・報告**: `.claude/rules/workflow/ai-coordination.md`（正式時のみ `spec/{案件ID}/` 自由形式）

---
SD003 Framework v2.15.0 | Updated: 2026-07-06
