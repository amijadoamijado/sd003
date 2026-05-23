---
name: spec-history
description: Codex equivalent of the SD003 custom command `/spec:history`. Use when the user invokes `/spec:history`, `spec-history`.
---

# Spec History

この skill は Claude Code の `/spec:history` を Codex で再現するためのものです。
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
