# SD002実装タスク一覧

**作成日**: 2025-11-15
**実装担当**: Gemini
**総推定工数**: 6-10日

---

## Phase 1: 基盤実装（2-3日）

### タスク1.1: SpreadsheetApp モック実装
- **ファイル**: `src/mocks/SpreadsheetApp.mock.ts`
- **参照**: `/d/claudecode/ga001/src/mocks/spreadsheet-app.mock.ts`
- **優先度**: 🔴 最高
- **推定時間**: 8時間
- **実装内容**:
  - [ ] SpreadsheetApp.getActiveSpreadsheet()
  - [ ] SpreadsheetApp.openById()
  - [ ] SpreadsheetApp.create()
  - [ ] Spreadsheet クラス
  - [ ] Sheet クラス
  - [ ] Range クラス
- **テスト**: `tests/unit/mocks/SpreadsheetApp.test.ts`

### タスク1.2: DriveApp モック実装
- **ファイル**: `src/mocks/DriveApp.mock.ts`
- **参照**: `/d/claudecode/ga001/src/mocks/drive-app.mock.ts`
- **優先度**: 🟡 高
- **推定時間**: 4時間
- **実装内容**:
  - [ ] DriveApp.getFileById()
  - [ ] DriveApp.getFolderById()
  - [ ] DriveApp.createFile()
  - [ ] File クラス
  - [ ] Folder クラス
- **テスト**: `tests/unit/mocks/DriveApp.test.ts`

### タスク1.3: GmailApp モック実装
- **ファイル**: `src/mocks/GmailApp.mock.ts`
- **参照**: `/d/claudecode/ga001/src/mocks/gmail-app.mock.ts`
- **優先度**: 🟡 高
- **推定時間**: 4時間
- **実装内容**:
  - [ ] GmailApp.sendEmail()
  - [ ] GmailApp.getInboxThreads()
  - [ ] GmailMessage クラス
  - [ ] GmailThread クラス
- **テスト**: `tests/unit/mocks/GmailApp.test.ts`

### タスク1.4: PropertiesService モック実装
- **ファイル**: `src/mocks/PropertiesService.mock.ts`
- **優先度**: 🟡 高
- **推定時間**: 2時間
- **実装内容**:
  - [ ] PropertiesService.getScriptProperties()
  - [ ] PropertiesService.getUserProperties()
  - [ ] Properties クラス
- **テスト**: `tests/unit/mocks/PropertiesService.test.ts`

### タスク1.5: Logger モック実装
- **ファイル**: `src/mocks/Logger.mock.ts`
- **優先度**: 🟢 中
- **推定時間**: 1時間
- **実装内容**:
  - [ ] Logger.log()
  - [ ] Logger.getLog()
  - [ ] Logger.clear()
- **テスト**: `tests/unit/mocks/Logger.test.ts`

### タスク1.6: LocalEnv統合
- **ファイル**: `src/env/LocalEnv.ts`
- **優先度**: 🔴 最高
- **推定時間**: 4時間
- **実装内容**:
  - [ ] すべてのモックサービスをLocalEnvに統合
  - [ ] IEnvインターフェース完全実装
  - [ ] 初期化処理の実装
- **テスト**: `tests/unit/env/LocalEnv.test.ts`

### タスク1.7: ID Registry実装
- **ファイル**: `src/spec-driven/id-registry.ts`
- **参照**: `/d/claudecode/sd001/src/spec-driven/id-registry.ts`
- **優先度**: 🔴 最高
- **推定時間**: 6時間
- **実装内容**:
  - [ ] ID生成（REQ-001, DESIGN-001形式）
  - [ ] ID検証
  - [ ] ID一覧取得
  - [ ] ID検索
- **テスト**: `tests/unit/spec-driven/id-registry.test.ts`

