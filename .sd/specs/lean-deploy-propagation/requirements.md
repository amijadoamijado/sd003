# Requirements: lean-deploy-propagation

## ゴール（ユーザーが受け取るもの）

配布先12プロジェクトが Claude 5世代 lean構造（常時ロード削減済みsd003）で動く状態。
かつ**既存プロジェクトを壊さない**。プロジェクトごとに適用度をチューニングできる。

## 背景

2026-07-26 lean化（sd003本体: 常時ロード121KB→31KB、17ルールを docs/rules-reference/ へ移設）。
調査で判明した穴:
- deploy は `docs/rules-reference/` を配布しない → 配布先で参照がdangling
- CLAUDE.md.template が旧パス7本を参照
- 検証ゲートC1-C7はリンク実在を見ないため素通り
- deploy はコピーのみで削除しないため、配布先の旧・常時ロード17ファイルが残留し lean効果ゼロ
- 配布先実態は3様: oc001(v2.14/keep無), at001(v2.15/keep無/固有ルール有), at002(rules・hooksディレクトリ丸ごとkeep保護=自動配備不達)

## アウトプット

1. deploy.ps1 / deploy.sh: docs/rules-reference/ 配布 + dry-runスキャン追加 + version 2.18.0
2. CLAUDE.md.template v2（lean構造・dangling参照ゼロ）
3. upgrade.ps1 / upgrade.sh: 旧17ルールの移行（archive-move）+ .sd003-keep 尊重 + .sd003-profile 対応
4. .sd003-profile（プロジェクト別チューニング・プレーンテキスト key=value）
5. verify-deployment.mjs C8（CLAUDE.mdのルール参照パス実在チェック）
6. ミラー同期（sync-cli-commands.py）

## 検証観点

- bash -n / node --check / PS parser が全て通る
- oc001 への deploy dry-run で docs/rules-reference が new として現れ、破壊操作がない
- at002 への upgrade dry-run で .sd003-keep 保護（rules不可侵）が維持される
- 旧17ルールの移行は archive-move（可逆）のみ。削除なし
- C8 が dangling 参照を検出できる（現テンプレの7本が修正済みであること）
- 実際の --execute は本仕様の範囲外（ユーザー承認後に別途実施）
