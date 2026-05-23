---
name: cleanup-history
description: Codex equivalent of the SD003 custom command `/cleanup:history`. Use when the user invokes `/cleanup:history`, `cleanup-history`.
---

# /cleanup:history

この skill は Claude Code の `/cleanup:history` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Codex Runtime Rules
- `.claude/commands/**/*.md` はClaude Code側のauthoring sourceです。直接変更せず、CodexではこのSkillを実行仕様として扱います。
- Claude Codeのスラッシュコマンド、`Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Codexの通常手順に翻訳します。
- Codex内で `/codex:review`、`/codex:rescue` などのCodexプラグインコマンドを再帰的に呼ばないでください。必要な読取・差分確認・編集・検証・報告をCodex自身で実施します。
- 人間向け出力、レビュー報告、質問、完了報告は日本語で書きます。
- `.sd/ai-coordination/` に依頼書・報告書を書く場合は、既存の案件ID配下に限定し、プロジェクトルートへ散らさないでください。
- Windows環境ではPowerShellで実行できるコマンドを優先し、bash専用の例はWSLやGit Bashが使える場合だけ採用します。

## Codex Native Execution Contract
このセクションはCodex実行時に `Original Command Body` より優先します。

- Claude Codeのスラッシュコマンド、`/workflow:*`、`/codex:*`、`Agent(...)`、`AskUserQuestion` は文字通り実行しない。
- Codex自身がファイル読取、差分確認、編集、検証、報告を直接行う。
- `.claude/commands/**/*.md` はauthoring sourceとして読むだけにし、Codex改善のために直接編集しない。
- 案件IDがない相談・レビューでは `.sd/ai-coordination/` に報告書を作らず、会話内で完結する。
- `.sd/ai-coordination/` に書くのは、案件IDが明示された正式Workflowの場合だけにする。
- WindowsではPowerShellで実行できるコマンドを優先し、bash例はWSL/Git Bashが使える場合だけ採用する。
- `.sd/` が存在しない場合は、その事実を報告し、可能なら軽量レビューまたは直接実装へ縮退する。

## Original Command Body
# /cleanup:history

過去のcleanupセッション履歴を表示する。

## Usage

```
/cleanup:history              # 全履歴を表示
/cleanup:history --limit 5    # 最新5件のみ
/cleanup:history {session-id} # 特定セッションの詳細
```

## Execution Flow

### Step 1: アーカイブディレクトリスキャン

```bash
# アーカイブセッション一覧
ls -lt .sd/cleanup/archive/ | head -20
```

### Step 2: 各セッションのmanifest.json読み込み

各セッションのサマリーを収集:
- セッションID
- 実行日時
- ファイル数
- 合計サイズ

### Step 3: 履歴一覧表示

```markdown
## Cleanup履歴

| Session ID | 日時 | ファイル数 | サイズ |
|------------|------|-----------|--------|
| cleanup-20260102-150000 | 2026-01-02 15:00 | 8 | 45.2KB |
| cleanup-20260101-093000 | 2026-01-01 09:30 | 3 | 12.1KB |
| cleanup-20251231-180000 | 2025-12-31 18:00 | 15 | 128.5KB |

合計: 3セッション, 26ファイル, 185.8KB

### 復元コマンド
/cleanup:restore {session-id}
```

### 詳細表示（セッションID指定時）

```markdown
## Session: cleanup-20260102-150000

- **実行日時**: 2026-01-02 15:00:00
- **ファイル数**: 8
- **合計サイズ**: 45.2KB

### アーカイブファイル一覧

| ファイル | 元パス | サイズ | 理由 |
|----------|--------|--------|------|
| test_parser.js | ./test_parser.js | 1.2KB | テスト用一時ファイル |
| debug_log.txt | ./logs/debug_log.txt | 0.5KB | デバッグログ |

### 復元コマンド
/cleanup:restore cleanup-20260102-150000
```

## Output Format

履歴がない場合:
```markdown
## Cleanup履歴

アーカイブセッションはありません。

/cleanup を実行するとファイルがアーカイブされます。
```

## Arguments
$ARGUMENTS
