---
description: セッション管理（.sessions/ を扱うときのみロード）
paths:
  - ".sessions/**"
---

# Session Management

## Two-Layer Memory Structure

| Layer | File | Purpose |
|-------|------|---------|
| Long-term | `.sessions/TIMELINE.md` | Project history (timeline) |
| Short-term | `.sessions/session-current.md` | Current session details |

`.sessions/` は記憶8層のうち「経緯」の層（いつ・何をした・何が未検証か）。
規範 / `bd remember` / auto-memory / kb001 との境界と保存先の判断フロー:
`docs/rules-reference/session/memory-layers.md`

## Commands

| Command | Description |
|---------|-------------|
| `/sessionread` | 引継ぎ・Git状態の確認＋起動時の点検（読み取りのみ） |
| `/sessionwrite` | Save session (history + current + timeline) |
| `/sessionhistory` | View timeline only |

## /sessionread - セッション読み込み

正本は `.claude/commands/sessionread.md`。`.agents/skills/sessionread/SKILL.md`・
`.grok/skills/sessionread/SKILL.md`・`.sd/commands/specs/sessionread.md` は
`python scripts/sync-cli-commands.py` の生成物なので直接編集しない（`--check` で差分検知）。

| 対象 | 扱い |
|------|------|
| `CLAUDE.md`（グローバル・プロジェクト） | 実行中CLIが自動注入済み。読んだ設定は再読しない |
| `.sessions/session-current.md` | 毎回読む |
| `.handoff/DONE.md` | session-current より新しい場合のみ併読 |
| `.sessions/TIMELINE.md` | 過去の経緯が必要なときだけキーワード検索 |
| `git status --short`・ブランチ・直近コミット | 毎回確認 |

加えて、セッション1回だけ**起動時の点検**（SD003版・会話ログ退避候補）を行う。
点検は読み取りのみでファイルを更新も移動もせず、差が無ければ無音（下記2節）。

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
/sd-deploy <target-project-path>
```

詳細手順: `.claude/skills/sd-deploy/README.md`

## 起動時の点検1: SD003の版（sessionread拡張）

`/sessionread` はセッション1回だけ、導入先が更新元より古くないかを確認する。読み取りのみ。

### 比較の正

| 経路 | 方法 |
|------|------|
| 標準 | `python .codex/check-framework-version.py`（更新元指定は `--source <絶対パス>` か `SD003_SOURCE`） |
| フォールバック | 上記スクリプトが無い旧い導入先では、導入先と更新元の `.claude/skills/sd-deploy/deploy.ps1` の `$FRAMEWORK_VERSION` を直接比較 |

- スクリプトは導入先と更新元の `deploy.ps1` / `deploy.sh` の `$FRAMEWORK_VERSION` を照合し、
  `update_available` / `current` / `ahead` / `unknown` を JSON で返す。参照不能は未確認として扱う。
- **`CLAUDE.md` 末尾の `SD003 v[数値]` 表記は比較に使わない**。deployツール版・テンプレート版とは
  別管理でズレるため（実測: at002 は表記 2.18.0・deploy.ps1 は 2.19.1）。表記は目安であって根拠ではない。
- 版の一致はファイル内容の一致を保証しない。`.sd003-keep` で保護したファイルは更新されないため、
  実際の適用状況は差分と検証で判断する。

### 検知後の扱い

自動でアップグレードしない。導入版・更新元版と「`/sd-upgrade .` で更新できる」ことを1行伝えるだけで、
実行はユーザーの指示があってから。実行時は既存の `/sd-upgrade` 機構（dry-run既定・`.sd003-keep` 保護・
`--execute` 明示時のみ実行）をそのまま使う。詳細: `.claude/skills/sd-upgrade/SKILL.md`。

### ブートストラップ上の制約

この仕組み自体が `sessionread.md` / 本ファイル / `.codex/` の更新として配布されるため、既存の導入先は
次に `/sd-upgrade` を一度実行するまで新しい起動手順を受け取らない（`.codex/` は deploy がツリーごと配布）。
それまでの間は上記フォールバックが効く。

## 起動時の点検2: 会話ログの退避候補

`/sessionread` はセッション1回だけ、`~/.claude/scripts/archive-sessions.sh` があれば
`bash ~/.claude/scripts/archive-sessions.sh 7 preview` で退避候補を数える（Bash ツール＝Git Bash で実行する。PowerShell の `bash` は WSL の空の bash.exe を拾って失敗する）。

- **preview は数えるだけで移動しない**。候補があれば件数・容量と
  `bash ~/.claude/scripts/archive-sessions.sh 7 execute` で退避できることを1行伝える。0件なら無音
- 既定の基準は**7日**（第1引数で変更可）。退避先は `G:/マイドライブ/claude-sessions-archive`、
  execute 時のみ Drive 到達性を確認し、`.jsonl` と同名フォルダを移動してインデックスを再構築する
- 対象は `~/.claude/projects/*/*.jsonl` のみ。`~/.claude/state/` 配下のスキル読取ログ等は対象外

### この2点を簡素化で削らない理由

2026-09-05 の簡素化（78df469）でこの2点を削除し、9月6日に復旧した。どちらも**読み取りのみで
副作用が無く、差が無ければ無音**の観測処理であり、削減対象の「過剰な読み込み・毎回の確認」ではない。
削除中は at002 の版ズレも退避候補315件（123MB）も誰にも見えていなかった。
簡素化する場合は、削除前後の機能を突き合わせて欠落が無いことを確認してから削る。

### ブートストラップ上の制約

この仕組み自体が `sessionread.md`/本ファイルの更新として配布されるため、既存デプロイ先
プロジェクトは次回 `/sd-upgrade` を一度実行してこれらの更新ファイルを受け取るまで、
アップデート自動検知が働かない。初回のみ手動での `/sd-upgrade` が必要。
