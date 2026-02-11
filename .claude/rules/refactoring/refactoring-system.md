# リファクタリングシステム

## 概要
Context-efficient refactoring with autonomous session management and proposal-based rollback.

## Autonomy Levels
| Function | Level | Description |
|----------|-------|-------------|
| Context management | **Auto** | 70% compact, 85% clear |
| Session persistence | **Auto** | Auto-save on batch complete |
| Rollback | **Proposal** | User confirmation required |

## コマンド
| コマンド | 説明 |
|----------|------|
| `/refactor:init {scope}` | 3-agent並列分析で初期化 |
| `/refactor:plan` | バッチ実行計画を生成 |
| `/refactor:batch` | チェックポイント付きでバッチ実行 |
| `/refactor:rollback [target]` | チェックポイントに復元 |
| `/refactor:complete` | セッション終了 |

## ワークフロー

```
/refactor:init
    ├── [Parallel] Scope Agent
    ├── [Parallel] Pattern Agent
    └── [Parallel] Risk Agent
         │
         ▼
    /refactor:plan
         │
    ┌────┴────┐
    ▼         ▼
[Batch N]  [Failure]
    │         │
    ├─ Auto checkpoint
    ├─ Transform      └─ rollback-guard
    ├─ Quality gates      (proposal)
    ├─ Ralph Loop
    └─ Auto sessionwrite
         │
         ▼
    /refactor:complete
```

## スキル連携
| Skill | Purpose | Trigger |
|-------|---------|---------|
| `context-autonomy` | Auto compact/clear | 70%/85% threshold |
| `session-autosave` | Auto save | Batch complete |
| `rollback-guard` | Propose rollback | Test failure |

## 設定
`.kiro/refactor/config.json`

## 外部リソース
- **LSP**: `ENABLE_LSP_TOOLS=1` or cclsp MCP
- **Batch refactoring**: claude-skills-marketplace