### タスク1.8: Traceability Engine実装
- **ファイル**: `src/spec-driven/traceability-engine.ts`
- **参照**: `/d/claudecode/sd001/src/spec-driven/traceability-engine.ts`
- **優先度**: 🔴 最高
- **推定時間**: 8時間
- **実装内容**:
  - [ ] トレーサビリティマトリックス生成
  - [ ] 要件-設計-実装のリンク管理
  - [ ] カバレッジ分析
- **テスト**: `tests/unit/spec-driven/traceability-engine.test.ts`

### タスク1.9: Quality Gate実装
- **ファイル**: `src/spec-driven/quality-gate.ts`
- **参照**: `/d/claudecode/sd001/src/spec-driven/quality-gate.ts`
- **優先度**: 🔴 最高
- **推定時間**: 10時間
- **実装内容**:
  - [ ] 8段階品質ゲート実装
  - [ ] 構文検証
  - [ ] 型検証
  - [ ] リント検証
  - [ ] セキュリティ検証
  - [ ] テスト検証
  - [ ] パフォーマンス検証
  - [ ] ドキュメント検証
  - [ ] 統合検証
- **テスト**: `tests/unit/spec-driven/quality-gate.test.ts`

**Phase 1 チェックポイント**:
- [ ] 全モック実装完了
- [ ] LocalEnv統合完了
- [ ] 仕様書駆動機能完了
- [ ] npm run build 成功
- [ ] TypeScriptエラー0件
- [ ] ユニットテストパス

---

## Phase 2: CLI実装（1-2日）

### タスク2.1: CLIエントリポイント
- **ファイル**: `bin/sd002.js`
- **優先度**: 🔴 最高
- **推定時間**: 2時間
- **実装内容**:
  - [ ] Shebang設定
  - [ ] コマンドルーター
  - [ ] エラーハンドリング
- **テスト**: 手動テスト

### タスク2.2: CLIコントローラー
- **ファイル**: `src/cli/index.ts`
- **優先度**: 🔴 最高
- **推定時間**: 4時間
- **実装内容**:
  - [ ] コマンドパーサー
  - [ ] ヘルプ表示
  - [ ] バージョン表示
- **テスト**: `tests/unit/cli/index.test.ts`

### タスク2.3: spec:create コマンド
- **ファイル**: `src/cli/commands/spec-create.ts`
- **優先度**: 🟡 高
- **推定時間**: 3時間
- **実装内容**:
  - [ ] 新規仕様書テンプレート生成
  - [ ] .kiro/specs/配下に配置
  - [ ] ID自動生成
- **テスト**: `tests/unit/cli/commands/spec-create.test.ts`

### タスク2.4: spec:validate コマンド
- **ファイル**: `src/cli/commands/spec-validate.ts`
- **優先度**: 🟡 高
- **推定時間**: 3時間
- **実装内容**:
  - [ ] 仕様書JSONスキーマ検証
  - [ ] ID重複チェック
  - [ ] トレーサビリティ検証
- **テスト**: `tests/unit/cli/commands/spec-validate.test.ts`

### タスク2.5: qa:deploy:safe コマンド
- **ファイル**: `src/cli/commands/qa-deploy-safe.ts`
- **優先度**: 🔴 最高
- **推定時間**: 4時間
- **実装内容**:
  - [ ] 全品質ゲート実行
  - [ ] デプロイ可否判定
  - [ ] レポート生成
- **テスト**: `tests/unit/cli/commands/qa-deploy-safe.test.ts`

**Phase 2 チェックポイント**:
- [ ] sd002 コマンド実行可能
- [ ] 全サブコマンド実装済み
- [ ] ヘルプドキュメント完備
- [ ] コマンドテスト済み

---

## Phase 3: テスト実装（2-3日）

### タスク3.1: LocalEnv ユニットテスト
- **ファイル**: `tests/unit/env/LocalEnv.test.ts`
- **優先度**: 🔴 最高
- **推定時間**: 4時間
- **テスト内容**:
  - [ ] 初期化テスト
  - [ ] モックサービス取得テスト
  - [ ] IEnv準拠テスト

