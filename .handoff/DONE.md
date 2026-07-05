# DONE.md - 完了報告

## やったこと

**変更したファイル（主要）**
| ファイル | 変更内容 |
|---------|----------|
| `.claude/rules/global/known-unknowns.md` | 新設: 無知の知（4象限=GREEN/YELLOW/RED・blindspot pass・地図≠現場） |
| `.claude/skills/blueprint-gate/SKILL.md` | Phase 5.5 Blindspot Pass ＋ テンプレに Known Unknowns 節 |
| `_archive/removed-overengineering-20260705/` | Ralph Loop/リファクタリング/7段階workflow を撤去アーカイブ（72ファイル） |
| `.claude/rules/workflow/ai-coordination.md` | 7段階workflow除去→軽量dispatch版へ書換 |
| `.claude/skills/sd-deploy/{deploy.sh,ps1,templates/*}` | 撤去の配信伝播＋Stop配線に正規フック配線 |
| `.claude/rules/workflow/artifact-output-location.md` / `scripts/recover-agy-artifacts.sh` | agy成果物のプロジェクト内保存＋回収 |
| `.eslintrc.cjs` / `.claude/hooks/{enforce-spec-location,track-skill-read,enforce-skill-read,session-skill-suggest}.sh` | P2修正（Lint gate/B17/B18） |

**変更内容の要約**
過剰設定（Ralph Loop・リファクタリングシステム・7段階workflow）を撤去し、逆に無知の知（Known Unknowns 4象限）を統合。両者を同じ判断軸「地図≠現場／強いモデルの失敗は静か→未知を表面化せよ・儀式は足枷」で貫いた。加えてP2 3件解消・agy成果物問題修正・ta001の.kiro→.sd根本対処（未コミット保留）。

## 確認結果
```
build OK / lint 0error / 撤去後 temp deploy: Content verification C1-C6 全PASS
skill-read B18: 10/10 E2E PASS / spec-location B17: 全ケース期待通り
ta001: pipeline-history が .sd/ から state読込を機能検証
全commit(294d35f/f5d3c7b/5f628f0/6c7de64/546c404) master push済み・remote同期
```

## 残っていること
- [ ] ta001 コミット（ステージ済み・ユーザー指示で保留。「ta001 コミットして」で実行）
- [ ] 配信先へ `/sd-upgrade` 反映（過剰設定撤去は破壊的→慎重に）
- [ ] bl001にYELLOW=条文確認ラベル適用（bl001着手時）

## 判断したこと
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 撤去は削除 vs アーカイブ | `_archive/`へgit mv | rm禁止・履歴保持・復元可 |
| 4象限をフォーム/クイズ化 vs しない | しない | 検出不能なUnknown Unknownのゲート化は次のRalph Loop（儀式） |
| ta001 .kiroを掃討 vs 根本対処 | 根本対処 | 実データ（実行中パイプライン）と判明。掃討は破壊的 |
| ta001 コミット vs 保留 | 保留 | ユーザーがAskで選択 |

## 追加情報
- 「sd003完成」= 無知の知の統合をもってユーザーが宣言。
- git-bash/WSL落とし穴: python subprocess['bash']はWSL拾う→git-bash明示（メモリ化）。
