# DONE - 2026-03-22
## Completed
- .kiro消失問題 完全解決（根本原因: AIのBash破壊的コマンド + worktree force remove）
- block-kiro-destructive.sh: 8パターンの破壊的コマンドをPreToolUseでブロック
- kiro-watchdog.sh: 全ツール後に.kiro/存在確認、消失時自動復元
- 3層防御完成: 予防 + 検知復元 + 環境隔離
## Next
- git pull --rebase → Skills検証バグ → browser-use MCP
- deploy.ps1に新フック追加（P1）
