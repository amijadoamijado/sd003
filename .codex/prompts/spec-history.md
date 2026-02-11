---
description: Show spec version history
allowed-tools: Bash, Read, Glob
---

# Spec History

Display version history for a specification.

## Usage

```
/spec:history {feature}
```

| Argument | Required | Description |
|----------|----------|-------------|
| feature | Yes | Feature name (folder under .kiro/specs/) |

## Examples

```bash
/spec:history bug-trace
/spec:history ralph-wiggum
```

## Execution Steps

1. Validate feature folder exists at `.kiro/specs/{feature}/`
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
