---
name: agy-dispatch
description: agyを非対話で安全に実行し、成果物をディスク検証する正準ラッパー。
disable-model-invocation: true
---

# agy-dispatch

`pwsh -File .claude/skills/agy-dispatch/agy-run.ps1 -Repo . -Out out.md -Prompt "依頼" -ExpectedArtifact path`

権限は `--sandbox --mode accept-edits` に固定する。brainに迷子になった成果物は `bash scripts/recover-agy-artifacts.sh` で回収する。E2E/画面確認はagy、独立検証はgrok-dispatch、コードレビューはcodex-dispatchを使う。
