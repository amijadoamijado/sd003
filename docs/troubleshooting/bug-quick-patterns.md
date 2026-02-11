# Bug QUICK - Common Difference Patterns

> Reference guide for `/bug-quick` - Frequently found flow differences

---

## Boundary Conditions (Most Common)

### Pattern 1: "or more" vs "exceeds"

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "100,000 yen **or more**" | "**exceeds** 100,000 yen" | 100,000 included vs excluded |

**Real-world impact**: User expects approval at exactly 100,000, but code requires 100,001+

### Pattern 2: "up to" vs "less than"

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "**up to** 10 items" | "**less than** 10 items" | 10 included vs excluded |

### Pattern 3: "between" ambiguity

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "between 1 and 10" | "from 1 to 10" | Are endpoints included? |

**Tip**: Always clarify: "1 to 10, including both" or "greater than 1 and less than 10"

---

## Order & Sequence

### Pattern 4: Step ordering

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "First validate, then save" | "Save first, validate after" | Order reversed |

**Real-world impact**: Invalid data might be saved before validation catches it

### Pattern 5: Timing of checks

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "Check permission before action" | "Do action, then check" | Check timing |

---

## Missing or Extra Steps

### Pattern 6: Hidden default behavior

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "If not found, show error" | "If not found, use default value" | Silent fallback |

**Real-world impact**: User never sees error, wonders why "wrong" value appears

### Pattern 7: Extra validation

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "Accept any input" | "Also check format" | Hidden requirement |

### Pattern 8: Skipped step

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "Notify manager after approval" | [No notification code] | Feature missing |

---

## Condition Logic

### Pattern 9: AND vs OR

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "Both conditions must be true" | "Either condition is enough" | AND vs OR |

### Pattern 10: NOT handling

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "Unless marked as special" | "If not marked as regular" | Double negative confusion |

---

## Data Handling

### Pattern 11: Empty vs null vs missing

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "If no value, skip" | "Empty string is treated as value" | Empty != missing |

### Pattern 12: Case sensitivity

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "Match the name" | "Match exactly (case matters)" | "John" != "john" |

### Pattern 13: Whitespace

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "The text 'Hello'" | "' Hello ' with spaces" | Hidden whitespace |

---

## Japanese-Specific Patterns

### Pattern 14: Full-width vs half-width

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| Number "1" | Full-width "１" vs half-width "1" | Character encoding |

### Pattern 15: Date format

| Your Understanding | Code's Behavior | Difference |
|-------------------|-----------------|------------|
| "2024/01/15" | "2024-01-15" | Separator difference |

---

## Quick Reference Table

| Category | Watch For | Question to Ask |
|----------|-----------|-----------------|
| Boundary | >=, >, <=, < | "Is the exact value included?" |
| Order | First/then | "What happens first?" |
| Missing | Default behavior | "What if nothing matches?" |
| Logic | And/or/unless | "Do all conditions need to be true?" |
| Data | Empty/null | "What counts as 'no value'?" |

---

## Escalation Indicators

**Escalate to `/bug-trace` when:**

- [ ] Multiple patterns found in same flow
- [ ] Differences span multiple processes
- [ ] Pattern impact is unclear
- [ ] Fix location is not obvious
- [ ] Same difference found in multiple places

**Escalate to `/dialogue-resolution` when:**

- [ ] AI's code translation seems wrong
- [ ] Same misunderstanding repeats
- [ ] You and AI disagree on what code does
