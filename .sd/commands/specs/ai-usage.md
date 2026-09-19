---
slug: ai-usage
source: .claude/commands/ai-usage.md
description: Claude Code、Codex (複数アカウント)、Grok、Antigravity の残量クォータと次回リセット時刻を一目で表示（どのプロジェクトからでも可）
claude_command: /ai-usage
agent_skill: ai-usage/SKILL.md
allowed_tools: Bash, Read
---

# AI Usage & Quota Monitor

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Codex/Antigravity共通Agent SkillとGrok Skillはこのファイルから生成します。

## Original Body
# AI Usage & Quota Monitor

Claude Code、OpenAI Codex（複数アカウント）、Antigravity (agy)、Grok の現在の利用枠・残量パーセント・次回リセット時刻を一目で確認します。

スクリプト実体は `D:\claudecode\sd003\scripts\ai-usage-monitor.py` の1か所のみ（各プロジェクトへコピーしない）。
どのプロジェクトから呼んでも、必ず絶対パスで実行すること。

## 実行手順

```bash
python -X utf8 D:/claudecode/sd003/scripts/ai-usage-monitor.py
```

## 結果の扱い

- 現在アカウントの残量は公式 `codex app-server` の `account/rateLimits/read` で取得する（CLI必須、25秒で打切り）。会話・モデル実行・ログイン切替は行わない。保存済みアカウントの直接取得は公式実装と同じ `/backend-api/wham/usage` を使う。
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
