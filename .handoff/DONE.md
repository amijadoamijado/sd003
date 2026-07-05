# DONE.md - 完了報告

## やったこと

**変更したファイル（主要）**
| ファイル | 変更内容 |
|---------|----------|
| `tests/integration/spec-workflow.test.ts` | `.sd/`消失の真因（cwd/.sdをrmSync）をtempディレクトリ隔離で修正 |
| `package.json` / `tsconfig.json` / `bin/sd003.js` | dist実行不能のESM/CJS不整合をCommonJS統一で修復 |
| `src/cli/commands/*.ts` / `src/spec-driven/spec-file-utils.ts` | CRLF/BOM対応・spec:create上書き防止・再帰spec探索・qa:deploy:safeのモック排除 |
| `.claude/hooks/*.sh` (13本) | sedのJSON抽出バイパスをpython化・block-sd-destructive再武装・watchdog修正等 |
| `.claude/hooks/sd003-stop-hook*.{sh,ps1}` ほか | 常時no-opだったStopフックをtranscript_path経由に修正 |
| `.git/hooks/{pre,post}-commit` + テンプレート | L4スナップショットのアトミック化・鮮度照合・日本語名対応 |
| `.claude/skills/sd-deploy/*` / `sd-upgrade/*` / `scripts/*` | .sd003-keep保護・git hooks上書き・独自スキル削除ガード・prune・即死バグ修正 |
| `.gitattributes`（新規） | autocrlf=true対策でシェル系をLF固定 |

**変更内容の要約**
sd003本体を全面コードレビューし、約35件の欠陥を5体のSonnetエージェントで実装・検証・修正した。最大の成果は「`.sd/`がcommit時に消える」長年の症状の真因特定（自テストのrmSync + test-gateフック）で、#34330 runtime bug説は誤診の可能性が高い。

---

## 確認結果

**実行したコマンド**
```bash
npm run build
npm test
node bin/sd003.js --help
bash hooktest.sh   # ライブフックのバイパス/許可テスト
```

**結果**
```
Build successful (tsc clean)
Tests: 65 passed, 65 total (9 suites)
CLI: sd003 usage 正常表示
Hook checks: 12/12 PASSED (bypass拒否・正規許可)
.sd/: npm test後も実コミット6回後も 59ファイル維持
シェル系35ファイル: 全てLF/BOMなし
```

**動作確認**
- [x] dist/CLIがnode実行でクラッシュしない（ERR_MODULE_NOT_FOUND解消）
- [x] 破壊コマンド（rm .sd/git checkout ./clasp undeploy等）がフックで拒否される
- [x] npm test / commit で実`.sd/`が消えない
- [x] 6コミットをremoteへpush（git ls-remoteで確認）

---

## 残っていること

**未完了タスク**
- [ ] 配信先プロジェクト（oc001/at001/at002/cf001等）へ`/sd-upgrade`で今回の修正を反映（同じ欠陥が存在）
- [ ] `.sd/`真因除去に伴うL1-L4/Bash Tool Policy/sd-safe-commit儀式/関連ルールの見直し要否をユーザー判断→承認後に撤去/緩和
- [ ] ESLint設定作成でqa:deploy:safeのLintゲート有効化
- [ ] enforce-spec-locationの裸パス早期allow漏れ修正

**次の手順**
- 次のタスク: 上記P1（配信先反映・制約見直し判断）
- 依存関係: なし（sd003本体は全push済み）

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 実装モデル | Sonnet×5 | トークン効率（Opusはオーケストレーション/最終検証に専念） |
| src/のESM対応 | CommonJS統一 | require.mainガード維持+拡張子問題回避で最小リスク |
| L1-L4防御 | 残置（撤去せず） | 真因除去後も多重防御として保持。撤去は破壊的変更でユーザー判断 |
| フックのJSON解析 | python | jq非依存（Git Bash for WindowsにjqなしのためBash Policy整合） |

**採用しなかった案と理由**
- L1-L4/Bash Policyの即時撤去: 影響大の破壊的変更のため事実記録のみに留めた
- qa:deploy:safeのモック維持: 柱3（Real Data First）違反のため実チェック化

---

## 追加情報
- 作業中インシデント3件（settings.json誤上書き→復元、agy誤起動→kill、CRLF混入→自己修復）。全て解消済み。
- settings.json/.git/hooksはgitignore対象のため変更はディスクのみ（コミット外）。
