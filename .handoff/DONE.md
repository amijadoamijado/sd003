# DONE.md - 完了報告（2026-06-10 20:52 セッション）

---

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `.claude/skills/sd-deploy/templates/git-hooks/pre-commit` | 自動ステージ後に `.sd/` 全体を `.git/sd-snapshot/` へ複製する処理を追加 |
| `.claude/skills/sd-deploy/templates/git-hooks/post-commit` | wipe検知を「ディレクトリ全消失」→「スナップショット基準のファイル単位」に変更。欠損のみ復元、不在時HEADフォールバック |
| `.claude/rules/git/sd-safe-commit.md` | L4強化を反映。改善候補2件（partial wipe検知/未commit保護）を実装済みに更新 |
| `docs/bug-workaround-sunset.md` | L4行をスナップショット方式に更新 |
| `.git/hooks/`（管理外） | 新hook導入＋`.git/sd-snapshot` 初期化（58ファイル） |

**変更内容の要約**
ユーザー「.sd/ wipe これ改善できないのか」→ L4防御をスナップショット方式に強化。
旧L4の2限界（partial wipe非検知・未commit分喪失）を解消。バグ自体（#34330）は上流なので発生は止められない。

---

## 検証コマンド

```bash
bash /c/AppData/Local/Temp/sd003-staging/test-sd-hooks.sh   # temp repo 17ケーステスト
bash .git/hooks/post-commit                                  # 手動復元（wipe発生時）
```

## 検証結果

- temp repoテスト17ケース全PASS（full/partial復元・残存不可侵・意図的削除非復活・HEADフォールバック・未commit保護）
- 実弾実証2回: mid-session wipe 58ファイル復元（手動実行）/ commit時wipe 58ファイル自動復元
- **新観察**: wipeはpre-commit実行前に発火（=Bashツール起動時のrefreshの可能性が高い）

---

## 未完了・次のステップ

- [ ] P1: 残り配信先（oc001/fw5yp/sb001/er001等）/sd-upgrade ＋ **ss001/at002/nm002へ新hooks再展開**（本日のupgradeは旧hook）
- [ ] P2: sd-watchdogのスナップショット復元型拡張（mid-session wipe対応）— 「警告のみ」は意図的設計のため**ユーザー判断待ち**
- [ ] P2: deploy.ps1 Phase 6 Skillsカウント修正（118/119型誤報）/ deploy共通化Stage1 / セッションアーカイブ

## 引き継ぎ

- wipe発生時の手動復元: `bash .git/hooks/post-commit` 一発（snapshot/HEADから欠損分のみ復元）

**判断記録**
| 判断ポイント | 採用 | 理由 |
|--------------|------|------|
| 復元の正本: HEAD vs スナップショット | `.git/sd-snapshot/`（HEADフォールバック付き） | `.git/`内はruntime refresh対象外。commit時点の未commit分も守れる |
| sd-watchdog（mid-session）も復元型にするか | 今回は見送り | 「警告のみ」は意図的設計。変更はユーザー判断を仰ぐ |
| テスト方法 | temp使い捨てrepoで17ケース | 本物の.sd/を実験台にしない。実弾wipe 2回が追加実証になった |
