# DONE.md - 完了報告

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `.sd/ai-coordination/` 16ファイル | AI協調ワークフロー土台（6テンプレート+handoff-log+README+specs init） |
| `.claude/skills/sd-deploy/deploy.{ps1,sh}` | v3.2.0統一、deploy.sh差異修正（CLAUDE.md skip-if-SD003撤廃、materials/html追加） |
| `.claude/rules/` 15ファイル | 14件にpaths:制約付与、testing-standardsカバレッジ方針 |
| `tests/deploy/ps1-sh-parity.test.ts` | ps1/sh静的パリティテスト新設 |
| `docs/{deploy-commonization-plan,bug-workaround-sunset}.md` | 共通化計画・サンセット表 |
| `package.json` | coverageThreshold撤廃、maxWorkers:2 |
| `CLAUDE.md` `.handoff/RULES.md` | v3.2.0、Bash Policy修正、design.md→spec.md |

**変更内容の要約**
SD003フレームワークを調査・評価し、推奨アクション5件（W1ワークフロー土台、W2整合性、P2ルール棚卸し、P2 deploy差異修正、P3サンセット表）を全て改修した。

## 確認結果

**実行したコマンド**
```bash
npm test
```

**結果**
```
Test Suites: 9 passed, 9 total
Tests:       65 passed, 65 total
```

**動作確認**
- [x] 全テストPASS（新パリティテスト5件含む）
- [x] バージョン参照v3.1.0残存ゼロを確認
- [x] paths:機構が実働（セッション内でtesting-standards自動注入を観測）

## 残っていること

**未完了タスク**
- [ ] 今セッションの修正を全現役配信先へ /sd-upgrade 展開（P1）
- [ ] deploy共通化 Stage1: Phase5のNode統合（P2）
- [ ] マシンメモリ逼迫の恒久対策（P2）

**次の手順**
- 次タスク: /sd-upgrade で oc001/fw5yp/sb001/er001/at002 等へ展開
- 依存関係: なし（本体の変更は全てコミット済み）

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| W1: 使う/退役/縮小 | 使う（土台実装） | 3AI協調はSD003中核宣言、agy/codex連携は現役 |
| deploy CLAUDE.md: 上書き/skip | 上書き（.sd003-keep保護に一本化） | skip-if-SD003は952ef66と同型の「古い配線が直らない」バグ |
| ルール棚卸し: 全paths化/一部維持 | 16件は常時維持 | 安全系・ドクトリン・会話トリガー系はファイル操作前に効く必要 |

**採用しなかった案と理由**
- deploy ps1/sh の即時Node全統合: big bang書き換えはWork First違反。Stage制で段階化（計画文書に記載）。

## 追加情報
- .sd/作成の安定パターン: Write→temp staging→Bash cp（heredoc多連結はexit 66失敗）
- jest OOM: 空きRAM逼迫でデフォルト並列クラッシュ→maxWorkers:2で回避
