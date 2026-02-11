# Ralph Loop Operation Rules

## Phase-Based Application

| Phase | Ralph Loop | Completion Condition |
|-------|------------|---------------------|
| Early (Phase 1) | Not used | - |
| Midpoint (Phase 2-3) | **Active** | All tests pass |
| Endgame (Phase 4-5) | Max 2 attempts | Same error 2x -> dialogue-resolution |

## Commands

### Primary (Midpoint Phase)
```bash
/sd002:loop-test    # Loop until all tests pass
```

### Supplementary
```bash
/sd002:loop-lint    # Loop until ESLint 0 errors
/sd002:loop-type    # Loop until TypeScript strict passes
```

## Escalation Protocol

### Midpoint Phase
- Use Ralph Loop freely
- No escalation limit
- Stop when tests pass or max iterations reached

### Endgame Phase
```
Same error pattern 1st time -> Ralph auto-fix
Same error pattern 2nd time -> Stop, escalate to /dialogue-resolution
```

## Stop Hooks

| Hook | Phase | Purpose |
|------|-------|---------|
| `sd002-stop-hook.sh` | Midpoint | Loop until completion promise |
| `sd002-stop-hook-endgame.sh` | Endgame | Track error patterns, escalate on 2nd occurrence |

## Environment Variables

```bash
SD002_MAX_ITERATIONS=20       # Max loop iterations
SD002_COMPLETION_PROMISE="ALL_TESTS_PASS"  # Success marker
```

## Integration with SD002 Philosophy

This implements the SD002 error learning principle:

1. **1st error occurrence**: Allowed, auto-fix attempted
2. **2nd same error**: Warning, final Ralph attempt
3. **3rd same error**: Escalate to human collaboration

The Ralph Loop automates steps 1-2. Step 3 requires `/dialogue-resolution`.

## Best Practices

1. **Set clear completion promises** - Use specific markers like `ALL_TESTS_PASS`
2. **Use appropriate phase hooks** - Midpoint vs Endgame
3. **Don't over-iterate** - Set reasonable `max-iterations`
4. **Escalate when stuck** - Use `/dialogue-resolution` for persistent issues

---

## Night Mode (Ralph Wiggum)

夜間自律実行用の拡張システム。詳細: `.kiro/ralph/README.md`

### Two-Layer Architecture

| 項目 | 日中（sd002-loop-*） | 夜間（Ralph Wiggum） |
|------|---------------------|---------------------|
| コマンド | `/sd002:loop-*` | `/ralph-wiggum:*` |
| max-iterations | 15-20 | 60 |
| 環境変数 | `SD002_*` | `RALPH_*` |
| 完了マーカー | `ALL_TESTS_PASS` | `RALPH_NIGHTLY_COMPLETE` |
| リカバリー | dialogue-resolution | 7パターン自動 |
| 人間介入 | 随時可能 | ブロック時のみ |

### Night Mode Commands

```bash
/ralph-wiggum:run     # 夜間キュー実行
/ralph-wiggum:status  # 実行状況確認
/ralph-wiggum:plan    # 週次計画作成
```

### Night Mode Environment Variables

```bash
RALPH_MAX_ITERATIONS=60
RALPH_COMPLETION_PROMISE="RALPH_NIGHTLY_COMPLETE"
RALPH_BLOCKED_PROMISE="RALPH_NIGHTLY_BLOCKED"
```

### 7 Recovery Patterns (Night Mode)

| Pattern | Description |
|---------|-------------|
| 1 | Build Error - 型エラー自動修正 |
| 2 | Test Failure - 実装/テスト修正 |
| 3 | Lint Error - --fix + 手動修正 |
| 4 | Infinite Loop - 適応的検知 + スキップ |
| 5 | External Dependency - サーキットブレーカー |
| 6 | Unexpected - graceful-exit（再開可能） |
| 7 | Recovery Exhaustion - スキップ + エスカレーション |

### Specification

- Requirements: `.kiro/specs/ralph-wiggum/requirements.md`
- Design: `.kiro/specs/ralph-wiggum/design.md`
