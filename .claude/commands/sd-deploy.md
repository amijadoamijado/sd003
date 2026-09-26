---
description: SD003フレームワークを新規プロジェクトに展開
allowed-tools: Read, Bash, Glob
---

# /sd-deploy

`.claude/skills/sd-deploy/SKILL.md` に従って展開する。コピーは `deploy.ps1` / `deploy.sh` が行い、手作業でファイルをコピーしない。
先に dry-run で上書き対象（`WILL OVERWRITE`）を確認し、固有化ファイルは `.sd003-keep` で保護してから本実行する。

## 入力

$ARGUMENTS
