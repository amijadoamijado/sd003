# セッション記録

## セッション情報
- **日時**: 2026-03-29 22:38:01
- **プロジェクト**: D:\claudecode\sd003
- **ブランチ**: master
- **最新コミット**: a623c65 feat: sd-deployに .git/hooks/ 自動インストール追加

## 作業サマリー

### 完了
1. Codex/Geminiからアーカイブ済みコマンド42ファイル削除（コミット: 09db501）
2. Blueprint GateコマンドをCodex/Geminiに追加
3. git hooks（pre-commit/post-commit）の `.kiro/` → `.sd/` 更新
4. sd-deployテンプレート5ファイルの `.kiro` → `.sd` 置換（コミット: 43d4c85）
5. 全22プロジェクトにテンプレート修正を同期
6. deploy.ps1に `.git/hooks/` 自動インストール追加（コミット: a623c65）
7. 全21プロジェクトにgit hooksをインストール

### 進行中
なし

### 未解決
- nm002にGitHub remoteが設定されていない（リポジトリ未作成）

### 作成・変更ファイル

**新規作成**
- `.codex/prompts/blueprint-gate.md`
- `.gemini/commands/blueprint-gate.toml`
- `.claude/skills/sd-deploy/templates/git-hooks/pre-commit`
- `.claude/skills/sd-deploy/templates/git-hooks/post-commit`

**変更**
- `.claude/skills/sd-deploy/deploy.ps1` — Phase 4-21追加
- `.claude/skills/sd-deploy/SKILL.md` — 動的コピー対象#21追加
- `.claude/skills/sd-deploy/templates/` 5ファイル — .kiro→.sd置換
- `.codex/prompts/.sync-manifest.json`
- `.git/hooks/pre-commit`, `.git/hooks/post-commit`

**削除**
- `.codex/prompts/` 28ファイル、`.gemini/commands/` 14ファイル

### 次回タスク

#### P0（緊急）
1. nm002のGitHubリポジトリ作成 + remote追加

#### P1（重要）
1. Blueprint Gateを実プロジェクトで試用
2. 他プロジェクトへのSD003 v3.0.0デプロイ

#### P2（通常）
1. spec-archive/spec-historyコマンドの整理
2. `.claude/rules/specs/spec-driven.md` の更新

### 備考
- deploy.ps1の `.git/hooks/` コピー漏れ（設計漏れ）を修正
- git hooksはgit管理外のため `templates/git-hooks/` にテンプレート配置→インストール方式
- .kiro→.sd の残存参照を全プロジェクトで完全に掃除完了
