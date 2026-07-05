# Session Management

## Two-Layer Memory Structure

| Layer | File | Purpose |
|-------|------|---------|
| Long-term | `.sessions/TIMELINE.md` | Project history (timeline) |
| Short-term | `.sessions/session-current.md` | Current session details |

## Commands

| Command | Description |
|---------|-------------|
| `/sessionread` | **Full session load** (4 files) |
| `/sessionwrite` | Save session (history + current + timeline) |
| `/sessionhistory` | View timeline only |

## /sessionread - Complete Session Load

**Reads 4 files in order:**

| Order | File | Purpose |
|-------|------|---------|
| 1 | `D:\claudecode\CLAUDE.md` | Global settings (UTF-8 constraints) |
| 2 | `./CLAUDE.md` | Project settings |
| 3 | `.sessions/session-current.md` | Current session (short-term) |
| 4 | `.sessions/TIMELINE.md` | Project history (long-term) |

**Use at session start to load all context automatically.**

## File Locations

- **History**: `.sessions/session-YYYYMMDD-HHMMSS.md`
- **Latest**: `.sessions/session-current.md`
- **Timeline**: `.sessions/TIMELINE.md`

## Saved Information

- Date, project, branch, latest commit
- Completed items, in-progress items, unresolved issues
- Created/modified files list
- Next session tasks (P0/P1/P2 priority)
- Notes and handoff items

## Session Lifecycle

1. **Start**: Run `/sessionread` (loads all 4 files)
2. **Working**: Checkpoint as needed
3. **End**: `/sessionwrite` for handoff

## Crash Recovery Procedure

When Claude Code crashes unexpectedly:

```bash
# Step 1: Resume conversation context
claude --continue

# Step 2: Load all session context
/sessionread
```

**Important**:
- `--continue` restores conversation context (unsaved work may be visible)
- `/sessionread` loads global + project settings + last saved session + history
- Work done after last `/sessionwrite` requires manual review from `--continue` context

### Recovery Flow

```
Crash occurs
    ↓
claude --continue   ← Restores conversation (may include unsaved work)
    ↓
/sessionread        ← Loads all 4 files (global, project, session, timeline)
    ↓
Compare and determine what was lost
    ↓
Continue work
```

## 記録フォーマット

```markdown
# セッション記録

## セッション情報
- **Date**: [YYYY-MM-DD HH:MM:SS]
- **Project**: [path]
- **Branch**: [branch name]
- **Latest Commit**: [hash]

## 作業サマリー

### 完了
### 進行中
### 未解決
### 作成・変更ファイル

### 次回タスク
- P0（緊急）
- P1（重要）
- P2（通常）

### 備考
```

## Deployment to New Projects（⚠️ 省略禁止）

SD003を新規プロジェクトに展開する際、セッション管理は**必須コンポーネント**。

### 必須ファイルチェックリスト

| # | ファイル | 種別 | 確認 |
|---|---------|------|------|
| 1 | `.claude/commands/sessionread.md` | コピー | ☐ |
| 2 | `.claude/commands/sessionwrite.md` | コピー | ☐ |
| 3 | `.claude/commands/sessionhistory.md` | コピー | ☐ |
| 4 | `.claude/rules/session/session-management.md` | コピー | ☐ |
| 5 | `.sessions/session-template.md` | コピー | ☐ |
| 6 | `.sessions/session-current.md` | **新規作成** | ☐ |
| 7 | `.sessions/TIMELINE.md` | **新規作成** | ☐ |

### 注意事項

- **session-current.md と TIMELINE.md はコピーではなく新規作成する**（プロジェクト固有の初期内容）
- 展開後すぐに `/sessionread` で動作確認
- 失敗した場合: 上記7ファイルの存在を確認

### 展開コマンド

```bash
/sd:deploy <target-project-path>
```

詳細手順: `.claude/skills/sd-deploy/README.md`

## SD003 Update Check（sessionread拡張）

デプロイ先プロジェクト（SD003本体 `D:\claudecode\sd003` 以外）で `/sessionread` を実行すると、
Step 2（プロジェクトCLAUDE.md読み込み）の直後に、SD003本体に対して自分が古くないかを
非ブロッキングで自動チェックする（`.claude/commands/sessionread.md` Step 6）。

### バージョン比較の正

- 比較対象は `D:\claudecode\sd003\.claude\skills\sd-deploy\deploy.ps1` の `$FRAMEWORK_VERSION`
  （実際にデプロイ先CLAUDE.mdへ書き込まれる値）。
- **既知の注意**: SD003本体の `CLAUDE.md` 末尾表記（例: `SD003 v3.4.0`）と、deployスクリプトの
  `$SD003_VERSION`（deployツール自体のバージョン、2026-07-06に3.4.0へ再同期済み）・`$FRAMEWORK_VERSION`
  （配布されるテンプレートバージョン、現在2.15.0）は別々に管理されている。本チェックは必ず
  `$FRAMEWORK_VERSION` を「現行版」として扱う。3値の完全統一（reconcile）は別問題として扱う。
- デプロイ先プロジェクトのCLAUDE.md本文に残る `SD003 v[数値]` の文字列のみが唯一のローカル
  バージョン痕跡（専用のバージョンファイル・manifestは存在しない）。

### 検知後の扱い（確認ゲート必須）

「アップデートあり」と判定された場合でも、**自動でアップグレードを実行しない**。
非ブロッキングな通知（表示フォーマットへの追記）のみ行い、実行するかどうかは
`AskUserQuestion` による1回の確認ゲートを経てから判断する（柱4 Segmented Sequencing、
および破壊的操作は確認を挟むという全体方針に整合）。

実行する場合は既存の `/sd-upgrade` 機構（dry-run既定・`.sd003-keep`による固有化ファイル保護・
`--execute`明示時のみ実行）をそのまま再利用する。詳細: `.claude/skills/sd-upgrade/SKILL.md`。

### ブートストラップ上の制約

この仕組み自体が `sessionread.md`/本ファイルの更新として配布されるため、既存デプロイ先
プロジェクトは次回 `/sd-upgrade` を一度実行してこれらの更新ファイルを受け取るまで、
アップデート自動検知が働かない。初回のみ手動での `/sd-upgrade` が必要。
