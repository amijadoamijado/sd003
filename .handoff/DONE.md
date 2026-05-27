# DONE.md - 2026-05-27 20:18 セッション完了報告

## やったこと

**変更したファイル**

| ファイル | 変更内容 |
|---------|----------|
| `package.json` | jest `testPathIgnorePatterns` 追加（`tests/gas-fakes/` 除外） |
| `.gitignore` | `.sd/` 削除、`.claude/settings.local.json` 追加 |
| `.claude/settings.json` | PreToolUse hook (Write/Edit/MultiEdit) に `block-edit-write-on-sd.sh` 登録 |
| `.claude/hooks/block-edit-write-on-sd.sh` | 新規。`.sd/` への Write/Edit/MultiEdit を物理ブロック |
| `.claude/settings.local.json` | untrack（ディスク保持） |
| `tests/integration/env-integration.test.ts` | アーカイブ（gas-fakes 移行に伴う廃止テスト） |
| `tests/unit/env/LocalEnv.test.ts` | アーカイブ |
| `tests/e2e/gas-mock-e2e.test.ts` | アーカイブ |
| `.sd/cleanup/archive/cleanup-20260527-141500/` | 廃止物の退避先（新規） |

**変更内容の要約**

(1) pre-commit hook ブロック原因だった廃止テスト3件を整理し `npm test` を 7/7 PASS に修復。(2) 「`.sd/` 消失バグ」の真因を3層構造で特定し、L1=gitignore除外、L2=settings.local.json untrack、L3=Edit/Write 物理ブロック の対策を実装し検証完了。

---

## 確認結果

**実行したコマンド**

```bash
npm test                                  # → 7/7 suites, 58/58 tests pass
find .sd -type f | wc -l (×5 連続)         # → 41 安定維持
echo >> .sd/...  + 別bashでcommit          # → wipe なし、commit 6b3884f 成功
Edit on .sd/commands/manifest.json        # → ガードレール発火、deny
```

**結果**

```
Test Suites: 7 passed, 7 total
Tests:       58 passed, 58 total
.sd/ file count: 41 (stable across 5 consecutive Bash invocations)
Block hook: fires on Write|Edit|MultiEdit when path contains .sd/
```

**動作確認**

- [x] `npm test` が PASS する
- [x] pre-commit hook が commit をブロックしない
- [x] `.sd/` が Bash 連続実行で消えない
- [x] Bash-only edit + 別 Bash commit が wipe なしで完走
- [x] Edit/Write on `.sd/` が PreToolUse hook で deny される

---

## 残っていること

**未完了タスク**

- [ ] at002 への Layer 3 hook 配備（ユーザー選択待ち: A/B/C/D 提示済み）
- [ ] `.claude/rules/git/sd-safe-commit.md` の改訂（旧運用ルール「同一bash add+commit」を新運用に置換）
- [ ] 他11プロジェクトの Layer 1+2+3 状態確認（oc001/at001/fw5yp/sb001/er001/as001/ad001/cf001/ck001/td001/PC001）
- [ ] `/sd-upgrade` スキルへの Layer 3 統合（配備自動化）
- [ ] `.sd/cleanup/archive/cleanup-20260527-141500/manifest.json` 再生成（機能影響なし）

**次の手順**

- 次のタスク: at002 への Layer 3 配備（ユーザー判断後）
- 依存関係: なし

---

## 判断したこと

**設計上の選択**

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 「同一bash add+commit 儀式」維持 vs 構造解決 | **構造解決** | ユーザー要求「ultrathink + 根本的な解決」 |
| `.sd/` 完全 untrack vs 通常 tracked | **通常 tracked** | gitignored-but-tracked の矛盾が wipe trigger |
| settings.local.json 維持 vs untrack | **untrack** | 慢性 M 状態が refresh 発火確率を上げていた |
| Layer 3 を「ルール追加」 vs 「物理ガードレール」 | **物理ガードレール** | guardrails-over-rules 原則 |
| 廃止テスト削除 vs アーカイブ | **アーカイブ** | file-organization.md「rm禁止」 |

---

## 追加情報

- at002 を診断したところ Layer 1+2 が既に入っていた（恐らく 2026-05-23 `/sd-upgrade` 経由）。Layer 3 のみ未配備。
- 本セッションで7コミット発生（試行錯誤の証跡を含む）。
- post-commit hook の auto-restore は完全消失時のみ発火（partial wipe 非対応）だが、L1+L2+L3 後は wipe 自体が発生しないため fallback として温存。
- セッション中4回ユーザー方針修正（応急処置→根本解決へのエスカレーション）。learning-nudge で auto-memory feedback 追加推奨。

---
