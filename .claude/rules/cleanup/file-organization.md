# ファイル整理ルール

## Materials Folder（参考資料・成果物）

ユーザーの参考資料やAIが生成した成果物を整理保存するフォルダ。
開発用一時ファイル（`.sd/cleanup/`）とは明確に分離。

### 構造
```
materials/
├── csv/      # CSVファイル
├── excel/    # Excel（.xlsx, .xls）
├── pdf/      # PDFファイル
├── images/   # 画像（.png, .jpg, .jpeg, .gif, .webp, .svg）
└── text/     # テキスト（.txt, 一般.md）
```

## AIファイル保存ルール（必須）

**禁止**: プロジェクトルート直下へのファイル作成

| ファイル種別 | 保存先 | 例 |
|-------------|--------|-----|
| CSV/Excel成果物 | `materials/csv/`, `materials/excel/` | `materials/csv/report.csv` |
| 画像・PDF | `materials/images/`, `materials/pdf/` | `materials/pdf/spec.pdf` |
| テスト用一時ファイル | `tests/fixtures/` | `tests/fixtures/sample.json` |
| ログ・デバッグ出力 | `logs/` または `.sd/` | `logs/debug.log` |

**違反時**: `/cleanup` コマンドで自動整理される

---

## Cleanup Tool

プロジェクト内の散らかったファイルをAI判断で安全に整理するツール。

### コマンド
| コマンド | 説明 |
|----------|------|
| `/cleanup` | AI判断付きファイル整理 |
| `/cleanup --dry-run` | プレビューのみ（移動なし） |
| `/cleanup:restore` | アーカイブからファイル復元 |
| `/cleanup:history` | 過去のcleanupセッション一覧 |

### 分類カテゴリ

**Category A: 参考資料・成果物** → `/materials/` へ整理
- csv, xlsx, pdf, png, jpg, txt など

**Category B: AI開発用一時ファイル** → `.sd/cleanup/archive/` へアーカイブ
- test_*, temp_*, debug_*, *_backup.* など

### 保護対象（移動しない）
- AI設定ファイル（agents.md, CLAUDE.md, gemini.md）
- sd003コアファイル（package.json, tsconfig.json等）
- コアディレクトリ（/src, /tests, /.sd等）
- git変更中のファイル

### アーカイブ構造
```
.sd/cleanup/archive/
└── cleanup-YYYYMMDD-HHMMSS/
    ├── files/          # 移動ファイル（元パス構造維持）
    └── manifest.json   # 履歴（復元用）
```

---

## ファイル保護ルール（必須）

### 削除禁止
ファイルの `rm` / 直接削除は原則禁止。不要ファイルはアーカイブに移動する。

| 操作 | 禁止 | 代替 |
|------|------|------|
| `rm file` | NG | `mv file .sd/cleanup/archive/` |
| ファイル統合で旧版削除 | NG | 旧版をアーカイブへ移動 |
| リネーム元ファイル削除 | NG | 元ファイルをアーカイブへ移動 |

### 上書き禁止（ユーザー提供ファイル・最終成果物）

ユーザーが提供したファイルや最終成果物を修正する場合、元ファイルを上書きしない。

> **背景**: Excelの修正依頼で元ファイルを上書きし、レイアウトが崩壊した事故から。

**上書き禁止対象**:
- ユーザーが提供・共有したファイル（Excel, CSV, PDF, 画像等）
- `materials/` 配下の成果物
- `.sd/ai-coordination/` 配下の依頼書・報告書
- `.sd/sessions/` 配下のセッション記録

**例外（上書きOK）**:
- ソースコード（`src/`, `tests/`）
- 設定・ルール（`package.json`, `.claude/`, `.handoff/`等）
- ビルド出力（`dist/`）

**手動修正の手順**:
1. 元ファイルはそのまま保持（またはアーカイブに移動）
2. 修正版は別名で新規作成（例: `_v2`, `_modified`）

**スクリプト再生成の手順**:
1. 既存ファイルをアーカイブにバックアップ（`cp file .sd/cleanup/archive/`）
2. スクリプトを実行して上書き

**例外**: ユーザーが明示的に「上書きしてよい」「削除してよい」と指示した場合のみ許可。
