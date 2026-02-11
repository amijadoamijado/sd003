# レビュー依頼: Auto Code Review Pipeline

## メタデータ
| 項目 | 値 |
|------|-----|
| 案件ID | 20260207-001-branch-review |
| レビュー番号 | 001 |
| 対象ブランチ | `claude/auto-code-review-ujVdH` |
| 対象コミット | `d5372e6` |
| コミットメッセージ | feat: Auto Code Review pipeline - Codex CLI integration via PostToolUse hook |
| レビュー依頼日 | 2026-02-07 |
| 依頼元 | Claude Code |
| レビュアー | Codex |

## 概要

git commitをトリガーとして、Codex CLIを自動起動しコードレビューを実行するPostToolUseフックの実装。

## 変更ファイル一覧（5ファイル）

| ファイル | 変更内容 |
|---------|---------|
| `.claude/hooks/agent-review.sh` | **新規** - Codex自動レビューフックスクリプト (183行) |
| `.claude/settings.json` | PostToolUseフック設定追加 |
| `.claude/hooks/.gitignore` | レビュー結果ファイルのgitignoreコメント追加 |
| `.gitignore` | `.codex-review-result.md` を除外対象に追加 |
| `.kiro/ai-coordination/handoff/handoff-log.json` | `auto_code_review` handoffタイプ追加 |

## レビュー観点

### 1. agent-review.sh（主要ファイル）
- シェルスクリプトの品質（set -euo pipefail、エラーハンドリング）
- セキュリティ: コマンドインジェクションリスクの有無
- stdin JSONパース（jq使用）の堅牢性
- git commitコマンドの検出ロジック（正規表現）の妥当性
- Codex CLI呼び出しのタイムアウト・フォールバック処理
- レビュー結果の出力形式の一貫性
- 大きなdiffの切り詰め処理（MAX_DIFF_LINES=2000）

### 2. settings.json
- PostToolUseフック設定の構造が正しいか
- タイムアウト値（120秒）の妥当性
- 既存のStopフック設定との共存

### 3. handoff-log.json
- 新しいhandoffタイプの定義が既存スキーマと整合しているか

## レビュー準備コマンド

```bash
# ブランチの差分確認
git diff master..claude/auto-code-review-ujVdH

# 変更ファイル一覧
git diff master..claude/auto-code-review-ujVdH --stat

# コミットログ
git log --oneline master..claude/auto-code-review-ujVdH
```

## レビュー結果保存先

```
.kiro/ai-coordination/workflow/review/20260207-001-branch-review/REVIEW_IMPL_001.md
```
