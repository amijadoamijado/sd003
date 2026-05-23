---
name: spec-archive
description: Codex equivalent of the SD003 custom command `/spec:archive`. Use when the user invokes `/spec:archive`, `spec-archive`.
---

# Spec Archive

この skill は Claude Code の `/spec:archive` を Codex で再現するためのものです。
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
# Spec Archive

Archive specification files to history folder with timestamp.

## Usage

```
/spec:archive {feature} [file]
```

| Argument | Required | Description |
|----------|----------|-------------|
| feature | Yes | Feature name (folder under .sd/specs/) |
| file | No | Specific file (requirements, design, tasks). If omitted, archives all. |

## Examples

```bash
/spec:archive bug-trace              # Archive all files
/spec:archive bug-trace requirements # Archive requirements.md only
/spec:archive ralph-wiggum spec      # Archive spec.md only
```

## Execution Steps

1. Validate feature folder exists at `.sd/specs/{feature}/`
2. Generate timestamp: `YYYYMMDD-HHMMSS`
3. Create `history/` folder if not exists
4. For each target file:
   - Read current content from `.sd/specs/{feature}/{file}.md`
   - Save to `.sd/specs/{feature}/history/{file}-YYYYMMDD-HHMMSS.md`
5. Update `spec.json` history section
6. Display completion message

## File Naming

```
{type}-YYYYMMDD-HHMMSS.md
```

Examples:
- `requirements-20251226-143000.md`
- `design-20251226-143000.md`
- `tasks-20251226-143000.md`

## spec.json Update

Add entry to history array:

```json
{
  "history": [
    {
      "version": "[current version]",
      "date": "YYYY-MM-DD",
      "file": "{type}-YYYYMMDD-HHMMSS.md",
      "note": "[user provided note or auto-generated]"
    }
  ]
}
```

## User Input

Feature: $ARGUMENTS

---

**Execute**: Read target files, save to history/ with timestamp, update spec.json.
