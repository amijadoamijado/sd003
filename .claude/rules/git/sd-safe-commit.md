# .sd/ Safe Commit Rule（要点）

## 運用

| 操作 | 方法 |
|------|------|
| `.sd/` 作成・編集 | Bash のみ（heredoc / `sed`）。Write/Edit/MultiEdit は hook が物理ブロック（L3） |
| `.sd/` 削除・mv・git clean | hook が物理ブロック |
| commit | `.sd/` 変更後は早めに commit（同一bashが最も安全）。**未commitの変更は wipe 時に L4 で復元されない** |

防御実装: L1=通常tracked化 / L2=settings.local.json untrack / L3=PreToolUse hook /
L4=pre-commit が `.git/sd-snapshot/` へ複製 → post-commit がファイル単位で欠損検知・自動復元（最終防衛線）。
mid-session wipe のみ L4 の射程外（sd-watchdog が警告のみ、意図的設計）。

## 消失時の手動復元（L4 が機能しない場合）

```bash
git ls-tree -r <commit-hash> --name-only | grep "^\.sd/" | while read f; do
  mkdir -p "$(dirname "$f")"
  git show "<commit-hash>:$f" > "$f"
done && git add .sd/ && git commit -m "fix: restore .sd from <commit-hash>"
```

経緯・実測・L1-L4詳細史: `docs/rules-reference/git/sd-safe-commit-full.md`
（関連commit: 7106525 / dcf0498 / 9ae3274 / f5f6648、Refs: claude-code#34330 #10011）

全AIモデル共通（Claude Code / Codex / Antigravity / Grok）。
