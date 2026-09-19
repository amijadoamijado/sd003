---
name: ai-usage
description: "Claude Code、Codex (複数アカウント)、Grok、Antigravity の残量クォータと次回リセット時刻を一目で表示（どのプロジェクトからでも可）"
disable-model-invocation: true
---

# AI Usage & Quota Monitor

SD003 custom command `/ai-usage` をCodex/agy共通Agent Skillとして再現します。

User-provided arguments (if any): $ARGUMENTS

## Runtime Adaptation Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、実行中CLIの通常手順（ファイル読取・編集・検証・必要時のユーザー確認）に翻訳する。
- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは再帰実行しない。必要な作業は現在のCLIが直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。
- Codex固有の実行優先順位は `.codex/CODEX_NATIVE.md` に従う。

## Original Command Body
# AI Usage & Quota Monitor

Claude Code、OpenAI Codex（複数アカウント）、Antigravity (agy)、Grok の現在の利用枠・残量パーセント・次回リセット時刻を一目で確認します。

スクリプト実体は `D:\claudecode\sd003\scripts\ai-usage-monitor.py` の1か所のみ（各プロジェクトへコピーしない）。
どのプロジェクトから呼んでも、必ず絶対パスで実行すること。

## 実行手順

```bash
python -X utf8 D:/claudecode/sd003/scripts/ai-usage-monitor.py
```

## 結果の扱い

- Codexのローカル認証情報（`CODEX_HOME`、未設定なら `~/.codex/auth.json`）から分かるアカウントと、残量APIの取得成否を分けて報告する。403だけでログイン不明・期限切れと断定しない。
- ローカル認証ファイルと実行中アプリのログインが同じとは断定しない。JWTの参照は表示用であり、認証の有効性を証明しない。トークン本文を表示しない。
- 保存値は保存日時とともに明示し、現在残量や現在からの残り時間として扱わない。保存日時をログアウト日時と呼ばない。
- Antigravityの履歴件数は利用枠ではない。固定係数で残量やリセット時刻を推定しない。取得できない項目は未取得と報告する。
- 通常の残量確認では認証ファイルの保存・切替を行わない。管理コマンドはその操作を依頼された場合だけ使う。

## 管理コマンド

- **現在のアカウントを保存**:
  ```bash
  python D:/claudecode/sd003/scripts/ai-usage-monitor.py --save-codex <名前>
  ```
- **アカウント切り替え**（`--switch` 番号選択メニューは対話入力のため、ユーザーに `! python D:/claudecode/sd003/scripts/ai-usage-monitor.py --switch` で実行してもらう）:
  ```bash
  python D:/claudecode/sd003/scripts/ai-usage-monitor.py --switch-codex <名前>
  ```
- **保存済みアカウント一覧**:
  ```bash
  python D:/claudecode/sd003/scripts/ai-usage-monitor.py --list-codex
  ```
