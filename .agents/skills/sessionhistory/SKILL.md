---
name: sessionhistory
description: "Show project timeline (long-term session history)"
disable-model-invocation: true
---

# Session History (Timeline)

SD003 custom command `/sessionhistory` をCodex/agy共通Agent Skillとして再現します。

User-provided arguments (if any): $ARGUMENTS

## Runtime Adaptation Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、実行中CLIの通常手順（ファイル読取・編集・検証・必要時のユーザー確認）に翻訳する。
- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは再帰実行しない。必要な作業は現在のCLIが直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。
- Codex固有の実行優先順位は `.codex/CODEX_NATIVE.md` に従う。

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
