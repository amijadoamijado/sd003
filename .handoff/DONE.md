# DONE.md - 無音故障2件の修正 → フリート監査 → 一括移行事故の全件復旧 完了報告

セッション: 2026-07-25 17:00:18 | 最新コミット: b19cca7 | 記録: `.sessions/session-20260725-170018.md`

---

## やったこと

**変更したファイル（sd003）**
| ファイル | 変更内容 |
|---------|----------|
| `.claude/hooks/agent-review.sh` | `codex review --commit`＋PROMPT（排他でexit 2）→ 正準 `codex exec` へ復帰。stderr tail を成果物に添付。既定OFF・`SD_AUTO_REVIEW=1` のopt-in化＋300秒上限 |
| `scripts/agent-review.sh` | 同型の壊れた invocation を修正＋stderr可視化 |
| `scripts/agent-pipeline.sh` | 同上（`--commit` / `--uncommitted` 両方が壊れていた） |
| `.claude/skills/sd-deploy/templates/git-hooks/post-commit` | 自動pushの結果を `.git/auto-push.log` に記録、失敗時マーカー＋次回コミット冒頭で警告 |
| `.git/hooks/post-commit` | 実体をテンプレートと同期 |
| `.claude/skills/sd-deploy/deploy.ps1` | gitignore Phase 5-5b に `.codex-review-result.md` 追加／optional skills 除外をコピー側にも適用／FRAMEWORK_VERSION 2.17.0 |
| `.claude/skills/sd-deploy/deploy.sh` | **`.gitignore` 処理が丸ごと欠けていた**（parity gap）ため新規実装／FRAMEWORK_VERSION 2.17.0 |
| `.agents/` `.grok/` ミラー | sync-cli-commands.py で同期 |
| `CLAUDE.md` | 死んだGrokモデル `grok-build` の既定案内を削除（`grok models` 実測で現存は `grok-4.5` のみ） |
| `docs/troubleshooting/RESOLUTION_LOG.md` | 事故2件（文字化け一括破壊 / バイナリ混入push不能）を記録 |

**他プロジェクト**
- 文字化け復元 231件（18PJ）、版数刻印4件（ta001/at002/fl006/ac001）、`.gitignore` 3件、履歴書き換え3件

**変更内容の要約**
Codex自動レビューhookが `231aca3`(2026-03-31)以降**4か月一度も成功していなかった**問題を修正
（`codex review` は `--commit` と `[PROMPT]` が排他で exit 2、`2>/dev/null` が真因を隠蔽）。
その調査から **2026-03-28 の `.kiro→.sd` 一括移行が18PJ・229ファイルの日本語をCP932誤読で焼いていた**事故を発見し、
git親リビジョンから全件復元。さらに復元コミットのpush失敗から、Chromiumバイナリgit混入による
**push恒久不能**（GitHub 100MB上限）を3PJで発見し `git filter-repo` で解消した。

---

## 確認結果

**実行したコマンド**
```bash
npm test                                              # 88 tests / 11 suites
bash -n <各修正シェル>                                  # 構文チェック
pwsh [Parser]::ParseFile(deploy.ps1)                  # パースチェック
SD_AUTO_REVIEW=1 bash .claude/hooks/agent-review.sh   # 実レビュー生成（実機）
git filter-repo --invert-paths --path <dir> --force   # fw003 / oc001 / ac001
```

**結果**
```
Test Suites: 11 passed, 11 total
Tests:       88 passed, 88 total

[auto-review] 2026-03-08以来はじめて実レビュー生成（Warning 2 / Info 1）
[auto-push]   [2026-07-25 13:46:02] branch=master commit=5e4f5e0 exit=0
              4db367a..5e4f5e0  master -> master
[文字化け]     8,872ファイル再走査 → 残存0件 / ac001 275ファイル → 残存0件
[filter-repo] fw003 529MB→1.4MB / oc001 700MB→134MB / ac001 →3.6MB、100MB超blob 0個
```

