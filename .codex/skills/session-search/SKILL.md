---
name: session-search
description: Codex equivalent of the SD003 custom command `/session-search`. Use when the user invokes `/session-search`, `session-search`.
---

# セッション横断検索

この skill は Claude Code の `/session-search` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Codex Runtime Rules
- `.claude/commands/**/*.md` はClaude Code側のauthoring sourceです。直接変更せず、CodexではこのSkillを実行仕様として扱います。
- Claude Codeのスラッシュコマンド、`Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Codexの通常手順に翻訳します。
- Codex内で `/codex:review`、`/codex:rescue` などのCodexプラグインコマンドを再帰的に呼ばないでください。必要な読取・差分確認・編集・検証・報告をCodex自身で実施します。
- 人間向け出力、レビュー報告、質問、完了報告は日本語で書きます。
- `.sd/ai-coordination/` に依頼書・報告書を書く場合は、既存の案件ID配下に限定し、プロジェクトルートへ散らさないでください。
- Windows環境ではPowerShellで実行できるコマンドを優先し、bash専用の例はWSLやGit Bashが使える場合だけ採用します。

## Codex Native Execution Contract
このセクションはCodex実行時に `Original Command Body` より優先します。

- Claude Codeのスラッシュコマンド、`/workflow:*`、`/codex:*`、`Agent(...)`、`AskUserQuestion` は文字通り実行しない。
- Codex自身がファイル読取、差分確認、編集、検証、報告を直接行う。
- `.claude/commands/**/*.md` はauthoring sourceとして読むだけにし、Codex改善のために直接編集しない。
- 案件IDがない相談・レビューでは `.sd/ai-coordination/` に報告書を作らず、会話内で完結する。
- `.sd/ai-coordination/` に書くのは、案件IDが明示された正式Workflowの場合だけにする。
- WindowsではPowerShellで実行できるコマンドを優先し、bash例はWSL/Git Bashが使える場合だけ採用する。
- `.sd/` が存在しない場合は、その事実を報告し、可能なら軽量レビューまたは直接実装へ縮退する。

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
