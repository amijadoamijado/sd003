# SD003 Framework - Antigravity CLI / agy Configuration

## Custom Commands & Skills (New)

SD003 now supports Antigravity CLI custom slash commands and skills.

### Slash Commands
Custom commands are authored in `.claude/commands/**/*.md`, normalized into `.sd/commands/specs/*.md`, and then generated as Agent Skills into `.agents/skills/{name}/SKILL.md` — the directory agy actually scans (verified against agy 1.0.1). agy does NOT read `.toml` command files.

Sync command:
```bash
python scripts/sync-cli-commands.py
python scripts/sync-cli-commands.py --check
python scripts/sync-cli-commands.py --deploy-codex-home
```

Antigravity CLI auto-discovers the generated `.agents/skills/*/SKILL.md` files at startup (`/skills` to verify). Do not hand-maintain copies.

### Skills
Project-local skills are available in `.agents/skills/` (workspace path agy scans: `<repo>/.agents/skills/{name}/SKILL.md`; global `~/.gemini/antigravity-cli/skills/`; shared `~/.gemini/skills/`).
You can activate them using the `activate_skill` tool (if supported by your environment) or they will be automatically included in the system instructions.
Available skills: `sd-deploy`, `session-autosave`, `rollback-guard`, etc.

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

### Antigravity CLI's Role
| Role | Description |
|------|-------------|
| Implementation | Execute IMPLEMENT_REQUEST tasks |
| E2E Test | Execute TEST_REQUEST, verify production |
| Report | Create completion reports & TEST_REPORT with evidence |

### Trigger Keywords (AUTO-EXECUTE)

| Keyword | AI | Action |
|---------|-----|--------|
| "implement", "build" | Antigravity | Read IMPLEMENT_REQUEST, execute |
| "test request", "verify" | Antigravity | Read TEST_REQUEST, execute |
| "complete", "done" | Antigravity | Create report in review folder |

### File Location Rules

**ALL documents in `.sd/ai-coordination/`**

| Read From | Write To |
|-----------|----------|
| `workflow/spec/{projectID}/` | `workflow/review/{projectID}/` |

**PROHIBITED**: Creating files in `.antigravity/` or project root

---

## Project Context

### Key Paths
| Path | Purpose |
|------|---------|
| `.sd/ai-coordination/` | **AI coordination workflow** |
| `.sd/specs/` | Feature specifications |
| `docs/` | Documentation |

### Templates
| Template | Location |
|----------|----------|
| TEST_REQUEST | `workflow/templates/TEST_REQUEST.md` |
| TEST_REPORT | `workflow/templates/TEST_REPORT.md` |
| IMPLEMENT_REQUEST | `workflow/templates/IMPLEMENT_REQUEST.md` |

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
- **.sd/ safe commit**: .sd/ファイルの変更は同一コマンド内でgit add+commitまで完了すること。分割するとランタイムが.sd/を消す。詳細: `.claude/rules/git/sd-safe-commit.md`
- **settings.json**: `.claude/settings.json`はgit管理外（.gitignore）にすること

### GASデプロイルール（厳守）
- **`clasp push` のみ許可。`clasp deploy` / `clasp undeploy` はユーザー明示指示なしに実行禁止**
- 引数なし `clasp deploy` は新規デプロイメントを作成する（既存URLが増える）
- `clasp undeploy` は固定URLを消す（復旧不可能）
- 固定URL更新が必要でも、まずユーザーに確認すること
- 詳細: `.handoff/RULES.md` / `.claude/rules/gas/gas-constraints.md`

---

## Task Completion Reporting

Every task must end with a report:
```
## Task Completion Report

### Summary
[Completion summary]

### Changes Made
| File | Action | Description |

### Verification
npm test && npm run lint

### Next Steps
- [ ] Next action
```

---

## Reference
- **AI Coordination**: `.claude/rules/workflow/ai-coordination.md`
- **Quality Gates**: `docs/quality-gates.md`
- **Templates**: `.sd/ai-coordination/workflow/templates/`

---

## Non-Interactive CLI Automation

Antigravity CLI (`agy`) は非インタラクティブモードでプロンプト実行をサポートしています。
SD003ワークフローでは、IMPLEMENT_REQUESTをプロンプトとして渡して自動実装を実行できます。

