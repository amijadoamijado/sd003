---
slug: sessionhistory
source: .claude/commands/sessionhistory.md
description: Show project timeline (long-term session history)
claude_command: /sessionhistory
codex_skill: sessionhistory
gemini_file: sessionhistory.toml
allowed_tools: Read, Glob
---

# Session History (Timeline)

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Gemini CLI の TOML と Codex の skill はこのファイルから生成します。

## Original Body
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
