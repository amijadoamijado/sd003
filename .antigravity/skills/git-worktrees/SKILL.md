---
name: git-worktrees
description: Git Worktreeの安全な作成・管理・クリーンアップ手順
optional: true
source: obra/superpowers (adapted)
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Agent
---

# Git Worktrees - 安全管理スキル

## 概要

Git Worktreeを使い、メインの作業ディレクトリを汚さずに並列作業を行うためのガイド。
SD003のCLAUDE.mdで推奨される「git worktreeでの分離作業」を安全に自動化する。

## いつ使うか

| ケース | 説明 |
|--------|------|
| 並列実装 | メインブランチを保ちながら別機能を実装 |
| `/workflow:impl` | Gemini CLIがworktreeで作業する場合 |
| 実験的変更 | メインを壊さずに大規模変更を試す |
| リファクタリング | `/refactor:batch` の安全な実行環境 |

## Phase 1: ディレクトリ選択

```bash
# デフォルトの配置場所（プロジェクトの隣に作成）
# 例: D:\claudecode\sd003 → D:\claudecode\sd003-worktrees\feature-name

WORKTREE_BASE="../$(basename $(pwd))-worktrees"
mkdir -p "$WORKTREE_BASE"
```

### 命名規則

| パターン | 例 |
|---------|-----|
| 機能名 | `sd003-worktrees/feature-auth` |
| 案件ID | `sd003-worktrees/20260318-001-fix` |
| AI名 | `sd003-worktrees/gemini-impl-001` |

## Phase 2: 安全性検証

worktree作成前に以下を確認:

```bash
# 1. 未コミットの変更がないか
git status --porcelain

# 2. ブランチが存在しないか（衝突防止）
git branch --list "worktree/*"

# 3. .gitignore にworktreeディレクトリが含まれるか
grep -q "worktrees" .gitignore || echo "*-worktrees/" >> .gitignore
```

### SD003固有の確認事項

| 項目 | 確認内容 |
|------|---------|
| hookパス | `.claude/hooks/` のパスがworktreeでも解決されるか |
| 設定ファイル | `.claude/settings.json` がworktreeにコピーされるか |
| npm依存 | `node_modules` がworktreeに存在するか |

## Phase 3: 作成と検証

```bash
# 1. worktree作成
git worktree add "$WORKTREE_BASE/feature-name" -b worktree/feature-name

# 2. 依存関係インストール
cd "$WORKTREE_BASE/feature-name"
npm install

# 3. ベースライン確認（ビルド＋テスト通過を確認）
npm run build && npm test

# 4. 作業開始
```

## Phase 4: 作業完了・統合

```bash
# 1. worktreeで変更をコミット
cd "$WORKTREE_BASE/feature-name"
git add -A && git commit -m "feat: description"

# 2. メインに戻ってマージ
cd /path/to/main-project
git merge worktree/feature-name

# 3. worktreeを削除
git worktree remove "$WORKTREE_BASE/feature-name"
git branch -d worktree/feature-name
```

## Claude Code内蔵ツールとの連携

Claude Codeには `EnterWorktree` / `ExitWorktree` ツールが組み込まれている。
Agent toolの `isolation: "worktree"` パラメータでもworktreeが自動作成される。

| 方法 | 用途 |
|------|------|
| `EnterWorktree` / `ExitWorktree` | 手動でworktreeに入退出 |
| `Agent(isolation: "worktree")` | サブエージェントが自動worktreeで作業 |
| 本スキルの手順 | 上記で対応できない複雑なケース |

## AI協調でのworktree活用

### `/workflow:impl` でGemini CLIがworktreeを使うケース

```
1. Claude Code: worktreeを作成（Phase 1-3）
2. Claude Code: IMPLEMENT_REQUEST に worktreeパスを記載
3. Gemini CLI: worktree内で実装
4. Claude Code: 実装結果をメインにマージ（Phase 4）
```

## 禁止事項

| 禁止 | 理由 |
|------|------|
| メインブランチ上でworktree作成 | メインの作業が中断される |
| worktree内で `git checkout main` | worktreeのHEADが壊れる |
| worktreeの手動削除（`rm -rf`） | git管理情報が不整合になる |
| 未コミット変更があるworktreeの削除 | 作業が失われる |
