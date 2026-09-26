---
slug: sd-deploy
source: .claude/commands/sd-deploy.md
description: SD003フレームワークを新規プロジェクトに展開
claude_command: /sd-deploy
agent_skill: sd-deploy/SKILL.md
allowed_tools: Read, Bash, Glob
---

# /sd-deploy

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Codex/Antigravity共通Agent SkillとGrok Skillはこのファイルから生成します。

## Original Body
# /sd-deploy

`.claude/skills/sd-deploy/SKILL.md` に従って展開する。コピーは `deploy.ps1` / `deploy.sh` が行い、手作業でファイルをコピーしない。
先に dry-run で上書き対象（`WILL OVERWRITE`）を確認し、固有化ファイルは `.sd003-keep` で保護してから本実行する。

## 入力

$ARGUMENTS
