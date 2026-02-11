# /sd003:loop-test - Test Completion Loop

Run tests in a loop until all tests pass.

## Purpose

This command activates the Ralph Loop mechanism to automatically retry test execution until all tests pass. It's designed for the **midpoint phase (Phase 2-3)** of SD003 development where we want fast development but complete (not incomplete) results.

## Usage

```
/sd003:loop-test [max-iterations]
```

## Parameters

- `max-iterations` (optional): Maximum number of retry attempts. Default: 20

## How It Works

1. Runs `npm test`
2. If tests fail, the stop-hook blocks the session end
3. Claude analyzes the failure and attempts to fix
4. Repeat until:
   - All tests pass (output contains `ALL_TESTS_PASS`)
   - Max iterations reached
   - User manually interrupts

## Completion Promise

The loop completes when the output contains: `ALL_TESTS_PASS`

Make sure your test output includes this string when all tests pass, or modify the SD003_COMPLETION_PROMISE environment variable.

## Example Output

```
Running npm test...

  Test Suite 1
    - test case 1
    - test case 2

  3 passing, 1 failing

Iteration 1/20 - Task not complete. Continuing...
Looking for: ALL_TESTS_PASS

[Claude attempts fix...]

Running npm test...

  Test Suite 1
    - test case 1
    - test case 2

  4 passing

ALL_TESTS_PASS

Completion promise 'ALL_TESTS_PASS' detected. Task complete.
```

## Related Commands

- `/sd003:loop-lint` - ESLint completion loop
- `/sd003:loop-type` - TypeScript type-check loop

## SD003 Philosophy

This command implements the "90% fast development, 10% perfectionism" principle:
- Fast iteration with automatic retries
- Midpoint completion (not incomplete, but complete)
- Automatic escalation if stuck (see endgame phase)

---

**Phase**: Midpoint (Phase 2-3)
**Stop Hook**: `.claude/hooks/sd003-stop-hook.sh`
