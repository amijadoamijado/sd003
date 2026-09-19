---
description: Claude Code、Codex (複数アカウント)、Grok、Antigravity の残量クォータと次回リセット時刻を一目で表示（どのプロジェクトからでも可）
allowed-tools: Bash, Read
---

# AI Usage & Quota Monitor

Claude Code、OpenAI Codex（複数アカウント）、Antigravity (agy)、Grok の現在の利用枠・残量パーセント・次回リセット時刻を一目で確認します。

スクリプト実体は `D:\claudecode\sd003\scripts\ai-usage-monitor.py` の1か所のみ（各プロジェクトへコピーしない）。
どのプロジェクトから呼んでも、必ず絶対パスで実行すること。

## 実行手順

```bash
python D:/claudecode/sd003/scripts/ai-usage-monitor.py
```

## Codex アカウントの管理手順

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
