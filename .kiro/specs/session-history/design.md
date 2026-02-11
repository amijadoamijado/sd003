# Session History - Technical Design

## Architecture

### Two-Layer Memory System

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code Session                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Memory Layer                            │
│  ┌─────────────────────┐    ┌─────────────────────────────┐ │
│  │   Long-term Memory  │    │     Short-term Memory       │ │
│  │                     │    │                             │ │
│  │   TIMELINE.md       │    │   session-current.md        │ │
│  │   - Date summary    │    │   - Full session details    │ │
│  │   - Commit refs     │    │   - In-progress work        │ │
│  │   - Session links   │    │   - Next tasks              │ │
│  └─────────────────────┘    └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Session Archives                          │
│         session-YYYYMMDD-HHMMSS.md (immutable)              │
└─────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
.kiro/sessions/
├── TIMELINE.md              # Long-term memory (timeline)
├── session-current.md       # Short-term memory (latest)
├── session-20260104-*.md    # Archive (immutable)
├── session-20260102-*.md    # Archive
└── ...
```

---

## Data Flow

### Session Write Flow

```
/sessionwrite
    │
    ├── 1. Collect session data
    │       - Git status (branch, commit)
    │       - Work summary
    │       - Files modified
    │       - Next tasks
    │
    ├── 2. Generate timestamp
    │       Format: YYYYMMDD-HHMMSS
    │
    ├── 3. Write session record
    │       └── .kiro/sessions/session-{timestamp}.md
    │
    ├── 4. Update current session
    │       └── .kiro/sessions/session-current.md (overwrite)
    │
    └── 5. Update timeline
            │
            ├── Read TIMELINE.md
            ├── Extract main work (1 line)
            ├── Add entry to current month table
            ├── Update statistics
            └── Write TIMELINE.md
```

### Session Read Flow

```
/sessionread
    │
    └── Read .kiro/sessions/session-current.md
            │
            └── Display with summary
```

### Session History Flow

```
/sessionhistory
    │
    └── Read .kiro/sessions/TIMELINE.md
            │
            └── Display full timeline
```

---

## TIMELINE.md Schema

```markdown
# {Project Name} Timeline

> Auto-generated - Updated on /sessionwrite execution

---

## {Year}

### {Month}

| Date | Main Work | Commit | Details |
|------|-----------|--------|---------|
| MM-DD | [1-line summary] | [7-char hash] | [relative link] |

---

## Statistics

- Total Sessions: N
- First Session: YYYY-MM-DD
- Latest Session: YYYY-MM-DD
```

### Entry Format Rules

| Field | Format | Example |
|-------|--------|---------|
| Date | MM-DD | 01-04 |
| Main Work | Max 40 chars | Ralph Wiggum v1.1.0 |
| Commit | 7-char hash | 5cabda3 |
| Details | Relative link | [Details](session-20260104-100537.md) |

---

## Crash Recovery Design

### Standard Features Used

| Feature | Command | Purpose |
|---------|---------|---------|
| Context Resume | `claude --continue` | Restore conversation |
| Session Load | `/sessionread` | Load last checkpoint |

### Recovery Flow

```
          ┌────────────────┐
          │  Crash Occurs  │
          └───────┬────────┘
                  │
                  ▼
    ┌─────────────────────────────┐
    │    claude --continue        │
    │    (restores conversation)  │
    └───────────────┬─────────────┘
                    │
                    ▼
    ┌─────────────────────────────┐
    │    /sessionread             │
    │    (shows last checkpoint)  │
    └───────────────┬─────────────┘
                    │
                    ▼
    ┌─────────────────────────────┐
    │    Compare & Identify Gap   │
    │    (manual review)          │
    └───────────────┬─────────────┘
                    │
                    ▼
    ┌─────────────────────────────┐
    │    Continue Work            │
    └─────────────────────────────┘
```

### Data Recovery Matrix

| Data Type | --continue | /sessionread | Recovery |
|-----------|------------|--------------|----------|
| Conversation | Yes | No | Full |
| Saved session | No | Yes | Full |
| Unsaved work | Partial | No | Manual |
| File changes | N/A | N/A | Git status |

---

## Integration Points

### CLAUDE.md

```markdown
## Project Memory

Check at session start:
1. [Timeline (history)](.kiro/sessions/TIMELINE.md)
2. [Current Session](.kiro/sessions/session-current.md)

**Crash Recovery**: `claude --continue` + `/sessionread`
```

### Commands

| Command | File | Purpose |
|---------|------|---------|
| `/sessionhistory` | `.claude/commands/sessionhistory.md` | View timeline |
| `/sessionwrite` | `.claude/commands/sessionwrite.md` | Save + update timeline |
| `/sessionread` | `.claude/commands/sessionread.md` | Load current |

### Rules

| Rule | File | Purpose |
|------|------|---------|
| Session Management | `.claude/rules/session/session-management.md` | Full documentation |

---

## Design Decisions

### Decision 1: No Automatic Crash Detection

**Chosen**: Use standard `claude --continue`

**Rationale**:
- Standard feature is reliable
- No additional tooling required
- User has control over when to resume

### Decision 2: Timeline as Separate File

**Chosen**: TIMELINE.md separate from session files

**Rationale**:
- Single file for overview (easy to scan)
- Session files remain complete records
- Incremental updates are simple

### Decision 3: Chronological Order (Newest First)

**Chosen**: Newest entries at top within each month

**Rationale**:
- Most relevant work is immediately visible
- Consistent with typical log viewing
- Easy to find recent sessions

---

## Traceability Matrix

| Requirement | Design Component | Implementation |
|-------------|------------------|----------------|
| REQ-SH-001 | Two-Layer Memory | TIMELINE.md + session-current.md |
| REQ-SH-002 | TIMELINE Schema | Markdown table format |
| REQ-SH-003 | Session History Flow | `/sessionhistory` command |
| REQ-SH-004 | Session Write Flow | Step 5 (timeline update) |
| REQ-SH-005 | CLAUDE.md Integration | Project Memory section |
| REQ-SH-006 | Crash Recovery Design | --continue + /sessionread |
| REQ-SH-007 | Data Recovery Matrix | Documented limitations |
