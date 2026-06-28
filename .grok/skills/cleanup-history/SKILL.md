---
name: cleanup-history
description: "Show cleanup session history (Use when the user runs /cleanup-history.)"
---

# /cleanup:history

SD003 custom command `/cleanup:history` を Grok skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Grok Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Grok の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*`、`/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はGrok自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

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
