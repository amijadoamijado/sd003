---
name: sd003-loop-type
description: Codex equivalent of the SD003 custom command `/sd003:loop-type`. Use when the user invokes `/sd003:loop-type`, `sd003-loop-type`.
---

# /sd003:loop-type - TypeScript Type-Check Loop

この skill は Claude Code の `/sd003:loop-type` を Codex で再現するためのものです。
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
# /sd003:loop-type - TypeScript Type-Check Loop

Run TypeScript type-checking in a loop until all type errors are resolved.

## Purpose

This command activates the Ralph Loop mechanism to automatically retry TypeScript compilation until all type errors are resolved. Use this as a supplementary command for strict type compliance.

## Usage

```
/sd003:loop-type [max-iterations]
```

## Parameters

- `max-iterations` (optional): Maximum number of retry attempts. Default: 15

## How It Works

1. Runs `npx tsc --noEmit`
2. If type errors exist, the stop-hook blocks the session end
3. Claude analyzes the errors and attempts to fix
4. Repeat until:
   - All type errors resolved (output contains `TYPE_CHECK_PASS`)
   - Max iterations reached
   - User manually interrupts

## Completion Promise

The loop completes when the output contains: `TYPE_CHECK_PASS`

Set `SD003_COMPLETION_PROMISE=TYPE_CHECK_PASS` before running this command.

## Example Usage

```bash
# Set completion promise for type-check
export SD003_COMPLETION_PROMISE=TYPE_CHECK_PASS
export SD003_MAX_ITERATIONS=15

# Run type-check loop
/sd003:loop-type
```

## Expected Output Format

Your type-check script should output `TYPE_CHECK_PASS` when there are no errors:

```javascript
// In package.json scripts
"type-check": "tsc --noEmit && echo 'TYPE_CHECK_PASS'"
```

## Related Commands

- `/sd003:loop-test` - Test completion loop (primary)
- `/sd003:loop-lint` - ESLint completion loop

## SD003 Philosophy

Supplementary command for the midpoint phase. Use when:
- TypeScript strict mode violations need resolution
- Type safety is critical before proceeding

---

**Phase**: Midpoint (Phase 2-3)
**Stop Hook**: `.claude/hooks/sd003-stop-hook.sh`
**Completion Promise**: `TYPE_CHECK_PASS`
