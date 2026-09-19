---
slug: ai-usage
source: .claude/commands/ai-usage.md
description: Claude Code、Codex (4アカウント)、Grok、Antigravity の残量クォータと次回リセット時刻を一目で表示
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
