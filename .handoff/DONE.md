# 引き継ぎ（DONE.md）— 2026-07-06 09:52

## 完了
- **PR #1 ローカルマージ・クローズ**（sd003本体）: `git merge-tree`で無競合確認後、ローカルgitで`--no-ff`マージ（d571998）。push・ブランチ削除・PR MERGED確認済み。
- **SD003フレームワーク自体のバージョン番号アップ（v3.4.0 / template v2.15.0）**（commit d26f6c3）。push確認済み。
- **fleet upgrade 4件完了**（foreground・ゾンビ無し確認済み）: ss001(70cb1f8), rc001(86a16f0), cf002(82a54b2), ck001(ab61a23)。
- **fleet upgrade 2件処理中**（バックグラウンド、9:50時点でat001処理中の可能性、自然完了に任せた・強制終了せず）: at001, at002。要結果確認。

## 未完了（次のステップ）
- **at001・at002の結果確認が最優先**: `<scratchpad>/upgrade-logs/RESULTS2.log`を確認（scratchpadはセッション固有のため次回セッションでは消えている可能性大→無ければ`git -C /d/claudecode/at001 log -1`等で直接確認）。
- **未着手9件**: nm002(keep), fl006(keep), cf001(feature branch・安全確認済み), cr001, nl001, er001, ta001（＋at001/at002が失敗していた場合も）。
  - nm002/fl006/cf001は標準バッチ（`batch-upgrade2.sh`）でそのまま処理可。
  - **cr001**: `src/`196ファイルが初回コミット未実施の実アプリコード。`git add -A`後`git restore --staged src`で除外し、フレームワークのみcommit。srcの扱いは別途ユーザー確認。
  - **nl001**: `.tmp/`985件の無害キャッシュ削除に混ざり、`src/deckgen/*`実修正6件+新規テスト1件が混在。同様に該当パスを`git restore --staged`で除外。
  - **er001**: `.gitignore`に`node_modules/`(13,192ファイル・未登録)を追記してから実行。さもないと`git add -A`で誤コミットする。
  - **ta001**: 既存手順どおり（framework-onlyでcommit、web/tests 4件温存）。
- 全13件完了後、fleet再audit + Artifact最終更新（42/42）。
- 未PR・未マージのワークツリーブランチ`claude/epic-sutherland-41d93f`の扱い方針が未確認。

## 重要な発見（P1・要本格調査）
- **フリート横断のPostToolUse:Read問題**: cf002の`.sd003-keep`検証失敗を調査した結果、Claude Code CLIでは`hooks.PostToolUse`に`matcher:"Read"`を登録しても確実に発火しない既知バグが2026-07-04/05にcf002で実地検証済み（`D--claudecode-cf002`名前空間メモリ`reference_posttooluse_read_limitation`）。**sd003本体の正準テンプレート`settings.json.template`、および現在稼働中のsd003本体自身の`.claude/settings.json`も`track-skill-read.sh`を`PostToolUse:Read`のまま**にしており、`enforce-skill-read.sh`のスキル既読ゲートがフリート全体で機能不全の疑いがある。ただしcf002メモリの07-05追記では「PreToolUseへ移設後もログが記録されなかった」ともあり根本原因は未特定。**早合点で正準テンプレートを書き換えず、`/bug-trace`等でsd003本体で再現検証してから対処すること。**

## 重要な注意
- **ゾンビプロセス**: `run_in_background`の"killed"通知は実プロセス停止を保証しない。実行後は必ず `Get-CimInstance Win32_Process`（CommandLine match `upgrade\.sh|deploy\.sh`）で残存確認。**今回、バックグラウンド化したバッチを9:50の終了指示後も強制終了せず自然完了させた**（正しい判断・キル動作自体がゾンビの原因になり得るため）。
- **`.sd003-keep`保護ファイルは無条件に安全ではない**: cf002のケースのように、フリート横断の既知バグ回避策を含む場合がある。機械的にテンプレートで上書きする前に中身を確認すること。
- **`.claude/settings.json`への直接書き込みは自動modeがブロックしうる**（自己変更検知）。ユーザーの明示承認（AskUserQuestion経由）を得てから実施する。
- **nul問題**: Windows予約名`nul`ファイルが`git add -A`をabortさせる→`.gitignore`に`nul`/`NUL`追記で回避（batch-upgrade2.sh組込済み）。

## 関連ファイル
- sd003本体: `.claude/skills/sd-deploy/{deploy.ps1,deploy.sh,SKILL.md}`
- cf002修正: `D:\claudecode\cf002\.claude\settings.json`, `D:\claudecode\cf002\.sd003-keep`
- 作業スクリプト: `C:\AppData\Local\Temp\claude\D--claudecode-sd003\7d8b1a72-ce70-4781-b852-8210180d2112\scratchpad\batch-upgrade2.sh`（セッション固有・次回は再作成が必要な可能性）
- セッション詳細: `.sessions/session-current.md`（09:52追記あり）
