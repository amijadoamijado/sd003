# gas-fakes Testing Integration タスク一覧

## 基本情報
- **機能名**: gas-fakes Testing Integration
- **バージョン**: 1.0.0
- **ステータス**: 実装中
- **作成日**: 2026-02-15

## タスク一覧

### Task 1: @mcpher/gas-fakes インストール [DONE]
- **ファイル**: package.json
- **内容**: devDependency に @mcpher/gas-fakes ^1.2.0 追加
- **受入条件**: npm install 成功、既存テストに影響なし

### Task 2: Jest セットアップ作成 [DONE]
- **ファイル**: tests/gas-fakes/setup.ts
- **内容**: ESM動的インポート、isGasFakesLoaded()ヘルパー
- **受入条件**: import成功/失敗を適切にハンドリング

### Task 3: SpreadsheetApp テスト作成 [DONE]
- **ファイル**: tests/gas-fakes/spreadsheet.gas-fakes.test.ts
- **内容**: スプレッドシート作成/取得、シート操作、セル読み書き
- **受入条件**: GCP未認証時はスキップ、認証時はPass

### Task 4: PropertiesService テスト作成 [DONE]
- **ファイル**: tests/gas-fakes/properties.gas-fakes.test.ts
- **内容**: Script/User/Documentプロパティの CRUD
- **受入条件**: GCP未認証時はスキップ、認証時はPass

### Task 5: DriveApp テスト作成 [DONE]
- **ファイル**: tests/gas-fakes/drive.gas-fakes.test.ts
- **内容**: ファイル作成/取得、フォルダ操作、Blob処理
- **受入条件**: GCP未認証時はスキップ、認証時はPass

### Task 6: npm スクリプト追加 [DONE]
- **ファイル**: package.json
- **内容**: "test:gas-fakes" スクリプト追加
- **受入条件**: `npm run test:gas-fakes` で3テストスイート実行

### Task 7: テスト基準更新 [DONE]
- **ファイル**: .claude/rules/testing/testing-standards.md
- **内容**: 3層テスト戦略セクション追加
- **受入条件**: Tier-1/2/3比較表、選択基準

## 進捗サマリー

| 状態 | 件数 |
|------|------|
| DONE | 7 |
| TODO | 0 |
| 合計 | 7 |

---
最終更新: 2026-02-15
