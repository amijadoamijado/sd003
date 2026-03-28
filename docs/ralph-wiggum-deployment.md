# Ralph Wiggum Deployment Guide

> Night Mode Autonomous Execution System - Deployment Guide v1.0

## Overview

Ralph Wiggum is a night-mode autonomous execution system that enables 24-hour development cycles by combining daytime AI-coordinated workflows with nighttime autonomous task execution.

## Prerequisites

- Node.js 18+
- Claude Code CLI installed
- SD002 Framework (or compatible project structure)
- ESLint configured (for `/sd002:loop-lint`)

## Quick Start

### Option A: Deploy to Existing SD002 Project

```bash
# Already included in SD002 Framework
# Just start using the commands
/ralph-wiggum:plan    # Create weekly plan
/ralph-wiggum:run     # Execute nightly queue
/ralph-wiggum:status  # Check execution status
```

### Option B: Deploy to New Project

```bash
# 1. Copy required directories
cp -r .sd/ralph/ your-project/.sd/ralph/
cp -r .sd/specs/ralph-wiggum/ your-project/.sd/specs/ralph-wiggum/
cp -r .claude/commands/ralph-wiggum-*.md your-project/.claude/commands/

# 2. Update rules (append to existing or copy)
cat .claude/rules/ralph-loop.md >> your-project/.claude/rules/ralph-loop.md
```

## Directory Structure

### Required Files

```
your-project/
├── .sd/
│   ├── ralph/                          # Runtime directory
│   │   ├── nightly-queue.md            # Daily task queue
│   │   ├── backlog.md                  # Task backlog
│   │   ├── recovery/
│   │   │   ├── strategies.md           # 7 recovery patterns
│   │   │   ├── checkpoints/            # Auto checkpoints
│   │   │   └── fallback-prompts/
│   │   │       ├── retry-single.md
│   │   │       ├── skip-and-continue.md
│   │   │       └── graceful-exit.md
│   │   ├── weekly/
│   │   │   └── TEMPLATE/
│   │   │       └── plan.md
│   │   └── metrics/
│   │       └── weekly-stats.md
│   └── specs/ralph-wiggum/             # Specifications (optional)
│       ├── spec.json
│       ├── requirements.md
│       └── design.md
├── .claude/
│   ├── commands/
│   │   ├── ralph-wiggum-run.md
│   │   ├── ralph-wiggum-status.md
│   │   └── ralph-wiggum-plan.md
│   └── rules/
│       └── ralph-loop.md               # Append Night Mode section
└── CLAUDE.md                           # Add Ralph Wiggum reference
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_MAX_ITERATIONS` | 60 | Maximum loop iterations |
| `RALPH_COMPLETION_PROMISE` | `RALPH_NIGHTLY_COMPLETE` | Success marker |
| `RALPH_BLOCKED_PROMISE` | `RALPH_NIGHTLY_BLOCKED` | Blocked marker |

### Queue Configuration

Edit `.sd/ralph/nightly-queue.md`:

```yaml
# Queue Configuration
config:
  max-iterations: 60
  completion-promise: RALPH_NIGHTLY_COMPLETE
  blocked-promise: RALPH_NIGHTLY_BLOCKED
  recovery-strategy: auto
  checkpoint-interval: 5
```

## Two-Layer Architecture

Ralph Wiggum operates alongside the daytime Ralph Loop system:

| Aspect | Daytime (sd002-loop-*) | Nighttime (Ralph Wiggum) |
|--------|------------------------|--------------------------|
| Commands | `/sd002:loop-*` | `/ralph-wiggum:*` |
| max-iterations | 15-20 | 60 |
| Environment | `SD002_*` | `RALPH_*` |
| Completion | `ALL_TESTS_PASS` | `RALPH_NIGHTLY_COMPLETE` |
| Recovery | dialogue-resolution | 7 auto patterns |
| Human | Available anytime | Only when blocked |

## 7 Recovery Patterns

| # | Pattern | Description |
|---|---------|-------------|
| 1 | Build Error | Auto-fix type errors |
| 2 | Test Failure | Fix implementation or test |
| 3 | Lint Error | --fix + manual correction |
| 4 | Infinite Loop | Adaptive detection + skip |
| 5 | External Dependency | Circuit breaker |
| 6 | Unexpected | Graceful exit (resumable) |
| 7 | Recovery Exhaustion | Skip + escalation |

## Weekly Workflow

### Monday Morning: Plan

```bash
/ralph-wiggum:plan W02    # Create weekly plan
```

### Daily: Queue Setup

Edit `.sd/ralph/nightly-queue.md` with tasks for the night.

### Nighttime: Execution

```bash
/ralph-wiggum:run         # Start autonomous execution
```

### Morning: Review

```bash
/ralph-wiggum:status      # Check results
```

## Integration with AI Coordination

Ralph Wiggum integrates with the AI Coordination Workflow:

1. **Morning Report**: Auto-generates `TEST_REPORT` in `.sd/ai-coordination/workflow/review/ralph/`
2. **Handoff Log**: Records in `handoff-log.json`
3. **Session Continuity**: Preserves context for next session

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Lock file stuck | Delete `.sd/ralph/.lock` |
| Checkpoint corrupted | Use `--resume` with previous checkpoint |
| Recovery exhausted | Review logs, fix manually, resume |

### Log Locations

- Success: `.sd/ralph/logs/{date}-result.md`
- Blocked: `.sd/ralph/logs/{date}-blocked.md`
- Errors: `.sd/ralph/logs/{date}-errors.md`

## Customization

### Adding Custom Recovery Patterns

Edit `.sd/ralph/recovery/strategies.md` to add project-specific patterns.

### Adjusting Iteration Limits

```yaml
# In nightly-queue.md
config:
  max-iterations: 80  # Increase for complex projects
```

### Circuit Breaker Settings

```yaml
# In strategies.md
circuit-breaker:
  failure-threshold: 3
  timeout: 5m
  half-open-attempts: 1
```

## Best Practices

1. **Start Small**: Begin with low-risk tasks (lint, simple tests)
2. **Clear Specs**: Every task should reference a specification
3. **Friday = Low Risk**: Schedule risky tasks mid-week
4. **Monitor Metrics**: Review weekly-stats.md regularly
5. **Iterate**: Adjust max-iterations based on project patterns

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.1.0 | 2026-01-04 | Added Pattern 7, Adapter-Core, checkpoint migration |
| 1.0.0 | 2026-01-04 | Initial release |

---

**Ralph Wiggum** - Night Mode Autonomous Execution System
Part of SD002 Framework