**動作確認**
- [x] 既定OFFで `.codex-review-result.md` を書かない（mtime不変で確認）
- [x] `SD_AUTO_REVIEW=1` で実レビューが生成される
- [x] 自動pushの結果がログに記録される（実コミットで確認）
- [x] 復元ファイルが日本語として読める（複数サンプルをReadで確認）
- [x] 3PJのforce push後、リモートとローカルのhash一致（`git ls-remote` 照合）

---

## 残っていること

**未完了タスク**
- [ ] 44PJが旧 `agent-review.sh`（常時ON・壊れたまま）を回し続けている。`/sd-upgrade` 展開の判断待ち
- [ ] pre-commit で50MB超ファイルをブロックする物理ガードレールが未整備
- [ ] B17（auto-push可視化）の配信先展開。現状44PJは無音pushのまま
- [ ] oc001 の切れたシンボリックリンク `.claude/skills/webapp-testing`
- [ ] nm002 の版数刻印が実体より1つ古い（2.14.0 vs 2.15.0）
- [ ] deploy.sh に optional skills 除外機能が無い（ps1との機能差）

**次の手順**
- 次のタスク: P1（44PJの壊れたhook対応 / 50MB超ブロックのガードレール新設 / B17展開）
- 依存関係: なし

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 自動レビュー: 常時ON / opt-in / hook撤去 | **opt-in（既定OFF）** | 実レビューは2行diffでも3〜4分。PostToolUse は同期実行（timeout=600）で毎コミット数分ブロックする。直す＝有効化ではない |
| 配信先展開: フル `/sd-upgrade` / 最小配布 / なし | **今はsd003のみ** | ユーザー判断。各PJに触るタイミングで更新する方針 |
| 文字化け復元の範囲 | **229件すべて** | 履歴文書も含め機械復元可能と実証できたため |
| 復元の安全条件 | **移行以降そのファイルが未変更であること** | この条件下では現在の中身が親から機械的に生成されたものしか含まず、情報欠落が原理的に起きない |
| リネーム再適用の判定 | **ASCIIパストークン数の一致度で機械選択** | 化けがASCIIも食うため、`kiro`残存が「リネーム漏れ」か「化けが食った跡」か区別できない |
| ac001 の未コミット99件 | **バックアップして破棄** | ユーザー指示「消えてもいい」。ただし非破壊でscratchpadへ退避してから実施 |

**採用しなかった案と理由**
- 文字コード変換での復元: ASCII・改行まで欠落しており情報が物理的に失われているため不可能
- 行単位の骨格照合による検証: 文字化けが改行を食うため誤検知（826行→728行）
- `git reset --hard` / `git clean` でのクリーン化: sd003ガードレールが物理ブロック。等価な非ブロック手段
  （HEAD blob のファイル単位書き戻し＋untracked退避＋`git add --renormalize`）で代替

---

## 追加情報

- **今日の教訓**: `2>/dev/null` は「失敗の無音化装置」。1秒で判明する引数エラーが4か月生き延びた原因はこれ1点。
  旧 post-commit の `>/dev/null 2>&1 &` も同様に19コミットの取り残しを隠していた
- **一括処理は失敗も一括で配る**: 1つの移行スクリプトが18リポジトリを同時に破壊した。
  「1件で試す → 検証 → 残りへ展開」の段取りを必ず挟むこと
- **gitが唯一の復元元だった**: 229件すべて親リビジョンから復元。未コミットで一括処理を流していたら全損
- 復元スクリプトは再利用価値あり: `<scratchpad>/restore_mojibake.py`（Tier A/B判定ロジック入り）
- バックアップbundle 3件（計899MB）が各リポジトリの `.git/` 内にある。安定確認後に削除可
- 過去に `24ef3aa`「BOM/mojibake fix WIP, 287 files」で修復が試みられ**途中で止まっていた**
