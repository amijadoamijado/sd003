---
name: sd003-loop-type
description: "/sd003:loop-type - TypeScript Type-Check Loop"
disable-model-invocation: true
---

# /sd003:loop-type - TypeScript Type-Check Loop

SD003 custom command `/sd003:loop-type` を Antigravity (agy) skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Antigravity Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、agy(Gemini)の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はagy自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

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
