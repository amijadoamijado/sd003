# Bug QUICK Rules

## Core Principle

> Compare user's processing flow understanding with code's actual behavior.
> Present differences as facts. Don't judge which is "wrong".

## When to Use

- Bug occurs and user has a mental model of expected behavior
- Quick first-pass before deeper investigation
- Non-engineer needs to understand code behavior

## Prohibited Actions

1. **Use code terminology** (function names, variable names, operators)
2. **Judge correctness** - only state differences
3. **Read code in Step 1** - user's explanation must come first
4. **Skip confirmation** between steps

## 4-Step Flow

1. **User explains** their understanding (no code reading)
2. **AI translates** code to natural language
3. **Compare** side-by-side, highlight differences
4. **User decides** action (fix code, update understanding, escalate)

## Natural Language Translation Rules

| Code | Natural Language |
|------|-----------------|
| `>` | "exceeds", "more than" |
| `>=` | "at least", "or more" |
| `<` | "less than", "under" |
| `<=` | "up to", "at most" |
| `&&` | "both...and" |
| `||` | "either...or" |
| `!` | "not", "unless" |

## Escalation

**To Bug Trace when:**
- Multiple interrelated differences
- Root cause unclear
- Multiple files involved

**To Dialogue Resolution when:**
- AI keeps misunderstanding
- Circular reasoning detected

## Reference

- Command: `/bug-quick`
- Patterns: `docs/troubleshooting/bug-quick-patterns.md`
