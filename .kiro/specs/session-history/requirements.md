# Session History - Requirements

## Overview

**Purpose**: Compensate for Claude Code's lack of long-term memory by implementing a two-layer memory system.

**Problem Statement**: Claude Code loses context between sessions and after crashes. Developers need a way to quickly understand project history and recover from interruptions.

---

## Requirements

### REQ-SH-001: Two-Layer Memory Structure

**Priority**: P0 (Critical)

The system SHALL implement a two-layer memory structure:

| Layer | File | Purpose | Update Frequency |
|-------|------|---------|------------------|
| Long-term | TIMELINE.md | Project history overview | On /sessionwrite |
| Short-term | session-current.md | Current session details | On /sessionwrite |

**Acceptance Criteria**:
- TIMELINE.md exists in `.kiro/sessions/`
- session-current.md exists in `.kiro/sessions/`
- Both files are human-readable Markdown

---

### REQ-SH-002: Timeline (TIMELINE.md)

**Priority**: P0 (Critical)

The timeline SHALL provide:

1. Chronological list of all sessions
2. Date of each session
3. Main work summary (one line per session)
4. Commit hash at session end
5. Link to detailed session record

**Format**:
```markdown
| Date | Main Work | Commit | Details |
|------|-----------|--------|---------|
| MM-DD | [summary] | [hash] | [link] |
```

**Acceptance Criteria**:
- Entries sorted by date (newest first within each month)
- Grouped by year and month
- Statistics section at bottom

---

### REQ-SH-003: Session History Command

**Priority**: P1 (Important)

The system SHALL provide `/sessionhistory` command that:

1. Reads TIMELINE.md
2. Displays full timeline content
3. Shows summary statistics

**Acceptance Criteria**:
- Command is registered in `.claude/commands/`
- Output includes total session count
- Output includes date range

---

### REQ-SH-004: Automatic Timeline Update

**Priority**: P0 (Critical)

The `/sessionwrite` command SHALL:

1. Save session record (existing behavior)
2. Update TIMELINE.md with new entry
3. Update statistics (session count, latest date)

**Acceptance Criteria**:
- New entry added at top of current month
- Session count incremented
- Latest session date updated

---

### REQ-SH-005: Session Start Protocol

**Priority**: P1 (Important)

CLAUDE.md SHALL instruct AI to check at session start:

1. TIMELINE.md for project history
2. session-current.md for recent context

**Acceptance Criteria**:
- CLAUDE.md contains "Project Memory" section
- Links to both files provided
- Positioned near top of CLAUDE.md

---

### REQ-SH-006: Crash Recovery Procedure

**Priority**: P1 (Important)

The system SHALL document crash recovery procedure using standard Claude Code features:

1. `claude --continue` - Restore conversation context
2. `/sessionread` - Load last saved state

**Acceptance Criteria**:
- Procedure documented in session-management.md
- Brief reference in CLAUDE.md
- No new tools/commands required (use existing features)

---

### REQ-SH-007: Crash Recovery Limitations

**Priority**: P2 (Normal)

Documentation SHALL clearly state:

1. `--continue` restores conversation context (may include unsaved work)
2. `/sessionread` only shows last **saved** checkpoint
3. Work after last `/sessionwrite` requires manual review

**Acceptance Criteria**:
- Limitations documented in rules
- Recovery flow diagram included

---

## Non-Requirements

The following are explicitly NOT in scope:

| Item | Reason |
|------|--------|
| Automatic crash detection | Use standard `--continue` |
| Unsaved work recovery tool | Standard features sufficient |
| Real-time sync | Session-based is adequate |
| Cloud backup | Local files only |

---

## Traceability

| Requirement | Implementation |
|-------------|----------------|
| REQ-SH-001 | `.kiro/sessions/TIMELINE.md`, `session-current.md` |
| REQ-SH-002 | `.kiro/sessions/TIMELINE.md` |
| REQ-SH-003 | `.claude/commands/sessionhistory.md` |
| REQ-SH-004 | `.claude/commands/sessionwrite.md` |
| REQ-SH-005 | `CLAUDE.md` (Project Memory section) |
| REQ-SH-006 | `.claude/rules/session/session-management.md` |
| REQ-SH-007 | `.claude/rules/session/session-management.md` |
