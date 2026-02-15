# Antigravity Pipeline Enhancement 要件定義書

## 基本情報
- **機能名**: Antigravity Pipeline Enhancement - 4th Agent in AI Coordination Pipeline
- **バージョン**: 1.0.0
- **ステータス**: 実装中
- **作成日**: 2026-02-15
- **最終更新**: 2026-02-15

## 1. 概要

### 1.1 目的
Antigravityを4-Agentパイプラインの第4段階（E2Eテスト）として正式統合し、Claude Code（計画・指揮）→ Gemini CLI（実装）→ Codex（レビュー）→ Antigravity（E2Eテスト）の自動連鎖パイプラインを完成させる。

### 1.2 背景
- 既存の3-Agentパイプライン（Claude Code → Gemini → Codex）にE2Eテスト段階が欠如
- Antigravityはブラウザベースの探索的テスト・本番確認が可能
- 3-Tier テスト戦略のTier-3としてAntigravityを正式に位置付ける必要がある
- テスト依頼・報告のワークフローが未標準化

### 1.3 成功基準
- `/workflow:test` コマンドによるTEST_REQUEST自動作成
- `agent-test.sh` スクリプトによるAntigravityテストパイプライン実行
- `agent-pipeline.sh` への4段階目（Antigravity）統合
- ANTIGRAVITY_GUIDE.md による運用ガイド整備
- handoff-log.json への test_request/test_report 記録

## 2. 機能要件

### REQ-AP-001: /workflow:test コマンド
- **概要**: Antigravityへのテスト依頼（TEST_REQUEST）作成コマンド
- **入力**: 案件ID、タスク番号
- **処理**: テンプレート読み込み → TEST_REQUEST作成 → handoff記録 → ディスパッチ
- **優先度**: High

### REQ-AP-002: agent-test.sh テストパイプラインスクリプト
- **概要**: Antigravityテスト実行の4段階パイプラインスクリプト
- **オプション**: --dry-run, --manual
- **優先度**: High

### REQ-AP-003: agent-pipeline.sh 4-Agent統合
- **概要**: 既存3-Agentパイプラインに Antigravity E2Eテスト段階を追加
- **オプション**: --skip-test フラグ追加
- **優先度**: High

### REQ-AP-004: ANTIGRAVITY_GUIDE.md 運用ガイド
- **概要**: Antigravity向けのワークフロー運用ガイド作成（150行以上）
- **保存先**: `.kiro/ai-coordination/workflow/ANTIGRAVITY_GUIDE.md`
- **優先度**: High

### REQ-AP-005: 自動連鎖ルール
- **概要**: review(Approve) → test の自動連鎖を確立
- **優先度**: High

## 3. 非機能要件

### NFR-AP-001: 既存パイプラインとの互換性
- `--skip-test` オプションで従来動作を維持可能

### NFR-AP-002: 段階的導入
- Antigravity CLI未インストール環境での graceful degradation
- 手動モード（--manual）による非自動実行サポート

## 4. 禁止事項
1. `.antigravity/` ディレクトリへのテスト依頼書・報告書の作成
2. テンプレートなしでのTEST_REQUEST/TEST_REPORT作成
3. handoff-log.json への記録漏れ

---
最終更新: 2026-02-15
