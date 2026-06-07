# DONE — 引き継ぎ（2026-06-07 後半）

## 完了事項
- **nm002 を最新 sd003 へ更新**: `/sd-upgrade --execute`（308新規・廃止物除去）＋ settings.json をテンプレで全hook配線 → verifier C1-C6 全PASS。CLAUDE.md は既存尊重（`.sd003-keep` に登録して保護）。
- **deploy.sh の settings.json 上書きバグを根本修正**（`952ef66`）: 既存 settings.json を SKIP していた（deploy.ps1 は上書き）→ upgrade しても古い配線が直らなかった真因。`is_kept`（.sd003-keep）保護時のみ SKIP、それ以外は再生成（上書き）に変更。heredoc の OS対応は維持。3シナリオ実機検証済み。
- （同日前半: Phase 6b 内容検証ゲート実装＋レビュー対応＋at002修復＋GEPA/SkillOpt批判レビュー）

## 未完了 / 次のステップ
- P1: 残り現役配信先（oc001/fw5yp/sb001/er001等）を `/sd-upgrade` で最新化。固有CLAUDE.mdがあれば事前に `.sd003-keep` へ `CLAUDE.md` 登録。各々 verifier で C1-6 PASS 確認。
- P2: settings.json 真実源の単一化（template/ps1コピー/sh heredoc の3分散）。Windows専用なら優先度低。

## 関連ファイル
- `.claude/skills/sd-deploy/deploy.sh`（settings.json 上書き修正）
- `scripts/verify-deployment.mjs`（手動検証: `node scripts/verify-deployment.mjs <target> D:\claudecode\sd003`）
- `.claude/skills/sd-upgrade/upgrade.sh`（`<target> [--execute]`、既定dry-run）

## 注意
- deploy/upgrade はデフォルトで CLAUDE.md をテンプレ再生成する。**固有CLAUDE.mdを持つ配信先は `.sd003-keep` に `CLAUDE.md` を登録必須**（nm002は対応済）。
- 今後 `/sd-upgrade` だけで既存配信先の settings.json も最新化される（SKIPバグ解消済）。
- コミット時に post-commit hook(L4) が `.sd/` を HEAD から自動復元する。
