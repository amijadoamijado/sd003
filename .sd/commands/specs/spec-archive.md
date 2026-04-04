---
slug: spec-archive
source: .claude/commands/spec-archive.md
description: Archive spec files to history folder
claude_command: /spec:archive
codex_skill: spec-archive
gemini_file: spec-archive.toml
allowed_tools: Bash, Write, Read, Edit
---

# Spec Archive

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Gemini CLI の TOML と Codex の skill はこのファイルから生成します。

## Original Body
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
/spec:archive ralph-wiggum design    # Archive design.md only
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
