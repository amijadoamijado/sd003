# Antigravity Pipeline Enhancement 技術設計書

## 基本情報
- **機能名**: Antigravity Pipeline Enhancement
- **バージョン**: 1.0.0
- **ステータス**: 実装中
- **作成日**: 2026-02-15

## 1. アーキテクチャ概要

### 1.1 4-Agent パイプライン構成

```
Claude Code (計画・指揮)
    │
    ├── /workflow:request → IMPLEMENT_REQUEST作成
    │       │
    │       └── /workflow:impl → Gemini CLI実装（自動連鎖）
    │               │
    │               └── /workflow:review → Codexレビュー（自動連鎖）
    │                       │
    │                       └── /workflow:test → Antigravity E2Eテスト（自動連鎖）
    │
    └── /workflow:status → 工程状況確認
```

### 1.2 コンポーネント構成

| コンポーネント | ファイル | 種別 |
|--------------|---------|------|
| テストコマンド | `.claude/commands/workflow-test.md` | Claude Codeコマンド |
| テストコマンド(Gemini) | `.gemini/commands/workflow-test.toml` | Gemini CLIコマンド |
| 運用ガイド | `.kiro/ai-coordination/workflow/ANTIGRAVITY_GUIDE.md` | ドキュメント |
| テストスクリプト | `scripts/agent-test.sh` | Bashスクリプト |
| 統合パイプライン | `scripts/agent-pipeline.sh` | Bashスクリプト（既存拡張） |

## 2. 自動連鎖設計

| 連鎖 | 動作 | 理由 |
|------|------|------|
| impl → review | 強制実行 | レビューは必須 |
| review(Approve) → test | 自動作成 + 提案 | TEST_REQUESTは自動作成、テスト実行はAntigravity可用性に依存 |

## 3. スクリプト設計

### 3.1 agent-test.sh フロー

```
Step 1: TEST_REQUEST存在確認 → 不在: エラー終了
Step 2: Antigravityディスパッチ → CLI不在: 手動モード
Step 3: TEST_REPORT存在確認 → 不在: 待機案内
Step 4: handoff-log更新案内
```

### 3.2 agent-pipeline.sh 拡張

```
Step 1: Gemini CLI実装（既存）
Step 2: Auto Apply & Commit（既存）
Step 3: Codex レビュー（既存）
Step 4: Antigravity E2Eテスト（新規）← --skip-testでスキップ可能
```

## 4. ファイル配置ルール

| 種別 | 保存先 |
|------|--------|
| テスト依頼 | `workflow/spec/{案件ID}/TEST_REQUEST_{NNN}.md` |
| テスト報告 | `workflow/review/{案件ID}/TEST_REPORT_{NNN}.md` |
| テストログ | `workflow/log/{案件ID}/test-{NNN}.log` |

---
最終更新: 2026-02-15
