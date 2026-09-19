---
name: ai-usage
description: "Claude Code、Codex (4アカウント)、Grok、Antigravity の残量クォータと次回リセット時刻を一目で表示 (Use when the user runs /ai-usage.)"
---

# AI Usage & Quota Monitor

SD003 custom command `/ai-usage` を Grok skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Grok Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Grok の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*`、`/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はGrok自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

## Original Command Body
# AI Usage & Quota Monitor

Claude Code、OpenAI Codex（複数アカウント）、Antigravity (agy)、Grok の現在の利用枠・残量パーセント・次回リセット時刻を一目で確認します。

## 実行手順

PowerShell または Bash で以下を実行してください:

```bash
python scripts/ai-usage-monitor.py
```

## Codex アカウントの管理手順

Codexで別のアカウントに切り替えた際は、以下のコマンドでスナップショット保存しておくことで、以降は再ログイン不要で残量確認および切り替えができます:

- **現在のアカウントを保存**:
  ```bash
  python scripts/ai-usage-monitor.py --save-codex acc2
  ```
- **アカウントのワンタッチ切り替え**:
  ```bash
  python scripts/ai-usage-monitor.py --switch-codex acc2
  ```
- **保存済みアカウント一覧**:
  ```bash
  python scripts/ai-usage-monitor.py --list-codex
  ```
