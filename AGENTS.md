# AGENTS.md - Codex CLI Configuration (SD003)

## 役割の明確化

このファイルは**Codex CLI全体の設定**を定義します。

コードレビュー時の詳細な手順は `.handoff/AGENTS.md` を参照してください。

| ファイル | 役割 |
|---------|------|
| `AGENTS.md`（このファイル） | Codex全体の設定・AI Coordination・Work Order Review |
| `.handoff/AGENTS.md` | コードレビュー専用の4段階手順 |

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

**ALL documents in `.kiro/ai-coordination/`**

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

---

## Workflow Commands

### Specification
```
/prompts:kiro-spec-init "description"
/prompts:kiro-spec-requirements {feature}
/prompts:kiro-spec-design {feature}
/prompts:kiro-spec-tasks {feature}
```

### Implementation
```
/prompts:kiro-spec-impl {feature}
/prompts:kiro-validate-impl {feature}
```

### Claude互換コマンド同期
- Source: `.claude/commands/**/*.md`
- Target: `.codex/prompts/`
- Sync command: `npm run sync:codex-prompts`
- コマンド一覧表示: `/prompts`

例:
- Claude `/bug-quick` -> Codex `/prompts:bug-quick`
- Claude `/kiro:spec-init` -> Codex `/prompts:kiro-spec-init` または `/prompts:kiro/spec-init`

---

## Reference
- **AI Coordination**: `.claude/rules/workflow/ai-coordination.md`
- **Quality Gates**: `docs/quality-gates.md`
- **Templates**: `.kiro/ai-coordination/workflow/templates/`

---
SD003 Framework v2.11.0 | Updated: 2026-02-11
