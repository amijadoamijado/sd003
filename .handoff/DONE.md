# DONE.md - 完了報告

## やったこと

**変更したファイル（プロジェクト外アーカイブ含む）**

| ファイル / ディレクトリ | 変更内容 |
|---------|----------|
| `D:\kiro-archive-20260420\` | 33 PJ の `.kiro/` 実体を退避（プロジェクト外） |
| `D:\kiro-cmd-archive-20260420\` | 71 件のレガシー kiro コマンド/スキル/フックを退避 |
| 9 PJ × `.sd/`, `.claude/`, `.gemini/`, `.antigravity/`, `.handoff/`, `.sessions/` | `/sd-deploy` で SD003 一式を新規展開 |
| 30 PJ × 119 ファイル | `pipeline-*.md`, `ralph-wiggum-*.md`, `refactor-*.md` 等の `.kiro` → `.sd` 文字列置換 |
| `ta001/.sessions/` | `.kiro/sessions/` の実履歴 3 ファイルを昇格統合 |
| `ta001/.sd/ai-coordination/` | `.kiro/ai-coordination/workflow/research/` を統合 |

**変更内容の要約**

`.kiro/` → `.sd/` 統一の積み残しを全プロジェクト一括で完了。アーカイブはプロジェクト外（`D:\kiro-*-archive-20260420\`）に温存し復元可能。Claude Code ランタイム消失バグ（公式 issue 5 件）は未修正のため運用ルールで継続対処。

---

## 確認結果

**実行したコマンド**
```bash
ls -d /d/claudecode/*/.kiro 2>/dev/null | wc -l
for p in 9PJ; do ls /d/claudecode/$p/.sd; done
grep -rl "\.kiro" /d/claudecode/*/.claude/ | grep -vE "worktrees|migrate-kiro" | wc -l
```

**結果**
- 全 33 PJ から `.kiro/` 実体退避完了
- `.sd/` 不在 9 PJ 全てで `/sd-deploy` 成功（SD003 v2.14.0 / deploy v3.1.0）
- アクティブファイルの `.kiro` 文字列残存 0 件
- worktrees 配下 203 件、migrate-kiro スクリプト 1 件は意図的に保持

---

## 残っていること

**未完了タスク**
- [ ] トップレベル git（`yp001.git` = `/d/claudecode/`）の deletion 差分のコミット判断（ユーザー判断待ち）
- [ ] 各 PJ の `.sd003-backup-*` 自動バックアップ整理方針

**次の手順**
- 次のタスク: ユーザーが `/d/claudecode/` でコミット可否を判断
- 依存関係: なし

---

## 判断したこと

**設計上の選択**

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 削除 vs アーカイブ | アーカイブ | ユーザー指示「フォルダ等は削除せずアーカイブとして残す」 |
| アーカイブ先 | プロジェクト外 | ユーザー指示「プロジェクト外に残す」+ `/d/claudecode/` git 汚染回避 |
| 文字列置換範囲 | active のみ（worktrees + migrate-kiro 除外） | 履歴アーカイブとマイグレツール自体は破壊しない |
| ta001 の `.kiro/sessions/` 扱い | `.sessions/` に昇格 | ユーザーの実セッション履歴（5935+7558 bytes）を温存 |

**採用しなかった案と理由**
- リネーム（`.kiro/` → `.sd/`）: テンプレート未反映分が残るため `/sd-deploy` を選択
- 一括 git rm: ユーザー指示違反 + 復元不可

---

## 追加情報

- `D:\kiro-archive-20260420\README.md`, `D:\kiro-cmd-archive-20260420\README.md` に経緯と復元手順を記録
- bash 落とし穴: `"D:\claudecode\$p"` は bash で `\$` が escape され変数展開されない。PowerShell 引数は forward slash 推奨
- Claude Code 公式 issue #34330 / #15599 / #24956 / #11225 / #10011 全て対応予定なし。`.claude/rules/git/sd-safe-commit.md` の運用ルール継続が必須
