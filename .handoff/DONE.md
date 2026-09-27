# DONE.md - 完了報告（2026-09-27 21:35 Claude Code セッション）

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `.claude/skills/sd-deploy/templates/CLAUDE.md.template` | Build & Test・Quick Command Reference を削除し、Grok の段落を短縮（sd003 の CLAUDE.md と同じ変更） |
| `.agents/skills/sd-deploy/templates/*.template`, `.grok/skills/sd-deploy/templates/*.template` | `sync-cli-commands.py` で `.claude/` と同期（timeout・deadline・`--only` を含む） |

**変更内容の要約**
sd003 本体への変更を配布テンプレートと複製に反映した（1b828c6）。全配布先への展開は dry-run の途中。

---

## 確認結果

- `npx jest tests/deploy`: 9件すべて通過
- `.agents/` と `.grok/` のテンプレートが `.claude/` と一致することを diff で確認
- 配布先48件の dry-run: 21:35 時点で12件完了（変更なし）

---

## 残っていること

- [ ] **P0** 全配布先48件への sd-upgrade を完了する
  - dry-run の結果: `C:\AppData\Local\Temp\claude\D--claudecode-sd003\aeb11c4e-da60-4da7-8280-784b3d4ed36a\scratchpad\dryrun-result.json`
  - 固有化0件の PJ から `-Execute` で実行する
  - 作業ツリーがきれいな PJ だけ commit・push する
- [ ] upgrade 後、各 PJ で commit 時のテストが初めて本当に走る。隠れていた失敗が出る前提で見る
- [ ] 本セッション外の未 commit 変更（`sessionwrite.md` 系、`ai-usage-monitor.py`）の扱いを決める

---

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| dry-run の「失われる固有化」をそのまま信じる | 不採用 | 古い版の配布物も差として出るため、全件が固有化に見える |
| 差のあるファイルのハッシュが sd003 の履歴にあるかで判定 | 採用 | 過去の配布物と完全に一致すれば固有化ではない（at002 で実績あり） |
| 未 commit 変更が多い PJ でも commit する | 不採用 | 他の作業の変更と混ざるため |
