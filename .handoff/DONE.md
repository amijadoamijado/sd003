# DONE.md - 完了報告（2026-07-12 AI中立オーケストレーター整備）

---

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `docs/orchestrator-contract.md` | AI中立オーケストレーターの契約を文書化 |
| `materials/html/ai-neutral-orchestrator-blueprint.html` | 実装方針の HTML ブループリントを追加 |
| `src/orchestrator/types.ts` / `src/orchestrator/runner.ts` | オーケストレーターの型定義と実行ランナーを追加 |
| `src/cli/commands/orchestrate.ts` / `src/cli/index.ts` / `src/index.ts` | CLI から実行できるように配線 |
| `scripts/orchestrate.js` / `scripts/orchestrator-fixture-provider.js` | 実行エントリと fixture provider を追加 |
| `config/orchestrator.codex-e2e.json` / `config/orchestrator.providers.json` | Codex E2E と実プロバイダ接続設定を追加 |
| `scripts/check-orchestrator-providers.js` / `scripts/orchestrator-guard.js` | プロバイダ確認と共通ガードを追加 |
| `.codex/hooks.json` / `.claude/skills/sd-deploy/templates/settings.json.template` | 共有ガードをフックへ配線 |
| `tests/integration/orchestrator-e2e.test.ts` / `tests/integration/orchestrator-guard.test.ts` | E2E とガードの統合テストを追加 |
| `scripts/agent-pipeline.sh` / `scripts/agent-implement.sh` / `scripts/agent-review.sh` / `scripts/agent-test.sh` | `--scenario` 互換を追加 |
| `registry` 関連 | `tt001` を廃止し、`at003` 側の相続提案モジュールへ統合 |

**変更内容の要約**
AI 中立オーケストレーターとして `sd003` を使えるように、契約・ランナー・共有ガード・実プロバイダ設定・Codex E2E を一通り整えた。従来の `--scenario` 呼び出しも残し、移行途中でも壊れない構成にした。直近では `tt001` レジストリを廃止し、`at003` 側へ統合して整理した。

---

## 確認結果

**実行したコマンド**
```powershell
git log -1 --oneline
git log --oneline -4
git status --short
Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
```

**結果**
```
e1952bd registry: tt001を廃止（at003相続提案モジュールへ統合）
```

**動作確認**
- [x] ワークツリーがクリーンであることを確認
- [x] 最新コミットを確認
- [x] セッション記録・履歴・引継ぎ文書を更新

---

## 残っていること

**未完了タスク**
- [ ] 実プロバイダを使った write 系 E2E の実施
- [ ] 旧 project ID / task number を scenario に変換する互換レイヤーの追加
- [ ] push 可否の判断

**次の手順**
- 次のタスク: 上記 P1 項目の着手
- 依存関係: 実プロバイダの認証・実行権限の確認

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| fixture のみで終える vs 実プロバイダに接続する | まず fixture で固める | 実行経路とガードの品質を先に固定し、外部要因を切り離すため |
| 旧 `project ID / task number` を即時破棄する vs `--scenario` 互換を残す | 互換を残す | 既存呼び出しを壊さず移行できるため |

---

## 追加情報

- 実AI write E2E は次段階に分離した。認証情報やプロバイダ状態で結果が変動するため、ここで混ぜない方が安全。
- 共有ガードは Codex / agy / Grok / Claude の運用差を吸収するための共通層として扱っている。
