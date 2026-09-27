# DONE.md - 完了報告（2026-09-27 18:16 Claude Code セッション）

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `scripts/run-hook.js` | 自前の子プロセスごと強制終了の期限を既定100秒から25秒へ変更。`--deadline=<秒>` 引数を追加。環境変数で指定された bash は起動確認を省く |
| `.claude/skills/sd-deploy/templates/settings.json.template` | run-hook 経由の hook の timeout を5・10秒から30秒へ上げた（16件）。block-commit-on-test-fail に `--deadline=110`、agent-review に `--deadline=590` |
| `.claude/settings.json`（git 管理外） | テンプレートと同じ変更 |

**変更内容の要約**
PostToolUse hook が51分停止した件の修正。高負荷時に hook が timeout を超えると、Claude Code は node だけを kill し、残った bash がパイプを握り続けていた。run-hook.js の自前強制終了が timeout より後に設定されていて発動していなかったため、timeout より前に発動するよう直した。

---

## 確認結果

- 各 hook を個別に計測: 修正前 6.5〜10.6秒 → sd-watchdog は 1.8秒
- `sleep 60` を2本抱える hook を `--deadline=3` で実行 → 4.9秒で戻り、プロセスの残り0
- 修正の commit（a6851b6）で block-commit-on-test-fail（`--deadline=110`）が正常に通過

---

## 残っていること

- [ ] 配布先へ run-hook.js・テンプレートを展開（`/sd-upgrade`。settings.json・run-hook.js を `.sd003-keep` で保護している配布先は手動）
- [ ] 未追跡の `.sessions/session-20260926-131310.md`、本セッション外の未 commit 変更（`.claude/commands/sessionwrite.md`, `scripts/ai-usage-monitor.py`）の扱い
- [ ] aa001 のテストが powershell（DriveType の問い合わせ）を多重起動して全 PJ を重くする件

---

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| timeout を上げるだけ | 不採用 | Claude Code が kill すると孫が残る問題は解決しない |
| run-hook の自前期限を timeout より前に置く | 採用 | taskkill /T で子プロセスごと止められる（実測で残り0） |
| 既定期限 4秒（timeout 5秒のまま） | 不採用 | 高負荷時に保護 hook が素通りする。25秒・30秒で余裕を持たせた |
