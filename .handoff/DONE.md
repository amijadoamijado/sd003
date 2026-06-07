# DONE — 引き継ぎ（2026-06-07）

## 完了事項
- sd-deploy に **Phase 6b 内容検証ゲート**を実装（配送への Work First 適用）。
  - 単一Node検証 `scripts/verify-deployment.mjs`（C1 hook配線=イベント単位照合 / C2 hook実在 / C3 テンプレ実プレースホルダ限定 / C4 廃止語 / C5 文字化け .sh+.ps1 / C6 JSON妥当性）。
  - `deploy.ps1` / `deploy.sh` に Phase 6b 配線＋検証失敗で **exit 1**（旧来は失敗してもexit 0）。verifier を配信先へもコピー。
  - 回帰テスト `tests/deploy/verify-deployment.test.ts`＋9f14984再現fixture。2件PASS。
- コードレビュー P2（C1イベント単位）/ P3（C5に.ps1）＋自己発見 C3誤検知 を根本修正。
- 現役 at002 のガードレール不活性（block-sd-destructive 未配線等）をゲートが捕捉→最新テンプレ上書きで修復（C1-6 全PASS）。
- GEPA・SkillOpt・DSPy のブリーフィング文書を一次情報で批判的レビュー（「JEPAR」=GEPAの誤記と確定）。

## 未完了 / 次のステップ
- P1: 他の現役配信先（oc001/fw5yp/sb001/er001等）を verifier で棚卸し。FAIL先は settings.json をバックアップ→最新テンプレ上書きで修復。
- P2: deploy に既存壊れ生成物の再生成手段（`--force-settings`相当）検討。C4 deny-list 拡充検討。

## 関連ファイル
- `scripts/verify-deployment.mjs`
- `.claude/skills/sd-deploy/{deploy.ps1,deploy.sh,SKILL.md,README.md}`
- `tests/deploy/verify-deployment.test.ts`, `tests/fixtures/deploy-broken-settings/.claude/settings.json`
- 手動再検証: `node scripts/verify-deployment.mjs <target> D:\claudecode\sd003`

## 注意
- deploy.ps1 は settings.json を `Copy-Item -Force` で**上書き**（テンプレ逐語コピー）。探索が報告した「SKIP(既存時)」は誤り。
- コミット時に post-commit hook(L4) が `.sd/` を HEAD から自動復元する（毎commitで .sd/ 全消失→復元が発生する実環境）。
