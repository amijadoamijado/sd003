# DONE.md - AI中立オーケストレーター実CLI E2E完了

## やったこと

**変更したファイル**

| ファイル | 変更内容 |
|---------|----------|
| `config/orchestrator.providers.json` | Grok非対話実行を検証済みの権限モードへ変更 |
| `src/orchestrator/runner.ts` | Windows実行解決、大容量出力、権限キャンセル検出、dry-run状態を改善 |
| `scripts/orchestrate.js` | PowerShell/npm向けJSON位置引数補正 |
| `scripts/check-orchestrator-providers.js` | PATH順でネイティブ実行ファイルを優先 |
| `package.json` | `orchestrate:dry-run` を追加 |
| `tests/integration/orchestrator-e2e.test.ts` | Windows・大出力・権限キャンセル・dry-runの回帰テスト |
| `docs/orchestrator-contract.md` | Windows npmとGrok非対話実行の安全条件を明文化 |

**変更内容の要約**

Codexを司令塔とする実プロバイダーE2EをWindowsで成立させた。Grokの成果物欠落はファイル消失ではなく権限キャンセルが真因であり、隔離workspace上の非対話権限とランナー側のfail-closed検出で解消した。

## 確認結果

**実行したコマンド**

```powershell
npm run build
npm test -- --runInBand
npm run lint
npm run orchestrate:check
python scripts/sync-cli-commands.py --check
npm run orchestrate -- --scenario config/orchestrator.codex-e2e.json
npm run orchestrate:dry-run -- config/orchestrator.codex-e2e.json
```

**結果**

```
Test Suites: 11 passed, 11 total
Tests: 84 passed, 84 total
Build: 成功
Lint: 成功
CLI同期: 成功
実CLI E2E: 3段階・3成果物すべて成功
```

**動作確認**
- [x] Codex実装段階が成功
- [x] Grok独立レビュー段階が成功
- [x] Codex検証段階が成功
- [x] 期待成果物3件が永続化
- [x] manifestがsucceeded
- [x] ローカルとorigin/masterが同一コミット

## 残っていること

**未完了タスク**
- [ ] 実案件データを使った隔離worktree E2E
- [ ] Grok強権限が隔離workspace限定であることの追加ガード検討
- [ ] stage単位成果物検査の設計検討

**次の手順**
- 次のタスク: 実案件の依頼データを使ったCodex司令塔E2E
- 依存関係: 実案件データと隔離worktree

## 判断したこと

**設計上の選択**

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| Grok `acceptEdits` / `always-approve` / `bypassPermissions` | `bypassPermissions` | 実機で成果物の作成・解析・永続化が成功した唯一のモード |
| 終了コードのみ / stderrキャンセル検出併用 | 併用 | Grokが権限キャンセル時も終了コード0を返すため |
| npm長オプション依存 / JSON位置引数補正 | 位置引数補正 | PowerShellのnpm shimが長オプションを除去するため |
| dry-run共用入口 / 専用npm script | 専用npm script | フラグ除去時に実行へ化ける危険を避けるため |

**採用しなかった案と理由**
- `--always-approve` 単独: Grok 0.2.93で `PermissionCancelled` が継続した。
- 終了コード0を成功扱い: 成果物未作成を見逃す。
- npmの `--dry-run` 長オプション転送: 現環境の `npm.ps1` で除去される。

## 追加情報

- 完了コミット: `dc78c35`, `fc88b02`
- 最新成功run: `20260712T014328959Z-20260712-real-codex-lead-e2e`
- 作業ツリーはクリーン、`master` と `origin/master` は同期済み。

