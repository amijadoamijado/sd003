---
name: source-command-sessionread
description: Legacy alias for sessionread. Use only when source-command-sessionread is explicitly requested.
---

# source-command-sessionread

旧名との互換性のための入口。引継ぎの実行手順は `sessionread` に一本化する。

このスキルを呼び出されたら、同じスキル配置先の `../sessionread/SKILL.md` を読み、その手順に従う。既に読んでいれば再読不要。ユーザーの引数・依頼範囲はそのまま引き継ぐ。

独自の読込順序、履歴全体の読込、追加の確認工程は設けない。参照先が存在しない場合は欠落を報告し、旧手順を推測して実行しない。
