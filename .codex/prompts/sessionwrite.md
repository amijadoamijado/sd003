---
description: Save session handoff and update timeline
allowed-tools: Bash, Write, Read
---

# セッション記録 Save

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

## セッション記録 Format

```markdown
# セッション記録

## セッション情報
- **Date**: [YYYY-MM-DD HH:MM:SS]
- **Project**: [path]
- **Branch**: [git branch]
- **Latest Commit**: [hash + message]

## 作業サマリー

### 完了
[numbered list]

### 進行中
[numbered list]

### 未解決
[issues and attempted solutions]

### 作成・変更ファイル
[categorized list]

### 次回タスク

#### P0（緊急）
[immediate tasks]

#### P1（重要）
[important but not urgent]

#### P2（通常）
[when time allows]

### 備考
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
