---
name: cleanup
description: Codex equivalent of the SD003 custom command `/src/**,`. Use when the user invokes `/src/**,`, `cleanup`.
---

# /cleanup

この skill は Claude Code の `/src/**,` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Original Command Body
# /cleanup

プロジェクト内の散らかったファイルをAI判断で安全に整理する。

## 分類カテゴリ

### Category A: 参考資料・成果物 → `/materials/` へ整理
ユーザーの参考資料やAIが生成した成果物。削除ではなく整理。

| サブフォルダ | 対象拡張子 |
|-------------|-----------|
| `csv/` | .csv |
| `excel/` | .xlsx, .xls |
| `pdf/` | .pdf |
| `images/` | .png, .jpg, .jpeg, .gif, .webp, .svg |
| `text/` | .txt, .md (CLAUDE.md, README.md除く) |

### Category B: AI開発用一時ファイル → `.sd/cleanup/archive/` へアーカイブ
テストやデバッグ用の一時ファイル。必要なら復元可能。

| パターン | 例 |
|----------|-----|
| `test_*.*` | test_parser.js |
| `temp_*.*`, `tmp_*.*` | temp_data.json |
| `debug_*.*`, `*_debug.*` | debug_log.txt |
| `*_backup.*`, `*.bak` | config_backup.json |
| `*_old.*`, `*_copy.*` | app_old.ts |
| `nul`, `NUL` | Windows空ファイル |

## 保護対象（絶対に移動しない）

```
# sd003コアファイル
package.json, package-lock.json, tsconfig.json
.gitignore, .eslintrc.*, .prettierrc.*
CLAUDE.md, README.md, AGENTS.md

# sd003コアディレクトリ
/src/**, /tests/**, /docs/**
/.sd/**, /.claude/**, /.github/**
/node_modules/**

# 開発中ファイル（git status検出）
git diff --name-only で検出されるファイル
```

## Usage

```
/cleanup              # 標準実行（AI判断 + 確認）
/cleanup --dry-run    # プレビューのみ（移動なし）
/cleanup --verbose    # 詳細ログ出力
/cleanup --force      # AI判断スキップ（パターンマッチのみ）
```

## Execution Flow

### Step 1: スキャン

```bash
# 開発中ファイルを検出（保護対象）
git diff --name-only HEAD
git diff --cached --name-only
git ls-files --modified
```

Glob/Bashでプロジェクト全体をスキャン：
- Category A対象ファイルを抽出
- Category B対象ファイルを抽出
- 保護対象を除外

### Step 2: AI分析（--forceでスキップ可）

各候補ファイルについて分析：

```
分析観点:
1. ファイルの目的・用途
2. 開発中機能との関連
3. 移動可否の判断
4. 適切なカテゴリ（A or B）
```

出力形式:
```markdown
## AI分析結果

### Category A: 参考資料・成果物 → /materials/
| ファイル | 判断理由 | 移動先 |
|----------|----------|--------|
| data.csv | ユーザー入力データ | materials/csv/ |

### Category B: 一時ファイル → .sd/cleanup/archive/
| ファイル | 判断理由 |
|----------|----------|
| test_parser.js | テスト用一時ファイル |

### 保護対象（移動しない）
| ファイル | 理由 |
|----------|------|
| src/app.ts | git変更中 |
```

### Step 3: ユーザー確認

AskUserQuestionで確認:

```yaml
Question: "整理を実行しますか？"
Header: "実行確認"
Options:
  - label: "はい、実行する"
    description: "上記のファイルを整理します"
  - label: "Category Aのみ実行"
    description: "materialsへの整理のみ実行"
  - label: "Category Bのみ実行"
    description: "一時ファイルのアーカイブのみ実行"
  - label: "キャンセル"
    description: "何もしない"
```

### Step 4: 実行

#### Category A処理
```bash
# materialsディレクトリ作成
mkdir -p materials/csv materials/excel materials/pdf materials/images materials/text

# ファイル移動
mv data.csv materials/csv/
mv report.xlsx materials/excel/
```

#### Category B処理
```bash
# アーカイブディレクトリ作成
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_DIR=".sd/cleanup/archive/cleanup-${TIMESTAMP}"
mkdir -p "${ARCHIVE_DIR}/files"

# ファイル移動（元パス構造維持）
mv test_parser.js "${ARCHIVE_DIR}/files/"
```

#### manifest.json作成（Category Bのみ）
```json
{
  "session_id": "cleanup-20260102-150000",
  "created_at": "2026-01-02T15:00:00Z",
  "files": [
    {
      "original_path": "test_parser.js",
      "archived_path": ".sd/cleanup/archive/.../files/test_parser.js",
      "reason": "AI判断: テスト用一時ファイル",
      "size_bytes": 1234,
      "git_status": "untracked"
    }
  ],
  "summary": {
    "total_files": 5,
    "total_size_bytes": 12345
  }
}
```

### Step 5: 完了報告

```markdown
## Cleanup完了

### Category A: /materials/ へ整理
- csv: 3ファイル
- excel: 1ファイル
- images: 5ファイル

### Category B: .sd/cleanup/archive/ へアーカイブ
- Session: cleanup-20260102-150000
- Files: 8ファイル
- Size: 45.2KB

### 復元方法
/cleanup:restore cleanup-20260102-150000
```

## Safety Mechanisms

### 開発中ファイル保護
gitで変更中のファイルは絶対に移動しない。

### エラー時ロールバック
途中エラー時は実行済み移動を元に戻す。

### タイムアウト
- 処理全体: 5分
- AI判断: 60秒（タイムアウト時は保守的に移動拒否）

## Output Markers

| Marker | Meaning |
|--------|---------|
| `CLEANUP_SCAN_COMPLETE` | スキャン完了 |
| `CLEANUP_ANALYSIS_COMPLETE` | AI分析完了 |
| `CLEANUP_EXECUTED` | 整理実行完了 |
| `CLEANUP_CANCELLED` | キャンセル |
| `CLEANUP_ERROR` | エラー発生 |

## Arguments
$ARGUMENTS
