---
name: sd003-loop-lint
description: Codex equivalent of the SD003 custom command `/sd003:loop-lint`. Use when the user invokes `/sd003:loop-lint`, `sd003-loop-lint`.
---

# /sd003:loop-lint - ESLint Completion Loop

この skill は Claude Code の `/sd003:loop-lint` を Codex で再現するためのものです。
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
# /sd003:loop-lint - ESLint Completion Loop

Run ESLint in a loop until all lint errors are resolved.

## Purpose

This command activates the Ralph Loop mechanism to automatically retry linting until all ESLint errors and warnings are resolved. Use this as a supplementary command when the primary `/sd003:loop-test` is not sufficient.

## Usage

```
/sd003:loop-lint [max-iterations]
```

## Parameters

- `max-iterations` (optional): Maximum number of retry attempts. Default: 15

## How It Works

1. Runs `npm run lint`
2. If lint errors exist, the stop-hook blocks the session end
3. Claude analyzes the errors and attempts to fix
4. Repeat until:
   - All lint errors resolved (output contains `LINT_CLEAN`)
   - Max iterations reached
   - User manually interrupts

## Completion Promise

The loop completes when the output contains: `LINT_CLEAN`

Set `SD003_COMPLETION_PROMISE=LINT_CLEAN` before running this command.

## Example Usage

```bash
# Set completion promise for lint
export SD003_COMPLETION_PROMISE=LINT_CLEAN
export SD003_MAX_ITERATIONS=15

# Run lint loop
/sd003:loop-lint
```

## Expected Output Format

Your lint script should output `LINT_CLEAN` when there are no errors:

```javascript
// In package.json scripts
"lint": "eslint . && echo 'LINT_CLEAN'"
```

Or modify your ESLint configuration to output this on success.

## Related Commands

- `/sd003:loop-test` - Test completion loop (primary)
- `/sd003:loop-type` - TypeScript type-check loop

## SD003 Philosophy

Supplementary command for the midpoint phase. Use when:
- Tests pass but lint errors remain
- Code quality needs cleanup before proceeding

---

**Phase**: Midpoint (Phase 2-3)
**Stop Hook**: `.claude/hooks/sd003-stop-hook.sh`
**Completion Promise**: `LINT_CLEAN`
