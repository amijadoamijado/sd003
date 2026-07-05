---
name: sd003-loop-lint
description: "/sd003:loop-lint - ESLint Completion Loop (Use when the user runs /sd003-loop-lint.)"
---

# /sd003:loop-lint - ESLint Completion Loop

SD003 custom command `/sd003:loop-lint` を Grok skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Grok Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Grok の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*`、`/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はGrok自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

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
