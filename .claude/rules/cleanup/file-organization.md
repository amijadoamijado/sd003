# ファイル整理ルール

## Materials Folder（参考資料・成果物）

ユーザーの参考資料やAIが生成した成果物を整理保存するフォルダ。
開発用一時ファイル（`.kiro/cleanup/`）とは明確に分離。

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
| ログ・デバッグ出力 | `logs/` または `.kiro/` | `logs/debug.log` |

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

**Category B: AI開発用一時ファイル** → `.kiro/cleanup/archive/` へアーカイブ
- test_*, temp_*, debug_*, *_backup.* など

### 保護対象（移動しない）
- AI設定ファイル（agents.md, CLAUDE.md, gemini.md）
- sd003コアファイル（package.json, tsconfig.json等）
- コアディレクトリ（/src, /tests, /.kiro等）
- git変更中のファイル

### アーカイブ構造
```
.kiro/cleanup/archive/
└── cleanup-YYYYMMDD-HHMMSS/
    ├── files/          # 移動ファイル（元パス構造維持）
    └── manifest.json   # 履歴（復元用）
```
