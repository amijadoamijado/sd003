---
name: sessionhistory
description: Codex equivalent of the SD003 custom command `/sessionhistory`. Use when the user invokes `/sessionhistory`, `sessionhistory`.
---

# Session History (Timeline)

この skill は Claude Code の `/sessionhistory` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Codex Runtime Rules
- `.claude/commands/**/*.md` はClaude Code側のauthoring sourceです。直接変更せず、CodexではこのSkillを実行仕様として扱います。
- Claude Codeのスラッシュコマンド、`Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Codexの通常手順に翻訳します。
- Codex内で `/codex:review`、`/codex:rescue` などのCodexプラグインコマンドを再帰的に呼ばないでください。必要な読取・差分確認・編集・検証・報告をCodex自身で実施します。
- 人間向け出力、レビュー報告、質問、完了報告は日本語で書きます。
- `.sd/ai-coordination/` に依頼書・報告書を書く場合は、既存の案件ID配下に限定し、プロジェクトルートへ散らさないでください。
- Windows環境ではPowerShellで実行できるコマンドを優先し、bash専用の例はWSLやGit Bashが使える場合だけ採用します。

## Codex Native Execution Contract
このセクションはCodex実行時に `Original Command Body` より優先します。

- Claude Codeのスラッシュコマンド、`/workflow:*`、`/codex:*`、`Agent(...)`、`AskUserQuestion` は文字通り実行しない。
- Codex自身がファイル読取、差分確認、編集、検証、報告を直接行う。
- `.claude/commands/**/*.md` はauthoring sourceとして読むだけにし、Codex改善のために直接編集しない。
- 案件IDがない相談・レビューでは `.sd/ai-coordination/` に報告書を作らず、会話内で完結する。
- `.sd/ai-coordination/` に書くのは、案件IDが明示された正式Workflowの場合だけにする。
- WindowsではPowerShellで実行できるコマンドを優先し、bash例はWSL/Git Bashが使える場合だけ採用する。
- `.sd/` が存在しない場合は、その事実を報告し、可能なら軽量レビューまたは直接実装へ縮退する。

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
