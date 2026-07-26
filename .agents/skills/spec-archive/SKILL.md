---
name: spec-archive
description: "Archive spec files to history folder"
disable-model-invocation: true
---

# Spec Archive

SD003 custom command `/spec:archive` をCodex/agy共通Agent Skillとして再現します。

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
