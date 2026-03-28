# 実装指示書 IMPLEMENT_REQUEST_001

## 案件情報
- **案件ID**: 20260315-001-session-archive
- **依頼元**: Claude Code
- **依頼先**: Codex（レビュー・改善提案）
- **種別**: ツール実装（完了済み）のレビュー + 他プロジェクト展開可能化
- **優先度**: P1
- **日付**: 2026-03-15

## 概要

Claude Codeのセッション履歴管理ツールを実装した。以下3つの機能について、コードレビューと改善提案を依頼する。

### 機能一覧

| # | 機能 | 状態 |
|---|------|------|
| 1 | セッションアーカイブ（Google Drive移動） | ✅ 実装済み・動作確認済み |
| 2 | セッションインデックス生成（目次・キーワード検索） | ✅ 実装済み・動作確認済み |
| 3 | git post-commit hook（自動push） | ✅ 実装済み・動作確認済み |

---

## 機能1: セッションアーカイブ

### 目的
`~/.claude/projects/` 配下の全プロジェクトから、7日以上前のセッションファイル（.jsonl + フォルダ）を `G:/マイドライブ/claude-sessions-archive/` に移動する。

### ファイル

| ファイル | 場所 | 言語 |
|---------|------|------|
| `archive-sessions.sh` | `~/.claude/scripts/archive-sessions.sh` | bash |
| `archive-sessions.md` | `~/.claude/skills/archive-sessions.md` | markdown (スキル定義) |

### archive-sessions.sh の仕様

```
Usage: bash archive-sessions.sh [days] [preview|execute]

引数:
  $1 = days (デフォルト: 7)
  $2 = "preview" (デフォルト) または "execute"

動作:
  1. ~/.claude/projects/ 配下の全プロジェクトをスキャン
  2. *.jsonl ファイルの mtime を確認
  3. N日以上前のファイルを特定
  4. preview: 対象一覧を表示
  5. execute: G:/マイドライブ/claude-sessions-archive/{project}/ に移動
  6. 対応するフォルダ（{uuid}/）があればセットで移動
  7. execute完了後、build-session-index.py を自動実行

保護対象:
  - memory/ フォルダは移動しない
```

### 現在のソースコード

```bash
#!/bin/bash
DAYS="${1:-7}"
MODE="${2:-preview}"
SOURCE="$HOME/.claude/projects"
DEST="G:/マイドライブ/claude-sessions-archive"
CUTOFF=$(date -d "-${DAYS} days" +%s)

total_files=0
total_size=0
moved_files=0

echo "=== Claude Code Session Archive ==="
echo "対象: ${DAYS}日以上前のセッション"
echo "モード: ${MODE}"
echo ""

for project_dir in "$SOURCE"/*/; do
    project_name=$(basename "$project_dir")
    project_has_match=0

    shopt -s nullglob
    for jsonl in "$project_dir"*.jsonl; do
        file_mtime=$(stat -c %Y "$jsonl" 2>/dev/null)
        [ -z "$file_mtime" ] && continue

        if [ "$file_mtime" -lt "$CUTOFF" ]; then
            if [ "$project_has_match" -eq 0 ]; then
                echo "[$project_name]"
                project_has_match=1
            fi

            uuid=$(basename "$jsonl" .jsonl)
            file_size=$(stat -c %s "$jsonl" 2>/dev/null)
            file_date=$(date -d "@$file_mtime" "+%Y-%m-%d")
            size_kb=$((file_size / 1024))

            total_files=$((total_files + 1))
            total_size=$((total_size + file_size))

            folder_mark=""
            if [ -d "${project_dir}${uuid}" ]; then
                folder_mark=" +folder"
            fi

            if [ "$MODE" = "execute" ]; then
                dest_dir="$DEST/$project_name"
                mkdir -p "$dest_dir"
                mv "$jsonl" "$dest_dir/"
                if [ -d "${project_dir}${uuid}" ]; then
                    mv "${project_dir}${uuid}" "$dest_dir/"
                fi
                moved_files=$((moved_files + 1))
                echo "  ✓ ${uuid:0:8}... (${size_kb}KB, $file_date)${folder_mark}"
            else
                echo "  ${uuid:0:8}... (${size_kb}KB, $file_date)${folder_mark}"
            fi
        fi
    done
    shopt -u nullglob
done

total_mb=$((total_size / 1024 / 1024))
echo ""
echo "=== 合計 ==="
echo "対象: ${total_files}件 (${total_mb}MB)"
if [ "$MODE" = "execute" ]; then
    echo "移動完了: ${moved_files}件"
    echo "アーカイブ先: $DEST"
    echo ""
    echo "=== インデックス更新中... ==="
    python "$HOME/.claude/scripts/build-session-index.py"
else
    echo "※ プレビューのみ。実行: bash archive-sessions.sh ${DAYS} execute"
fi
```

