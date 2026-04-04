---
name: sessionhistory
description: Codex equivalent of the SD003 custom command `/sessionhistory`. Use when the user invokes `/sessionhistory`, `sessionhistory`.
---

# Session History (Timeline)

この skill は Claude Code の `/sessionhistory` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Original Command Body
# Session History (Timeline)

Display the project timeline - a chronological overview of all development sessions.

## Purpose

- **Long-term memory**: Overview of project evolution
- **Quick context**: What was done when
- **Navigation**: Links to detailed session records

## Files

| File | Role |
|------|------|
| `.sessions/TIMELINE.md` | Timeline (long-term memory) |
| `.sessions/session-current.md` | Current session (short-term) |

## Execution

1. Read `.sessions/TIMELINE.md`
2. Display full timeline content
3. Show summary statistics

## Output Format

```
## Project Timeline

[Full TIMELINE.md content]

---
## Summary
- Total Sessions: N
- Date Range: YYYY-MM-DD ~ YYYY-MM-DD
- Latest Work: [description]
```

## Related Commands

| Command | Purpose |
|---------|---------|
| `/sessionread` | Read current session details |
| `/sessionwrite` | Save session (updates timeline) |

---

**Execute**: Read and display `.sessions/TIMELINE.md`
