# DONE.md - 完了報告（2026-07-26 Claude 5世代lean化・全系統完了）

## やったこと

**変更したファイル（主要）**
| ファイル | 変更内容 |
|---------|----------|
| `CLAUDE.md` ほか常時ロード群 | 文脈ダイエット 121KB→31KB（74.3%減）。17ルールを`docs/rules-reference/`へ移設 |
| `deploy.ps1/sh`・`upgrade.ps1/sh` | v2.18.0: rules-reference配布・lean migration・`.sd003-profile`対応・UTF-8 BOM付与（PS5.1 CP932即死根治） |
| `scripts/verify-deployment.mjs` | C8（ルール参照実在）新設・C2b/C7をkeep-aware化 |
| `templates/CLAUDE.md.template` | lean v2（dangling参照ゼロ・Core Doctrine要約） |
| `AGENTS.md` | Shared Entry Point化＋**agy必須上書き**（実測: agy/Codexの自動注入は本ファイルのみ・agyはbrain/保存強制） |
| `docs/context-injection-map.md` | 新設。4CLIの注入実測表（全GREEN） |
| `.grok/GROK_SPEC.md`・`GROK_NATIVE.md` | Grok Lead実装（ce70d3f）: 死んだgrok-build掃除・省略=CLI既定へ |

**変更内容の要約**
公式lean化（本体80%削減）に整合するsd003全体のlean化を完了。配布機構v2.18.0を設計・実装し、12/12プロジェクトへ適用（at002は決定論/非決定論分離を維持・ハッシュで無傷証明）。SD002遺物は退役、実害バグ3件根治、Codex/Grok/agyの3視点レビューを消化。

---

## 確認結果

**実行したコマンド**
```bash
npm test                                  # 96/96 passed (11 suites)
python scripts/sync-cli-commands.py --check   # SYNC CHECK OK (20 commands)
node scripts/verify-deployment.mjs <各PJ>     # 12/12 PASSED
bash -n / PS Parser / node --check        # 全スクリプト構文OK
```

**動作確認**
- [x] 12/12プロジェクト: 検証C1〜C8（+C2b）PASS・v2.18.0刻印・origin一致（td001のみリモート無し）
- [x] at002: 決定論層（hooks52本・settings・registry45KB）のハッシュ無傷を実測証明
- [x] PS5.1での deploy 成功を実測（BOM修正の証明）
- [x] 注入マップ4CLI: ツール禁止プロトコル＋冒頭行引用突合で実測

---

## 残っていること

**未完了タスク**
- [ ] td001のGitHubリモート作成（任意）
- [ ] bd登録3件: jest flaky（IdRegistry静的汚染）／PS-bash廃止リスト乖離／deploy junction耐性
- [ ] at002提案2件（orchestrator-guard採用・Lead mode契約）＝ユーザー判断待ち

**次の手順**
- 新セッションで `/context` を実測（lean効果の確定値）
- 入口文書（AGENTS.md等）を触る前に `docs/context-injection-map.md` で影響評価すること

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| SD002遺物: 復元 vs 退役 | 退役（git保全のみ） | 中身がcoverage80/design.md等の旧規約で現行ドクトリンと矛盾 |
| push運用: sd003規約 vs Beads | Beads優先（ユーザー裁定） | セッション終了時push必須に統一 |
| at002のlean適用 | 無改変FW8ルールのみ移行 | at002改変5件＋固有ドメイン制約は「意見」として温存（分離思想の維持） |
| C2b/C7のkeep構成FAIL | 検証側をkeep-aware化 | C1/C8と同セマンティクス統一。bespoke配線には触れない |

**採用しなかった案と理由**
- agy Lead正本の新設: agy直接起動の長時間運用予定がないため「作らない」（handoff推奨の現行設計を維持）
- 全ルールの一律削減: フック未整備の事故駆動ルール・ドメイン制約は削減対象外（Guardrails Over Rules）

---

## 追加情報

- fw5yp/sb001はgit上**小文字`agents.md`**（`git add AGENTS.md`が無音空振り。小文字パスで操作）
- 「Everything up-to-date」はpost-commit自動pushとの競合。rev-parse突合で確認する運用
- 全記録Artifact: https://claude.ai/code/artifact/91176ee2-3763-445e-aadc-0b69f0e8eef0
