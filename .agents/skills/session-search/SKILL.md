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

1. **TIMELINE検索**: `.sessions/TIMELINE.md` をGrepで検索し、該当行を表示
2. **セッション検索**: `.sessions/session-*.md` を全ファイルGrepで検索
3. **結果表示**: ファイル名（日付）・マッチ行・前後1行のコンテキストを表示

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
