# ファイル整理ルール（要点）

## 保存先（プロジェクトルート直下への新規作成は禁止）

| 種別 | 保存先 |
|------|--------|
| 成果物（CSV/Excel/HTML/画像/PDF/テキスト） | `materials/{csv,excel,html,images,pdf,text}/` |
| テスト用一時ファイル | `tests/fixtures/` |
| ログ・デバッグ出力 | `logs/` または `.sd/` |

## ファイル保護（hook未整備のため文で維持・削減対象外）

- **rm 禁止**: 不要ファイルは `.sd/cleanup/archive/` へ移動（`/cleanup` 整理・`/cleanup:restore` 復元・`/cleanup:history` 履歴）
- **上書き禁止**: ユーザー提供ファイル・`materials/` 成果物・`.sd/ai-coordination/` 文書・`.sessions/` 記録は
  上書きせず別名で新規作成（`_v2` 等）。スクリプト再生成時は事前にアーカイブへバックアップ
  （背景: Excel上書きでレイアウト崩壊事故）
- 例外: ソースコード（src/, tests/）・設定/ルール（.claude/ 等）・ビルド出力（dist/）は上書き可。
  削除・上書きはユーザーが明示許可した場合のみ

詳細（cleanup分類・保護対象一覧）: `docs/rules-reference/cleanup/file-organization-full.md`
