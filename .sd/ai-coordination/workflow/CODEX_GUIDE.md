# Codex 運用ガイド

Codexは公式品質印を担う。案件IDのないアドホックFast Reviewは `.codex/CODEX_NATIVE.md` に従い会話内で完結する。

Claude Lead時は `/codex:review` プラグイン、Codex Lead時は直接レビューする。正式レビュー時のみ自由形式の結果を `review/{案件ID}/` に保存する。依頼文書は `spec/{案件ID}/` 配下の自由形式とし、handoff-logは任意（AI間handoff発生時に1行推奨）。

## Output Primacy 配点

| 観点 | 配点 |
|---|---:|
| UI・ユーザーが受け取るアウトプット | 60 |
| 機能動作 | 30 |
| 内部品質 | 10 |

重大度順に、場所・影響・修正案・検証証拠を報告する。
