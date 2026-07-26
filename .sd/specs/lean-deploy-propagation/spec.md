# Spec: lean-deploy-propagation

## 設計判断

### D1: rules ツリーコピーは無変更
deploy.ps1:345 / deploy.sh:281 の `.claude/rules` ツリーコピーはソース追従型のため、
lean化済みソース（圧縮3＋条件ロード群）がそのまま配布される。変更不要。

### D2: docs/rules-reference/ を配布対象に追加
- deploy.ps1: 4-11 の直後に `Copy-DirTree -RelPath "docs\rules-reference" -Filter "*.md"`
- deploy.ps1 dry-run `$scanDirs` に `docs\rules-reference` 追加（コピーとスキャンの対を保つ）
- deploy.sh: `copy_dir_tree "docs/rules-reference" ...` + `scan_dirs` に追加

### D3: CLAUDE.md.template v2
lean構造に全面改訂。移設済み7参照を docs/rules-reference/ パスへ更新、
Core Doctrine 4本柱の要約節を追加（配布先は旧全文ルールを失うため要約を持たせる）、
troubleshooting の Details も docs/rules-reference/ へ。フッター刻印 v2.18.0。

### D4: upgrade に lean migration を追加（archive-move・可逆）
`$leanLegacyRules`（移設済み17ファイルの旧パス）をハードコード。
Phase 2 で検出、実行時は既存 `Move-ToBackup` で `.sd003-upgrade-backup-*/` へ移動。
**削除はしない**。dry-run では移行予定と「ローカル改変あり（reference版とhash差）」を表示。

### D5: .sd003-keep を upgrade でも尊重（新規）
upgrade は従来 keep を読まなかった。lean migration に限り keep 判定を適用
（at002 の `.claude/rules` ディレクトリ保護で17ファイル全skip）。
既存の overeng/deprecated 削除の挙動は変えない（過去実績を壊さない）。

### D6: .sd003-profile（プロジェクト別チューニング）
プレーンテキスト・key=value・`#`コメント（.sd003-keep と同型式）:
```
lean-migration = standard   # standard(既定) | additive | off
keep-always-loaded = global/known-unknowns.md   # 繰り返し可・移行対象から除外
```
- standard: 17ファイルを archive-move（keep / keep-always-loaded 該当は除外）
- additive: 移動しない。残留を報告のみ（新規配布物は受け取る）
- off: lean migration 自体をスキップ
- ファイル無し = standard（可逆な移動のみのため既定で安全）
PS/bash 両方で同一パース。JSON不採用（bashパースの複雑化回避）。

### D7: バージョン
FRAMEWORK_VERSION 2.17.0 → 2.18.0、SD003_VERSION 3.4.0 → 3.5.0（CLAUDE.mdフッターと同期）。
deploy.ps1/deploy.sh 両方。

### D8: verify-deployment.mjs C8
配布先 CLAUDE.md から `(\.claude\/rules|docs\/rules-reference)\/[\w\/-]+\.md` を抽出し
実在チェック。CLAUDE.md が .sd003-keep 保護時は SKIP（C1と同セマンティクス）。
dangling 参照クラス（今回の事故）の再発を物理検出。

### D9: 範囲外（別issue）
- PS/bash の既存 overeng リスト乖離（workflow-*系6コマンド等） → bd issue化
- at002 への実適用（keep保護のため手動適用・版数刻印の手動更新が必要） → 別オペ
- 実プロジェクトへの --execute → ユーザー承認後

## 配布先ロールアウト方針

| プロジェクト | 方式 |
|-------------|------|
| oc001, at001 等（keep無し） | upgrade dry-run → 結果提示 → 承認後 --execute |
| at001 固有ルール（accounting/*, clients/*, quiz-gate） | 17リスト外のため不可侵（quiz-gateのみ17リスト内 → at001は .sd003-profile の keep-always-loaded 登録を推奨） |
| at002（rules/hooks/CLAUDE.md keep保護） | 自動配備不達。lean-migration=off 相当。手動適用を別途計画 |
