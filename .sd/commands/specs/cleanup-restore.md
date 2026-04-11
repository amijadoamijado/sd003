---
slug: cleanup-restore
source: .claude/commands/cleanup-restore.md
description: Restore files from cleanup archive
claude_command: /cleanup:restore
codex_skill: cleanup-restore
gemini_file: cleanup-restore.toml
allowed_tools: Read, Write, Bash, Glob, AskUserQuestion
---

# /cleanup:restore

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Gemini CLI の TOML と Codex の skill はこのファイルから生成します。

## Original Body
# /cleanup:restore

アーカイブされたファイルを元の場所に復元する。

## Usage

```
/cleanup:restore                    # セッション選択UI
/cleanup:restore {session-id}       # 特定セッションを復元
/cleanup:restore --all              # 全ファイル復元
/cleanup:restore --select           # ファイル個別選択
```

## Execution Flow

### Step 1: セッション一覧取得

```bash
# アーカイブセッション一覧
ls -la .sd/cleanup/archive/
```

セッションが指定されていない場合、AskUserQuestionで選択:

```yaml
Question: "復元するセッションを選択してください"
Header: "セッション"
Options:
  - label: "cleanup-20260102-150000 (8ファイル, 45.2KB)"
    description: "2026-01-02 15:00に実行"
  - label: "cleanup-20260101-093000 (3ファイル, 12.1KB)"
    description: "2026-01-01 09:30に実行"
```

### Step 2: manifest.json読み込み

```bash
cat .sd/cleanup/archive/{session-id}/manifest.json
```

復元対象ファイル一覧を表示:

```markdown
## 復元対象ファイル

| 元パス | サイズ | アーカイブ理由 |
|--------|--------|----------------|
| test_parser.js | 1.2KB | テスト用一時ファイル |
| debug_log.txt | 0.5KB | デバッグログ |
```

### Step 3: 復元確認

AskUserQuestionで確認:

```yaml
Question: "復元を実行しますか？"
Header: "復元確認"
Options:
  - label: "全ファイルを復元"
    description: "8ファイルを元の場所に復元"
  - label: "ファイルを選択して復元"
    description: "復元するファイルを個別選択"
  - label: "キャンセル"
    description: "何もしない"
```

### Step 4: 復元実行

```bash
# 各ファイルを元の場所に復元
mv .sd/cleanup/archive/{session-id}/files/test_parser.js ./test_parser.js
```

### Step 5: アーカイブフォルダ削除提案

AskUserQuestionで確認:

```yaml
Question: "復元完了。アーカイブフォルダを削除しますか？"
Header: "削除確認"
Options:
  - label: "削除する"
    description: ".sd/cleanup/archive/{session-id}/ を削除"
  - label: "残す"
    description: "アーカイブフォルダを保持"
```

### Step 6: 完了報告

```markdown
## 復元完了

- Session: cleanup-20260102-150000
- Restored: 8ファイル
- Archive: 削除済み / 保持
```

## Error Handling

| Error | Action |
|-------|--------|
| Session not found | 利用可能なセッション一覧を表示 |
| File conflict | 上書き確認を求める |
| Permission error | エラー詳細を表示 |

## Output Markers

| Marker | Meaning |
|--------|---------|
| `RESTORE_COMPLETE` | 復元完了 |
| `RESTORE_CANCELLED` | キャンセル |
| `RESTORE_ERROR` | エラー発生 |

## Arguments
$ARGUMENTS