### タスク3.2: GasEnv ユニットテスト
- **ファイル**: `tests/unit/env/GasEnv.test.ts`
- **優先度**: 🔴 最高
- **推定時間**: 4時間
- **テスト内容**:
  - [ ] GAS API呼び出しテスト
  - [ ] IEnv準拠テスト

### タスク3.3: モックサービステスト
- **場所**: `tests/unit/mocks/`
- **優先度**: 🔴 最高
- **推定時間**: 8時間
- **テスト内容**:
  - [ ] 各モックサービスの動作テスト
  - [ ] GAS API仕様との一致確認

### タスク3.4: 統合テスト
- **ファイル**: `tests/integration/env-integration.test.ts`
- **優先度**: 🟡 高
- **推定時間**: 6時間
- **テスト内容**:
  - [ ] LocalEnv ⇔ GasEnv切り替えテスト
  - [ ] 同一コードの両環境動作テスト

### タスク3.5: E2Eテスト
- **ファイル**: `tests/e2e/gas-mock-e2e.test.ts`
- **優先度**: 🔴 最高
- **推定時間**: 8時間
- **テスト内容**:
  - [ ] 実際のユースケース再現
  - [ ] 疑似GAS環境での完全動作確認

### タスク3.6: カバレッジ目標達成
- **優先度**: 🔴 最高
- **推定時間**: 4時間
- **作業内容**:
  - [ ] カバレッジレポート確認
  - [ ] 不足部分のテスト追加
  - [ ] 80%達成確認

**Phase 3 チェックポイント**:
- [ ] カバレッジ80%以上
- [ ] 全テストパス
- [ ] E2Eテスト成功
- [ ] 疑似GAS環境テスト完了

---

## Phase 4: ドキュメント拡充（1-2日）

### タスク4.1: APIリファレンス
- **場所**: `docs/api/`
- **優先度**: 🟡 高
- **推定時間**: 6時間
- **実装内容**:
  - [ ] `IEnv.md` - Envインターフェース
  - [ ] `mocks.md` - モックサービスAPI
  - [ ] `spec-driven.md` - 仕様書駆動API

### タスク4.2: チュートリアル
- **場所**: `docs/tutorials/`
- **優先度**: 🟡 高
- **推定時間**: 8時間
- **実装内容**:
  - [ ] `getting-started.md` - はじめてのSD002
  - [ ] `gas-development.md` - GAS開発ガイド
  - [ ] `spec-driven-workflow.md` - 仕様書駆動ワークフロー

### タスク4.3: サンプルプロジェクト
- **場所**: `examples/`
- **優先度**: 🟢 中
- **推定時間**: 8時間
- **実装内容**:
  - [ ] `basic-gas-app/` - 基本GASアプリ
  - [ ] `spec-driven-app/` - 仕様書駆動サンプル

**Phase 4 チェックポイント**:
- [ ] APIリファレンス完成
- [ ] チュートリアル完成
- [ ] サンプルプロジェクト動作確認済み

---

## 実装順序推奨

### Week 1 (Phase 1)
**Day 1-2**: モック実装
- SpreadsheetApp（最優先）
- DriveApp
- その他モック

**Day 3**: LocalEnv統合 + 仕様書駆動基盤
- LocalEnv統合
- ID Registry
- Traceability Engine基本

**Day 4**: Quality Gate実装

### Week 2 (Phase 2-3)
**Day 5-6**: CLI実装
- CLIフレームワーク
- 各コマンド実装

**Day 7-8**: テスト実装
- ユニットテスト
- 統合テスト
- E2Eテスト

### Week 2後半 (Phase 4)
**Day 9-10**: ドキュメント
- APIリファレンス
- チュートリアル
- サンプルプロジェクト

---

## 進捗トラッキング

各タスク完了時にチェック:
- [ ] コード実装
- [ ] テスト作成
- [ ] ドキュメント更新
- [ ] Git commit

各Phase完了時:
- [ ] Phase完了報告作成
- [ ] Git tag作成
- [ ] Claudeへ報告

---

最終更新: 2025-11-15
