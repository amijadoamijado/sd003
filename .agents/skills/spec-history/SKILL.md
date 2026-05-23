---
name: spec-history
description: "Show spec version history"
disable-model-invocation: true
---

# Spec History

SD003 custom command `/spec:history` を Antigravity (agy) skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Antigravity Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、agy(Gemini)の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はagy自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

## Original Command Body
# Spec History

Display version history for a specification.

## Usage

```
/spec:history {feature}
```

| Argument | Required | Description |
|----------|----------|-------------|
| feature | Yes | Feature name (folder under .sd/specs/) |

## Examples

```bash
/spec:history bug-trace
/spec:history ralph-wiggum
```

## Execution Steps

1. Validate feature folder exists at `.sd/specs/{feature}/`
2. Read `spec.json` for metadata and history array
3. List files in `history/` folder
4. Display formatted history table

## Output Format

```markdown
# {Feature} Version History

## Current Version
- **Version**: {version}
- **Updated**: {updated}
- **Status**: {status}

## History

| Date | Version | File | Note |
|------|---------|------|------|
| 2025-12-25 | 2.0.0 | requirements-20251225-100000.md | Logic change |
| 2025-10-26 | 1.0.0 | requirements-20251026-100000.md | Initial |

## Files in history/
- requirements-20251225-100000.md
- requirements-20251026-100000.md
- design-20251026-100000.md
```

## User Input

Feature: $ARGUMENTS

---

**Execute**: Read spec.json and history/ folder, display formatted history.
