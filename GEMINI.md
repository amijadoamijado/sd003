# SD003 Framework - Gemini CLI / Antigravity Configuration

## Custom Commands & Skills (New)

SD003 now supports Gemini CLI custom slash commands and skills.

### Slash Commands
Custom commands are authored in `.claude/commands/**/*.md`, normalized into `.sd/commands/specs/*.md`, and then generated into `.gemini/commands/*.toml`.

Sync command:
```bash
python scripts/sync-cli-commands.py
python scripts/sync-cli-commands.py --check
python scripts/sync-cli-commands.py --deploy-codex-home
```

Gemini CLI should consume the generated `.gemini/commands/*.toml` files, not hand-maintained copies.

### Skills
Project-local skills are available in `.gemini/skills/`.
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

### Gemini CLI's Role
| Role | Description |
|------|-------------|
| Implementation | Execute IMPLEMENT_REQUEST tasks |
| Report | Create completion reports |

### Antigravity's Role
| Role | Description |
|------|-------------|
| E2E Test | Execute TEST_REQUEST, verify production |
| Report | Create TEST_REPORT with evidence |

### Trigger Keywords (AUTO-EXECUTE)

| Keyword | AI | Action |
|---------|-----|--------|
| "implement", "build" | Gemini | Read IMPLEMENT_REQUEST, execute |
| "test request", "verify" | Antigravity | Read TEST_REQUEST, execute |
| "complete", "done" | Both | Create report in review folder |

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
- Test coverage >=80%
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

## Non-Interactive Piping (CLI Automation)

Gemini CLIは非インタラクティブモードでパイプ入力をサポートしています。
SD003ワークフローでは、IMPLEMENT_REQUESTをパイプで渡して自動実装を実行できます。

### 基本構文
```bash
echo "プロンプト" | gemini
```

### SD003 Agent Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `scripts/agent-implement.sh` | Gemini CLIへの実装依頼 | `./scripts/agent-implement.sh <案件ID> <タスク番号>` |
| `scripts/agent-pipeline.sh` | 3-Agent パイプライン | `./scripts/agent-pipeline.sh <案件ID> <タスク番号>` |

### agent-implement.sh
IMPLEMENT_REQUESTをGemini CLIにパイプで渡し、非インタラクティブに実装を実行:
```bash
# 基本実行
./scripts/agent-implement.sh 20260101-001-auth 001

# 既存ファイルのコンテキスト付き
./scripts/agent-implement.sh 20260101-001-auth 001 src/core/auth.ts

# プレビュー（Gemini実行なし）
./scripts/agent-implement.sh 20260101-001-auth 001 --dry-run
```

### agent-pipeline.sh
Claude Code → Gemini(実装) → Codex(レビュー) の3段階パイプライン:
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
    ├── Step 1: Gemini CLI (echo ... | gemini) → 実装
    ├── Step 2: git commit (--auto-apply時)
    └── Step 3: Codex CLI (echo ... | codex) → レビュー
    ↓
Claude Code: 結果を読んで判断 → 承認 or 修正指示
```

---
SD003 Framework v2.13.0 | Updated: 2026-03-07
b
b