### ⚠️ 認証・前提（非対話実行の必須条件・2026-06-28 agyレビューで判明）

> **非対話の `agy --prompt`/`agy models`/`agy --print` が完了せずフリーズする場合、原因は2系統。コードバグではない**
> （2026-06-28 agyレビュー2回で特定）:
> 1. **排他ロック競合**: AIエージェントの非対話実行が、稼働中の Antigravity プロセスと同じ設定ディレクトリ
>    （`~/.gemini/antigravity-cli/`・`~/.gemini/skills/`）を共有し、**二重起動防止ロック**が競合してハングする。
> 2. **認証バックグラウンド待ち**: OAuth トークン期限切れ・初回認証未完了だと、ブラウザ起動や対話プロンプト入力を待つ。
>
> **開発者自身が手元のターミナルから対話的に agy を回す分には、ログイン済みなら問題なく稼働する**（レビューで PASSED）。
> ハングはAIエージェント実行環境特有の競合が主。

非対話で agy を回す前に、次を満たすこと（Grok の `GROK_SPEC.md` 認証節と同クラスの対処）:

| # | 条件 | 確認/対処 |
|---|------|----------|
| 1 | 二重起動の回避 | 稼働中の Antigravity と**同時に**非対話 agy を起動しない（同一 `~/.gemini` 設定/ロック競合）。1インスタンスに直列化 |
| 2 | OAuth ログイン完了 | **事前に手動（対話シェル）で `agy` を一度起動し、ブラウザ/OAuth認証を完了させておく** |
| 3 | or APIキー設定 | CI/他AIからの非対話実行では `GEMINI_API_KEY`（必要に応じ `GOOGLE_API_KEY`）を設定 |
| 4 | 疎通確認 | ローカル完結コマンド（`agy help models`）が即応するか。ハングするなら 1〜3 を疑う |

未認証・二重起動のまま `agy --prompt ... --dangerously-skip-permissions` を回さない。逼迫・反復ハング時は
codex-dispatch/grok-dispatch と同様に**人手ハンドオフ**（依頼書をユーザーに渡す）へ切り替える。

> 同期確認: `npm run sync:cli`（= `python scripts/sync-cli-commands.py`）で agy/Codex/Grok スキルを再生成（レビューで正常確認）。

### 基本構文
```bash
agy --prompt "プロンプト" --dangerously-skip-permissions
```

### SD003 Agent Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `scripts/agent-implement.sh` | Antigravity CLIへの実装依頼 | `./scripts/agent-implement.sh <案件ID> <タスク番号>` |
| `scripts/agent-pipeline.sh` | 3-Agent パイプライン | `./scripts/agent-pipeline.sh <案件ID> <タスク番号>` |

### agent-implement.sh
IMPLEMENT_REQUESTを Antigravity CLI に渡して、非インタラクティブに実装を実行:
```bash
# 基本実行
./scripts/agent-implement.sh 20260101-001-auth 001

# 既存ファイルのコンテキスト付き
./scripts/agent-implement.sh 20260101-001-auth 001 src/core/auth.ts

# プレビュー（agy実行なし）
./scripts/agent-implement.sh 20260101-001-auth 001 --dry-run
```

### agent-pipeline.sh
Claude Code → Antigravity(実装) → Codex(レビュー) の3段階パイプライン:
```bash
# 基本実行（実装 + レビュー）
./scripts/agent-pipeline.sh 20260101-001-auth 001

# レビュースキップ（実装のみ）
./scripts/agent-pipeline.sh 20260101-001-auth 001 --skip-review

# プレビュー
./scripts/agent-pipeline.sh 20260101-001-auth 001 --dry-run
```

### Pipeline Flow
```
Claude Code: /workflow:request → IMPLEMENT_REQUEST作成
    ↓
agent-pipeline.sh:
    ├── Step 1: Antigravity CLI (agy --prompt ... --dangerously-skip-permissions) → 実装
    ├── Step 2: git commit (--auto-apply時)
    └── Step 3: Codex CLI (echo ... | codex) → レビュー
    ↓
Claude Code: 結果を読んで判断 → 承認 or 修正指示
```

---
SD003 Framework v2.14.0 | Updated: 2026-05-22
