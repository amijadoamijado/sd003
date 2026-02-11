# SD002 Framework - Gemini CLI / Antigravity Configuration

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

**ALL documents in `.kiro/ai-coordination/`**

| Read From | Write To |
|-----------|----------|
| `workflow/spec/{projectID}/` | `workflow/review/{projectID}/` |

**PROHIBITED**: Creating files in `.antigravity/` or project root

---

## Project Context

### Key Paths
| Path | Purpose |
|------|---------|
| `.kiro/ai-coordination/` | **AI coordination workflow** |
| `.kiro/specs/` | Feature specifications |
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
- **Templates**: `.kiro/ai-coordination/workflow/templates/`

---

## Non-Interactive Piping (CLI Automation)

Gemini CLIは非インタラクティブモードでパイプ入力をサポートしています。
SD002ワークフローでは、IMPLEMENT_REQUESTをパイプで渡して自動実装を実行できます。

### 基本構文
```bash
echo "プロンプト" | gemini
```

### SD002 Agent Scripts

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
SD002 Framework v2.9.0
