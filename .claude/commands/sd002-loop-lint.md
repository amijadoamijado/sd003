# /sd002:loop-lint - ESLint Completion Loop

Run ESLint in a loop until all lint errors are resolved.

## Purpose

This command activates the Ralph Loop mechanism to automatically retry linting until all ESLint errors and warnings are resolved. Use this as a supplementary command when the primary `/sd002:loop-test` is not sufficient.

## Usage

```
/sd002:loop-lint [max-iterations]
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

Set `SD002_COMPLETION_PROMISE=LINT_CLEAN` before running this command.

## Example Usage

```bash
# Set completion promise for lint
export SD002_COMPLETION_PROMISE=LINT_CLEAN
export SD002_MAX_ITERATIONS=15

# Run lint loop
/sd002:loop-lint
```

## Expected Output Format

Your lint script should output `LINT_CLEAN` when there are no errors:

```javascript
// In package.json scripts
"lint": "eslint . && echo 'LINT_CLEAN'"
```

Or modify your ESLint configuration to output this on success.

## Related Commands

- `/sd002:loop-test` - Test completion loop (primary)
- `/sd002:loop-type` - TypeScript type-check loop

## SD002 Philosophy

Supplementary command for the midpoint phase. Use when:
- Tests pass but lint errors remain
- Code quality needs cleanup before proceeding

---

**Phase**: Midpoint (Phase 2-3)
**Stop Hook**: `.claude/hooks/sd002-stop-hook.sh`
**Completion Promise**: `LINT_CLEAN`
