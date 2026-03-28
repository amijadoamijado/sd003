---
description: Save session handoff and update timeline
allowed-tools: Bash, Write, Read
---

# Session Record Save

Save session handoff and update project timeline.

## Files

| File | Purpose |
|------|---------|
| `.sessions/session-YYYYMMDD-HHMMSS.md` | History (timestamped) |
| `.sessions/session-current.md` | Latest version |
| `.sessions/TIMELINE.md` | Project timeline |

## Execution Steps

1. Create `.sessions/` directory (if not exists)
2. Generate timestamp (e.g., `20251123-143052`)
3. Get git status (branch, latest commit)
4. Create history file `.sessions/session-YYYYMMDD-HHMMSS.md`
5. Copy to `.sessions/session-current.md`
6. **Update TIMELINE.md** (add new entry)
7. Display completion message

## Session Record Format

```markdown
# Session Record

## Session Info
- **Date**: [YYYY-MM-DD HH:MM:SS]
- **Project**: [path]
- **Branch**: [git branch]
- **Latest Commit**: [hash + message]

## Progress Summary

### Completed
[numbered list]

### In Progress
[numbered list]

### Unresolved Issues
[issues and attempted solutions]

### Files Created/Modified
[categorized list]

### Next Session Tasks

#### P0 (Urgent)
[immediate tasks]

#### P1 (Important)
[important but not urgent]

#### P2 (Normal)
[when time allows]

### Notes
[handoff notes]
```

## TIMELINE.md Update

After saving session, update TIMELINE.md:

1. Read current TIMELINE.md
2. Extract main work summary (1 line, e.g., "Ralph Wiggum v1.1.0")
3. Add new entry at the top of the current month's table:

```markdown
| MM-DD | [Main Work] | [Commit Hash] | [Details](session-YYYYMMDD-HHMMSS.md) |
```

4. Increment total session count in Statistics
5. Update "Latest Session" date

## User Input
$ARGUMENTS

---

**Execute**: Create session record, save to both history and current files, then update TIMELINE.md.
