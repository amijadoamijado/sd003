# SD002 Framework - Codex CLI Configuration

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

---

## Reference
- **AI Coordination**: `.claude/rules/workflow/ai-coordination.md`
- **Quality Gates**: `docs/quality-gates.md`
- **Templates**: `.kiro/ai-coordination/workflow/templates/`

---
SD002 Framework v2.6.0
