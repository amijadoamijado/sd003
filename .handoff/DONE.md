# 引き継ぎ（DONE.md）— 2026-07-06 08:07

## 完了
- **SD003 upgradeツール根本修正（sd003本体 commit d9f00d5）**: `upgrade.sh`/`upgrade.ps1` のDELETEリストに07-05過剰設定撤去物（ralph/refactor/sd003-loop/workflow-impl/context系）を全root（.claude+.agents/.codex/.grok/.sd/commands mirror）でパージ追加。確認事項Artifact化ルール `artifact-confirmation.md` 新設（+CLAUDE.md/template）。dangling参照3件修正。
- **D:\claudecode 全登録PJへ最新SD003を一斉upgrade（29/42完了）**。各配信先で個別commit（push無し）。破損ゼロ・永久データ損失ゼロ。
- Artifact進捗ダッシュボード: https://claude.ai/code/artifact/0bbd9e8e-5a80-409e-a42e-330ca5421afd

## 未完了（次のステップ）
- **未着手13件のupgrade**: at001, ss001, ck001, cf001(feature branch), cr001, nl001, er001(feature branch), rc001, at002(keep完全), nm002, cf002, fl006, ta001。
  - 手順: `bash <scratchpad>/batch-upgrade2.sh <3件>` を **foregroundで3件ずつ**（**background禁止=ゾンビ事故防止**）。
  - registry.jsonは自動 .sd003-keep 保護。settings上書きはbackup退避。
  - **ta001**: framework-onlyでcommit（web/tests作業4件は温存＝`git add -A`後に`git restore --staged web tests`）。
- 全完了後にfleet再audit + Artifact最終更新（42/42）。

## 重要な注意
- **ゾンビプロセス**: `run_in_background`の"killed"通知は実プロセス停止を保証しない。実行後は必ず `Get-CimInstance Win32_Process`（CommandLine match `upgrade\.sh|deploy\.sh`）で残存確認し、あれば `Stop-Process -Force`。
- **nul問題**: Windows予約名`nul`ファイルが `git add -A` をabortさせる→`.gitignore`に`nul`/`NUL`追記で回避（batch-upgrade2.sh組込済）。
- **.sd/specs/ralph-wiggum** 等の旧spec/archive/commands_backupは保護領域→残置（勝手に消さない）。

## 関連ファイル
- sd003本体: `.claude/skills/sd-upgrade/upgrade.{sh,ps1}`, `.claude/rules/global/artifact-confirmation.md`
- 作業スクリプト: `<scratchpad>/batch-upgrade2.sh`（再利用）, `<scratchpad>/upgrade-logs/`
- セッション詳細: `.sessions/session-20260706-080731.md`
