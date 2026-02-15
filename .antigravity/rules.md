# SD003 Framework - Antigravity Rules

## Overview
SD003: Spec-Driven Development framework integrating SD001 and GA001 for AI-driven GAS development.

**Tech Stack**: TypeScript (strict) + Google Apps Script + Env Interface Pattern

## Project Structure
| Folder | Purpose |
|--------|---------|
| `src/` | Business logic (GAS-independent) |
| `tests/` | Tests |
| `docs/` | Documentation |
| `materials/` | Reference materials & deliverables |
| `.kiro/` | Specs, sessions, settings |
| `.claude/rules/` | Development rules |

## Design Principles
1. **Spec-First** - Requirements -> Design -> Implementation -> Test
2. **GAS Independence** - Env Interface Pattern for environment separation
3. **Pre-Deploy Bug Elimination** - 8-stage quality gates

---

## AI Coordination Workflow (MANDATORY)

### 4-Agent Pipeline
Antigravityは4-Agentパイプラインの第4段階として、自動連鎖で呼び出される:
```
request → impl(Gemini) → review(Codex) → test(Antigravity)
```
レビュー Approve 時に `/workflow:test` が自動実行され、TEST_REQUEST が作成される。

**運用ガイド**: `.kiro/ai-coordination/workflow/ANTIGRAVITY_GUIDE.md`

### Antigravity's Role
| Role | Description |
|------|-------------|
| E2E Test | UI verification in production/staging |
| Exploratory Test | Behavior verification outside specs, UX validation |
| Screenshot Capture | Evidence collection for test reports |
| Production Verification | Post-deploy operation check |

### 3-Tier Testing Integration
| Tier | Tool | Scope |
|------|------|-------|
| Tier-1 | GA001 Mock + LocalEnv | Unit tests (fast, limited fidelity) |
| Tier-2 | @mcpher/gas-fakes | Integration tests (medium speed, high fidelity) |
| Tier-3 | Antigravity E2E | Production tests (slow, highest fidelity) |

### Trigger Words (AUTO-EXECUTE)

When user prompt contains these keywords, AUTOMATICALLY execute the corresponding workflow:

| Trigger Keyword | Action | Template |
|----------------|--------|----------|
| "test request", "test instruction" | Read TEST_REQUEST from spec folder | `.kiro/ai-coordination/workflow/spec/{projectID}/` |
| "test report", "report results" | Create TEST_REPORT in review folder | `.kiro/ai-coordination/workflow/review/{projectID}/` |
| "create instruction", "create request" | Use template from templates folder | `.kiro/ai-coordination/workflow/templates/` |

### File Location Rules (ABSOLUTE)

**ALL requests and reports MUST be in `.kiro/ai-coordination/`**

| File Type | Location | Example |
|-----------|----------|---------|
| Test Request | `workflow/spec/{projectID}/TEST_REQUEST_{NNN}.md` | `TEST_REQUEST_001.md` |
| Test Report | `workflow/review/{projectID}/TEST_REPORT_{NNN}.md` | `TEST_REPORT_001.md` |

### PROHIBITED
| Prohibited | Reason |
|------------|--------|
| Creating requests in `.antigravity/` | Not linked to project |
| Creating requests in project root | Causes clutter |
| Creating requests without template | Inconsistent format |

### Workflow Steps

**When receiving a test request:**
```
1. Look for TEST_REQUEST in: .kiro/ai-coordination/workflow/spec/{projectID}/
2. Execute tests as specified
3. Capture screenshots
4. Create TEST_REPORT in: .kiro/ai-coordination/workflow/review/{projectID}/
5. Record in handoff-log.json
```

**When asked to create a test request:**
```
1. Use template: .kiro/ai-coordination/workflow/templates/TEST_REQUEST.md
2. Save to: .kiro/ai-coordination/workflow/spec/{projectID}/TEST_REQUEST_{NNN}.md
3. Record in handoff-log.json
```

---

## Critical Rules

### Required
- No direct GAS API references (use Env only)
- Test coverage 80%+
- ESLint errors: 0
- TypeScript strict mode

### Forbidden
- Node.js-only APIs (`fs`, `path`, `process`)
- Unauthorized spec changes
- Skipping tests

## Protected Files (Do NOT move/delete)

These files must remain at project root:
- `agents.md` - Agent configuration
- `CLAUDE.md` - Claude Code command center
- `gemini.md` - Gemini CLI settings
- `GEMINI.md` - Antigravity global rules

## Code Style

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Class | PascalCase | `DataProcessor` |
| Function | camelCase | `processData` |
| Constant | UPPER_SNAKE | `MAX_RETRIES` |

### Documentation
- JSDoc required for public APIs
- Comments in English within code
- User-facing messages in Japanese

## Build & Test Commands
```bash
npm run build    # Build
npm test         # Test
npm run lint     # Lint
npm run qa:all   # All quality gates
```

## Production Mode

Keywords "production", "deploy", or "release" activate:
- Line-by-line code review
- All test cases (normal, error, edge)
- All 8 quality gates must pass

## Reference Documents
| Topic | Location |
|-------|----------|
| Quality Gates | `docs/quality-gates.md` |
| Setup Guide | `docs/sd002-setup-guide.md` |
| Session Management | `docs/session-management.md` |
| Troubleshooting | `docs/troubleshooting/` |
| AI Coordination | `.claude/rules/workflow/ai-coordination.md` |

---
SD003 v2.12.0 | Updated: 2026-02-15
