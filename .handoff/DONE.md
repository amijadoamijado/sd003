# DONE.md - 完了報告（2026-06-25 ブランチ運用ルール制定＋at002 PR運用廃止セッション）

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `sd003/.claude/rules/git/branch-strategy.md` | 新規作成（一人運用ファーストのブランチ/PR運用ルール） |
| `sd003/CLAUDE.md` + `templates/CLAUDE.md.template` | ブランチ/PRルールのIMPORTANT行を追加 |
| `sd003/.handoff/RULES.md` | 禁止項目「作業前にブランチ/PRを勝手に作る」を追加 |
| `at002/.claude/rules/git/pr-based-workflow.md` | 退役（`.sd003-backup-branch-policy-20260625/` へ退避） |
| `at002/CLAUDE.md`, `.handoff/RULES.md`, `security/dev-mode-and-trusted-code.md` | PR運用記述→ブランチ最小ルールへ置換・宙吊り参照修正 |

**変更内容の要約**
SD003 に「基本は一人運用＝master直接作業、ブランチ/PRはユーザー指示時のみ作成」というルールを新設し、AIが勝手にブランチを切る挙動を抑止。at002 が固有採用していたPRベース運用は、ユーザー指示で廃止し一人運用へ統一した。

## 確認結果

**実行したコマンド**
```bash
git push origin master   # sd003 / at002 両方
gh api repos/.../branches/master/protection  # 保護有無の確認
```

**結果**
- sd003: `c702d0b` origin同期（ahead 0）
- at002: `10d83c6` origin同期（ahead 0）
- at002 ブランチ保護: 403（private/Pro限定）＝保護なし。master直push成功。

**動作確認**
- [x] 宙吊り参照ゼロ（grep で確認）
- [x] 両リポジトリ push 完了・origin同期
- [x] 新ルールが `copy_dir_tree` で全PJ伝播対象になることを確認

## 残っていること

**未完了タスク**
- [ ] 他PJ（oc001/at001/cf001/er001 等）へ `/sd-upgrade` でルール伝播（CLAUDE.md保護PJはIMPORTANT行を別途手当て）
- [ ] at002 `.worktrees/nm002-medical-corporation` の整理（稼働確認の上で）

**次の手順**
- PR が必要な場面ではユーザーが都度指示する運用。それ以外は master 直接。

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| ルールのみ vs ルール＋物理ガードレール(hook) | ルールのみ | 一人運用ではhookブロックは過剰。ユーザー判断 |
| at002のPR運用 維持 vs 廃止 | 廃止 | ユーザーの一人運用方針に統一 |
| 二条件(大改修AND要求) vs 一条件(指示時のみ) | 一条件 | ユーザーの実モデルに合わせ簡素化 |

## 追加情報
- 旧 `pr-based-workflow.md` は git履歴と `.sd003-backup-branch-policy-20260625/` に保全（rm禁止遵守）。
- at002 のCodeRabbit/Codex自動レビューはGitHubアプリ側でPR作成時に起動。PRを作らなければ起動しないため追加操作は不要。
