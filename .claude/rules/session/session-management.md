# Session Management

## Two-Layer Memory Structure

| Layer | File | Purpose |
|-------|------|---------|
| Long-term | `.kiro/sessions/TIMELINE.md` | Project history (timeline) |
| Short-term | `.kiro/sessions/session-current.md` | Current session details |

## Commands

| Command | Description |
|---------|-------------|
| `/sessionread` | **Full session load** (4 files) |
| `/sessionwrite` | Save session (history + current + timeline) |
| `/sessionhistory` | View timeline only |

## /sessionread - Complete Session Load

**Reads 4 files in order:**

| Order | File | Purpose |
|-------|------|---------|
| 1 | `D:\claudecode\CLAUDE.md` | Global settings (UTF-8 constraints) |
| 2 | `./CLAUDE.md` | Project settings |
| 3 | `.kiro/sessions/session-current.md` | Current session (short-term) |
| 4 | `.kiro/sessions/TIMELINE.md` | Project history (long-term) |

**Use at session start to load all context automatically.**

## File Locations

- **History**: `.kiro/sessions/session-YYYYMMDD-HHMMSS.md`
- **Latest**: `.kiro/sessions/session-current.md`
- **Timeline**: `.kiro/sessions/TIMELINE.md`

## Saved Information

- Date, project, branch, latest commit
- Completed items, in-progress items, unresolved issues
- Created/modified files list
- Next session tasks (P0/P1/P2 priority)
- Notes and handoff items

## Session Lifecycle

1. **Start**: Run `/sessionread` (loads all 4 files)
2. **Working**: Checkpoint as needed
3. **End**: `/sessionwrite` for handoff

## Crash Recovery Procedure

When Claude Code crashes unexpectedly:

```bash
# Step 1: Resume conversation context
claude --continue

# Step 2: Load all session context
/sessionread
```

**Important**:
- `--continue` restores conversation context (unsaved work may be visible)
- `/sessionread` loads global + project settings + last saved session + history
- Work done after last `/sessionwrite` requires manual review from `--continue` context

### Recovery Flow

```
Crash occurs
    ↓
claude --continue   ← Restores conversation (may include unsaved work)
    ↓
/sessionread        ← Loads all 4 files (global, project, session, timeline)
    ↓
Compare and determine what was lost
    ↓
Continue work
```

## Record Format

```markdown
# Session Record

## Session Info
- **Date**: [YYYY-MM-DD HH:MM:SS]
- **Project**: [path]
- **Branch**: [branch name]
- **Latest Commit**: [hash]

## Progress Summary

### Completed
### In Progress
### Unresolved Issues
### Created/Modified Files

### Next Session Tasks
- P0 (Urgent)
- P1 (Important)
- P2 (Normal)

### Notes
```

## Deployment to New Projects（⚠️ 省略禁止）

SD003を新規プロジェクトに展開する際、セッション管理は**必須コンポーネント**。

### 必須ファイルチェックリスト

| # | ファイル | 種別 | 確認 |
|---|---------|------|------|
| 1 | `.claude/commands/sessionread.md` | コピー | ☐ |
| 2 | `.claude/commands/sessionwrite.md` | コピー | ☐ |
| 3 | `.claude/commands/sessionhistory.md` | コピー | ☐ |
| 4 | `.claude/rules/session/session-management.md` | コピー | ☐ |
| 5 | `.kiro/sessions/session-template.md` | コピー | ☐ |
| 6 | `.kiro/sessions/session-current.md` | **新規作成** | ☐ |
| 7 | `.kiro/sessions/TIMELINE.md` | **新規作成** | ☐ |

### 注意事項

- **session-current.md と TIMELINE.md はコピーではなく新規作成する**（プロジェクト固有の初期内容）
- 展開後すぐに `/sessionread` で動作確認
- 失敗した場合: 上記7ファイルの存在を確認

### 展開コマンド

```bash
/kiro:deploy <target-project-path>
```

詳細手順: `.claude/skills/kiro-deploy/README.md`
