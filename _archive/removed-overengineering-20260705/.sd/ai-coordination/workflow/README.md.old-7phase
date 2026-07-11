# AI協調ワークフロー

Claude Code（司令塔）/ Codex（レビュー）/ Antigravity（実装・E2E）の3AI協調の運用ディレクトリ。
正本ルール: `.claude/rules/workflow/ai-coordination.md`

## 構造

| パス | 用途 |
|------|------|
| `templates/` | 依頼・報告の必須テンプレート（6種） |
| `spec/{案件ID}/` | 発注書・実装指示・テスト依頼 |
| `review/{案件ID}/` | レビュー結果・テスト報告 |
| `log/{案件ID}/` | 工程ログ（PROJECT_STATUS.md） |
| `../handoff/handoff-log.json` | AI間引き継ぎログ（記録必須） |
| `../sessions/{ai}/` | AI別セッション記録 |

## 運用フロー（7段階+テスト）

```
Phase 1 発注書(CC) → 2 発注書レビュー(Codex) → 3 実装指示(CC)
→ 4 実装(Agy) → 4.5 視覚評価(Web UIのみ) → 5 実装レビュー(Codex)
→ 6 修正(Agy) → 7 E2E(Agy) → 8 完了(CC)
```

`/workflow:request` 以降は自動連鎖（impl → review → test）。省略禁止。

## 注意（.sd/ 操作）

このディレクトリ配下のファイル作成・編集は **Bash tool のみ**（Write/Edit はhookで物理ブロック）。
作成したら早めに commit する。詳細: `.claude/rules/git/sd-safe-commit.md`
