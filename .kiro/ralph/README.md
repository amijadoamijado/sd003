# Ralph Wiggum - Night Mode Autonomous Execution System

> 24-hour Development Cycle: Daytime Collaboration + Nighttime Automation

[![Version](https://img.shields.io/badge/version-1.1.0-blue)]()
[![SD002](https://img.shields.io/badge/SD002-Framework-green)]()

## Overview

Ralph Wiggum enables autonomous nighttime task execution, complementing daytime AI-coordinated workflows. This creates a true 24-hour development cycle where:

- **Daytime**: Human-AI collaboration with interactive feedback
- **Nighttime**: Autonomous execution with 7-pattern auto-recovery

## Quick Start

```bash
# 1. Create weekly plan (Monday)
/ralph-wiggum:plan

# 2. Setup nightly queue (daily)
# Edit: .kiro/ralph/nightly-queue.md

# 3. Execute (nighttime)
/ralph-wiggum:run

# 4. Check results (morning)
/ralph-wiggum:status
```

## Directory Structure

```
.kiro/ralph/
├── nightly-queue.md              # Daily execution queue
├── backlog.md                    # Task backlog pool
├── README.md                     # This file
│
├── recovery/
│   ├── strategies.md             # 7 recovery patterns
│   ├── checkpoints/              # Auto-saved checkpoints
│   │   └── latest.json
│   └── fallback-prompts/
│       ├── retry-single.md       # Retry single task
│       ├── skip-and-continue.md  # Skip and continue
│       └── graceful-exit.md      # Graceful exit
│
├── weekly/
│   ├── TEMPLATE/                 # Week template
│   │   └── plan.md
│   └── {YYYY-Www}/               # Weekly data
│       ├── plan.md
│       ├── daily/
│       │   ├── mon.md ... fri.md
│       └── review.md
│
├── logs/
│   ├── {date}-result.md          # Success logs
│   ├── {date}-blocked.md         # Blocked logs
│   └── {date}-errors.md          # Error logs
│
└── metrics/
    └── weekly-stats.md           # Weekly statistics
```

## Commands

| Command | Description | Phase |
|---------|-------------|-------|
| `/ralph-wiggum:run` | Execute nightly queue | Night |
| `/ralph-wiggum:run --resume` | Resume from checkpoint | Night |
| `/ralph-wiggum:run --dry-run` | Preview without execution | Any |
| `/ralph-wiggum:status` | Check execution status | Any |
| `/ralph-wiggum:plan [week]` | Create weekly plan | Day |

## Two-Layer Architecture

Ralph Wiggum operates alongside the daytime Ralph Loop:

| Aspect | Daytime (sd002-loop-*) | Nighttime (Ralph Wiggum) |
|--------|------------------------|--------------------------|
| Commands | `/sd002:loop-test`, etc. | `/ralph-wiggum:run` |
| max-iterations | 15-20 | 60 |
| Environment Vars | `SD002_*` | `RALPH_*` |
| Completion Marker | `ALL_TESTS_PASS` | `RALPH_NIGHTLY_COMPLETE` |
| Recovery | dialogue-resolution | 7 auto patterns |
| Human Intervention | Available anytime | Only when blocked |

## 7 Recovery Patterns

| # | Pattern | Detection | Action |
|---|---------|-----------|--------|
| 1 | Build Error | `tsc` fails | Auto-fix types |
| 2 | Test Failure | `jest` fails | Fix impl/test |
| 3 | Lint Error | `eslint` fails | --fix + manual |
| 4 | Infinite Loop | Same error 3x | Adaptive skip |
| 5 | External Dependency | Network/API fail | Circuit breaker |
| 6 | Unexpected | Unknown error | Graceful exit |
| 7 | Recovery Exhaustion | All patterns fail | Skip + escalate |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_MAX_ITERATIONS` | 60 | Maximum iterations |
| `RALPH_COMPLETION_PROMISE` | `RALPH_NIGHTLY_COMPLETE` | Success marker |
| `RALPH_BLOCKED_PROMISE` | `RALPH_NIGHTLY_BLOCKED` | Blocked marker |

## Deployment to Other Projects

See [Deployment Guide](../../docs/ralph-wiggum-deployment.md)

### Quick Deploy

```bash
# Copy required files
cp -r .kiro/ralph/ your-project/.kiro/ralph/
cp -r .claude/commands/ralph-wiggum-*.md your-project/.claude/commands/

# Update rules
cat .claude/rules/ralph-loop.md >> your-project/.claude/rules/ralph-loop.md
```

## Specifications

| Document | Location |
|----------|----------|
| Requirements | `.kiro/specs/ralph-wiggum/requirements.md` |
| Design | `.kiro/specs/ralph-wiggum/design.md` |
| Metadata | `.kiro/specs/ralph-wiggum/spec.json` |

## Best Practices

1. **Start Small**: Begin with lint fixes, simple tests
2. **Clear Specs**: Every task needs specification reference
3. **Risk Management**: Monday=light, Mid-week=complex, Friday=low-risk
4. **Monitor Metrics**: Review `weekly-stats.md` regularly
5. **Iterate**: Adjust settings based on patterns

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Stuck lock | Delete `.kiro/ralph/.lock` |
| Checkpoint error | `--resume` with previous checkpoint |
| Pattern exhaustion | Manual fix + resume |

---

**Ralph Wiggum** - Night Mode Autonomous Execution System
Part of SD002 Framework v2.8.0