---

## 機能2: セッションインデックス生成

### 目的
全セッションから検索可能な目次（Markdown + JSON）を生成する。各セッションの最初の実質的なユーザーメッセージをトピックとして抽出し、キーワード逆引きインデックスも付与する。

### ファイル

| ファイル | 場所 | 言語 |
|---------|------|------|
| `build-session-index.py` | `~/.claude/scripts/build-session-index.py` | Python |

### 出力

| ファイル | 用途 |
|---------|------|
| `~/.claude/session-index.json` | プログラム検索用 |
| `~/.claude/session-index.md` | 人間が読む目次 |

### 仕様

```
Usage: python build-session-index.py [--days N] [--output PATH] [--include-empty]

動作:
  1. ~/.claude/projects/ 配下の全 *.jsonl をスキャン
  2. 各 .jsonl を解析:
     - type=user のメッセージからトピック抽出
     - ノイズ除去（sessionread, Caveat, /clear 等）
     - "Implement the following plan:" プレフィックス除去（プラン名を残す）
     - 3文字以下のメッセージはスキップ
  3. 2KB未満 or ユーザーメッセージ0件のセッションはスキップ
  4. プロジェクト別テーブル + キーワード逆引きインデックスを生成

ノイズパターン:
  - <command-message>, <local-command-caveat>
  - [Request interrupted, sessionread, sessionwrite
  - Caveat:, hello, config, git pull, /clear, /model
  - Implement the following plan: (除去してプラン名を残す)

キーワードインデックス:
  - 4文字以上の英語 + 3文字以上の日本語を抽出
  - ストップワード除外（一般的な英語 + sessionread系ノイズ）
  - 2回以上出現するキーワードのみ表示
```

---

## 機能3: git post-commit hook

### 目的
git commitのたびに自動でGitHubにpushする。

### ファイル

| ファイル | 場所 |
|---------|------|
| `post-commit` | `.git/hooks/post-commit`（各プロジェクト） |

### 仕様

```bash
#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# detached HEAD → スキップ
# remote未設定 → スキップ
# それ以外 → git push origin $BRANCH

# push失敗してもcommit自体は成功（exit 0不要、hookの失敗はcommitに影響しない）
```

### 展開済みプロジェクト
- sd003, oc001, cf001（gitリポジトリがあるもの）

---

## 機能4: sessionread へのバックグラウンドアーカイブ統合

### 目的
`/sessionread` 実行時に、バックグラウンドAgentでセッションアーカイブを自動実行する。メインの作業をブロックしない。

### 変更ファイル
`.claude/commands/sessionread.md`

### 変更内容
- `allowed-tools` に `Agent` を追加
- Step 5 を追加: バックグラウンドAgentがarchive-sessions.shを実行

### 展開済みプロジェクト
- sd003, oc001, at001, td001, ta001, cf001, ck001（全7プロジェクト）

---

## Codexへの依頼事項

### 1. コードレビュー

以下の観点でレビューしてください:

| 観点 | 対象 |
|------|------|
| セキュリティ | ファイルパスのインジェクション、意図しない削除 |
| エッジケース | 空ファイル、権限エラー、Google Drive未マウント時 |
| パフォーマンス | 大量セッション（1000件+）時のインデックス生成速度 |
| 可搬性 | Windows/macOS/Linux互換性（stat -c vs stat -f） |
| エラーハンドリング | mv失敗時のリカバリー、部分移動の防止 |

### 2. 改善提案

- archive-sessions.sh のクロスプラットフォーム対応（macOS stat互換）
- build-session-index.py のノイズパターン改善案
- post-commit hook のエラー通知方法（push失敗時の可視化）
- インデックスの検索性向上（全文検索、タグ分類等）

### 3. テスト案

- archive-sessions.sh のドライラン検証
- build-session-index.py のエッジケーステスト
- post-commit hook のdetached HEAD/リモート未設定テスト

---

## 参照ファイル一覧

| ファイル | 場所 |
|---------|------|
| archive-sessions.sh | `~/.claude/scripts/archive-sessions.sh` |
| build-session-index.py | `~/.claude/scripts/build-session-index.py` |
| archive-sessions.md (スキル) | `~/.claude/skills/archive-sessions.md` |
| sessionread.md (更新済み) | `.claude/commands/sessionread.md` |
| post-commit hook | `.git/hooks/post-commit` |

---

## 実行結果（2026-03-15）

| 指標 | 値 |
|------|-----|
| アーカイブ移動済み | 150件 / 346MB |
| ローカル残り | 58セッション（直近7日） |
| インデックス | 161セッション → 58セッション（更新済み） |
| post-commit展開 | 3プロジェクト（git有りのみ） |
| sessionread展開 | 7プロジェクト |
