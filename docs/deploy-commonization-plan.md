# deploy.ps1 / deploy.sh 共通化計画

作成: 2026-06-10 | 状態: Stage 0 完了

## 背景

deploy.ps1（786行）と deploy.sh（約950行）の二重実装は、片方だけ修正して
もう片方に同じバグが残る構造的リスクを持つ。実害が既に2回発生している:

| 日付 | 差異バグ | 修正 |
|------|---------|------|
| 2026-06-07 | deploy.sh のみ settings.json を skip-if-exists（古い配線が直らない） | 952ef66 |
| 2026-06-10 | deploy.sh のみ CLAUDE.md を skip-if-SD003 + materials/html 欠落 | 本計画 Stage 0 |

## Stage 0（完了・2026-06-10）: 差異の解消 + パリティガードレール

- deploy.sh の CLAUDE.md skip-if-SD003 分岐を撤廃（.sd003-keep 保護に一本化、ps1 と統一）
- deploy.sh の materials/html 欠落を修正
- **静的パリティテスト新設**: `tests/deploy/ps1-sh-parity.test.ts`
  - SD003_VERSION / FRAMEWORK_VERSION の一致
  - materials/* ディレクトリリストの一致
  - Phase 6b（verify-deployment.mjs）配線の両立
  - skip-if-SD003 類の再混入禁止（952ef66 バグクラス）

## 既知の残存差異（未対応・優先順）

| # | 差異 | ps1 | sh | リスク |
|---|------|-----|-----|--------|
| 1 | settings.json 生成方式 | テンプレート参照 | ハードコードheredoc | 🔴 内容が乖離し得る（Phase 6b C1 が実行時に検出する分だけ緩和済み） |
| 2 | session-current.md / TIMELINE.md 生成 | テンプレートから置換 | ハードコードheredoc | 🟡 |
| 3 | .sessions/templates/ コピー | ディレクトリ全体 | session-template.md 単体 | 🟡 テンプレ追加時に sh 側が漏れる |
| 4 | package.json 不在時 | 新規作成して gas-fakes 注入 | スキップ | 🟡 新規PJで gas-fakes 欠落（sh） |

## Stage 1（次の一手）: Phase 5（Generate）の Node 統合

`scripts/generate-framework-files.mjs` を新設し、ps1/sh 双方から
`node scripts/generate-framework-files.mjs <target> <source>` で呼ぶ。

- 対象: CLAUDE.md / settings.json / session-current.md / TIMELINE.md / registry.json / handoff-log.json
- .sd003-keep 判定も mjs 側に移す（is_kept / Test-Kept の二重実装も解消）
- 残存差異 #1〜#4 はこの統合で同時に消える
- 検証: temp ターゲットへの実デプロイ3シナリオ（新規 / 既存SD003 / .sd003-keep あり）+ Phase 6b PASS

## Stage 2: Phase 4（Copy）の Node 統合

`scripts/copy-framework-files.mjs`。動的コピー（ファイル追加時スクリプト修正不要）の
特性を維持したまま、コピーリストを1箇所にする。

## Stage 3: オーケストレータ統合

ps1/sh は「Node を呼ぶだけの薄いランチャー」（数十行）に縮退させる。
Phase 1-3, 7（検証・バックアップ・mkdir・レポート）も mjs に吸収。

## 原則

- 各 Stage は独立してデプロイ可能。一括書き換え（big bang）はしない
- 各 Stage 完了時に temp 実デプロイ + Phase 6b + パリティテストで検証（Work First）
- Node >= 18 は既に前提（verify-deployment.mjs が deploy 時に必須のため、新たな依存追加ではない）
