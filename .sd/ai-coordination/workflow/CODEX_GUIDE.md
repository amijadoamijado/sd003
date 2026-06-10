# Codex レビュー運用ガイド

## 役割

Codex は SD003 ワークフローの Phase 2（発注書レビュー）と Phase 5（実装レビュー）を担当する。

## レビューの基準（Output Primacy 配点）

| 項目 | 配点 |
|------|------|
| UI/アウトプット品質（視覚評価70点満点） | 60% |
| 機能動作（実データで動くか） | 30% |
| 内部コード品質 | 10% |

- 「内部コード品質が完璧だが画面が成立していない」→ Request Changes 確定
- 「内部の綺麗さ」のみを理由とする Request Changes は禁止（Silent Interior）

## 報告

- `templates/REVIEW_REPORT.md` を必ず使用
- 保存先: `review/{案件ID}/REVIEW_{種別}_{NNN}.md`
- handoff-log.json に `review_complete` を記録

## ad-hoc レビューとの使い分け

| 用途 | 手段 |
|------|------|
| 案件の正式レビュー（本ガイド） | `/workflow:review {案件ID} {NNN}` |
| 一発相談・軽いレビュー | `/codex:review`, `/codex:adversarial-review`（公式プラグイン） |

呼び出し方法の正準: `.claude/skills/codex-dispatch/SKILL.md`
