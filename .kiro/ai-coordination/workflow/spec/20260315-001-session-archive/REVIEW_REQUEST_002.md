# レビュー依頼 REVIEW_REQUEST_002

## 案件情報
- **案件ID**: 20260315-001-session-archive
- **依頼元**: Claude Code
- **依頼先**: Codex
- **種別**: 本日の全作業レビュー
- **日付**: 2026-03-15

## レビュー対象（本日の全作業）

### A. セッション管理系

| # | ファイル | 内容 |
|---|---------|------|
| A1 | `~/.claude/scripts/archive-sessions.sh` | セッションアーカイブ（mv失敗検知・Drive到達性チェック・引数バリデーション追加済み） |
| A2 | `~/.claude/scripts/build-session-index.py` | セッションインデックス生成（ノイズ除去後0件除外・Path.with_suffix修正済み） |
| A3 | `~/.claude/skills/archive-sessions.md` → `~/shared-skills/archive-sessions/SKILL.md` | アーカイブスキル定義 |
| A4 | `.claude/commands/sessionread.md` | バックグラウンドAgentでpreviewのみ自動実行（executeは分離済み） |

### B. git自動push

| # | ファイル | 内容 |
|---|---------|------|
| B1 | `.git/hooks/post-commit` | commit後に自動push（push_output変数でステータス保持修正済み） |

### C. Claude Code + Codex スキル共有

| # | ファイル | 内容 |
|---|---------|------|
| C1 | `~/shared-skills/sync-skills.sh` | shared-skills → .claude/skills + .codex/skills 同期スクリプト |
| C2 | `~/shared-skills/sync-skills.ps1` | Windows Junction版（Codex作成） |
| C3 | `~/shared-skills/codex-dispatch/SKILL.md` | Claude Code→Codex CLIディスパッチスキル |
| C4 | `~/shared-skills/gemini-dispatch/SKILL.md` | Claude Code→Gemini CLIディスパッチスキル |
| C5 | 全6スキルのSKILL.md | YAMLフロントマター追加 |

### D. ワークフロー拡張

| # | ファイル | 内容 |
|---|---------|------|
| D1 | `.claude/commands/workflow-impl.md` | `--codex` フラグでCodex CLI実行を選択可能に |

### E. 展開済みプロジェクト

sessionread.md, workflow-impl.md, post-commit を以下に展開:
- oc001, at001, td001, ta001, cf001, ck001

## レビュー観点

### 1. 設計の一貫性
- セッション管理（A系）とスキル共有（C系）の責務分離は適切か
- `/workflow:impl --codex` の追加はAI協調ワークフロー全体と整合しているか

### 2. セキュリティ
- `codex exec` をClaude Codeから呼ぶ際のリスク（意図しない実行、プロンプトインジェクション）
- post-commit hookの自動pushによる秘密情報漏洩リスク
- Google Driveパスのハードコーディング

### 3. 運用性
- `~/shared-skills/` + Junction方式の保守性
- sync-skills.sh と sync-skills.ps1 の二重管理
- sessionreadでのバックグラウンドarchive（previewのみ）のUX

### 4. エッジケース
- Codex CLIがインストールされていない環境での `/workflow:impl --codex`
- Gemini CLIがインストールされていない環境での `/workflow:impl`
- Google Drive未マウント時のarchive-sessions実行

### 5. 改善提案
- ディスパッチスキル（codex-dispatch, gemini-dispatch）の統合可能性
- AI選択の自動判定（タスク内容に基づく推奨AI）
- スキル共有のCI/CD的な自動検証

## 対象ファイルの場所

```
~/.claude/scripts/archive-sessions.sh
~/.claude/scripts/build-session-index.py
~/shared-skills/*/SKILL.md (6件)
~/shared-skills/sync-skills.sh
~/shared-skills/sync-skills.ps1
D:\claudecode\sd003\.claude\commands\sessionread.md
D:\claudecode\sd003\.claude\commands\workflow-impl.md
D:\claudecode\sd003\.git\hooks\post-commit
```
