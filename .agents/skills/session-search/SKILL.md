---
name: session-search
description: Codex equivalent of the SD003 custom command `/session-search`. Use when the user invokes `/session-search`, `session-search`.
---

# セッション横断検索

この skill は Claude Code の `/session-search` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Original Command Body
# セッション横断検索

過去のセッション記録とTIMELINEからキーワードで横断検索する。

## 引数

$ARGUMENTS — 検索キーワード（必須）

## 実行手順

1. **TIMELINE検索**: Grep tool で `.sessions/TIMELINE.md` を検索（output_mode: content, -C: 1）
2. **セッション全文検索**: Grep tool で `.sessions/` 配下の `session-*.md` を検索（glob: "session-*.md", output_mode: content, -C: 1）
3. **結果ソート**: ファイル名の日付部分（YYYYMMDD）でソートし、新しい順に表示
4. **件数制限**: マッチが10件以上ある場合、新しい方から上位10件に絞る（head_limit: 50）
5. **結果整形**: 下記フォーマットに整形して表示

## 出力フォーマット

```
## TIMELINE ヒット
| 日付 | 内容 | セッションファイル |
|------|------|-------------------|
| ... | ... | ... |

## セッション詳細ヒット
### [session-YYYYMMDD-HHMMSS.md]
> マッチ行（前後1行コンテキスト付き）

（N件中 上位10件を表示）
```

## ルール

- 検索対象: `.sessions/` 配下の `.md` ファイルのみ
- マッチが多い場合は上位10件に絞る（ファイル更新日が新しい順）
- キーワードが日本語・英語どちらでも検索可能
- ヒットなしの場合は「該当なし」と表示

## 関連コマンド

| コマンド | 用途 |
|---------|------|
| `/sessionhistory` | TIMELINE全体を俯瞰 |
| `/sessionread` | 最新セッションを読み込み |
| `/session-search` | **キーワードで横断検索（本コマンド）** |
