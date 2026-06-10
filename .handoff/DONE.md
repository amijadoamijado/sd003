# DONE.md - 完了報告（2026-06-10 20:29 セッション）

---

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `D:\claudecode\ss001\`（コミット 068eb07） | /sd-upgrade展開: v3.1.0→v3.2.0（290ファイル）。dry-run 40 divergence全件精査→固有化ゼロ判定（.sd003-keep不要）。廃止物13件（.gemini/・gemini.md・claude-memスタブ等）をバックアップ退避 |
| `ss001/.gitignore` | バックアップ除外3パターン追加（.sd002-backup-*/ .sd003-backup-*/ .sd003-upgrade-backup-*/） |
| `ss001/.claude/skills/sd-deploy/templates/` | 旧FW残骸2件（gemini.md.template / antigravity-rules.md.template）をバックアップへ退避 |

**変更内容の要約**
ユーザー指示「ss001にsd003を展開」を完遂。ss001は既存SD003（v3.1.0）だったため
deploy ではなく upgrade 手順を適用。dry-run→仕分け→execute→verify（C1〜C6全PASS）。
sd003本体のコード変更なし。

---

## 検証コマンド

```bash
bash .claude/skills/sd-upgrade/upgrade.sh <target>            # dry-run
bash .claude/skills/sd-upgrade/upgrade.sh <target> --execute
node scripts/verify-deployment.mjs <target> <source>
```

## 検証結果

- ss001: 432コピー+7生成、kept 0、C1〜C6全PASS、17 hooks配線健全
- Skills 118/119 FAILは誤報（期待値がoptional除外3件を含むsource総数。commで欠落ゼロを実証）
- コミット後の .sd/ wipeなし（HEAD=作業ツリー一致、10ファイル）
- ユーザー業務データ（materials/csv・output/tkc-yayoi・scripts/tkc-yayoi）は未コミットのまま温存

---

## 未完了・次のステップ

- [ ] P1: 残り配信先（oc001/fw5yp/sb001/er001等）への /sd-upgrade（C:空き25.25GBで実施可能）
- [ ] P2: deploy.ps1 Phase 6のSkillsカウント修正（optional除外を期待値に反映、118/119型誤報の根絶）
- [ ] P2: deploy共通化Stage1（generate-framework-files.mjs）/ メモリ逼迫恒久対策
- [ ] ss001のnpm install未実行（gas-fakesテスト利用時のみ必要）

## 引き継ぎ

- 次のタスク: 残り配信先への /sd-upgrade 展開（手順確立済み）

**判断記録**
| 判断ポイント | 採用 | 理由 |
|--------------|------|------|
| ss001への「展開」: deploy vs upgrade | upgrade | 既存SD003 v3.1.0入りと判明。「展開=新規deploy」と機械的に解釈しない |
| 40 divergenceの扱い: keep vs 全上書き | 全上書き（kept 0） | settings.json=旧テンプレ完全一致、CLAUDE.md=独自追記なし等、全件が古いFWと客観確認 |
| Skills 118/119 FAIL | 誤報と判定し続行 | commでファイルリスト差分を実証（欠落ゼロ＋超過側残骸2件）。at002 114/115と同型 |
