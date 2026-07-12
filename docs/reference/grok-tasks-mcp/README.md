# Grok Native Task Scheduling — MCPツールスキーマ

Grokネイティブの「予定タスク」機能（`create` / `list` / `update` / `pause` / `delete` / `get_results`）の
inputSchema定義。2026-07-12、Grok Lead mode正式化（`.grok/GROK_NATIVE.md`）作業時に参照用として取得。

再発防止メモ: 元は取得直後にプロジェクトルート直下 `mcps/` に取り残されていた（迷子ファイル）。
`.claude/rules/cleanup/file-organization.md`に従い`docs/reference/`へ移動。

## ファイル

| ファイル | 用途 |
|---------|------|
| `create.json` | 予定タスク作成（RRULE cadence指定） |
| `list.json` | アクティブなタスク一覧取得 |
| `update.json` | 既存タスクの更新 |
| `pause.json` | タスクの一時停止 |
| `delete.json` | タスクの削除 |
| `get_results.json` | 実行結果の取得 |

## 参照元

`.grok/GROK_NATIVE.md`
