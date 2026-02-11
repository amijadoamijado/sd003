# SD002フレームワーク実装依頼書（Gemini向け）

**作成日**: 2025-11-15
**依頼元**: Claude Code
**実装担当**: Gemini
**プロジェクト**: SD002 - GAS環境向け仕様書駆動開発フレームワーク

---

## 📋 実装依頼概要

SD002フレームワークの**Phase 1〜4の実装**をGeminiに依頼します。
基盤構築（Phase 0）は完了済みで、本格的な機能実装が必要です。

---

## 🎯 プロジェクト理解のための必読ドキュメント

### 最優先（必ず最初に読む）
1. **`CLAUDE.md`** - プロジェクト指針・GAS環境開発原則
2. **`01_requirements/01_requirements.md`** - 要件定義書
3. **`docs/architecture.md`** - アーキテクチャ設計書

### 参考資料
4. **`docs/integration-guide.md`** - 統合ガイド
5. **`docs/CREATION_REPORT.md`** - 作成レポート
6. **`README.md`** - クイックスタート

---

## 🚀 実装フェーズと優先順位

### Phase 1: 基盤実装（最優先）
**推定工数**: 2-3日
**目的**: GA001とSD001の機能を完全移植

#### タスク1.1: GA001モックサービス移植
**参照元**: `/d/claudecode/ga001/src/mocks/`

実装対象:
- [ ] `SpreadsheetApp.mock.ts` - スプレッドシート完全モック
- [ ] `DriveApp.mock.ts` - Drive完全モック
- [ ] `GmailApp.mock.ts` - Gmail完全モック
- [ ] `PropertiesService.mock.ts` - プロパティサービス
- [ ] `UrlFetchApp.mock.ts` - URLFェッチ
- [ ] `Utilities.mock.ts` - ユーティリティ
- [ ] `Logger.mock.ts` - ロガー

**重要**:
- GAS公式APIと100%同じシグネチャ
- `src/env/LocalEnv.ts`から使用されることを想定
- TypeScript strictモード厳守

#### タスク1.2: SD001仕様書駆動機能移植
**参照元**: `/d/claudecode/sd001/src/`

実装対象:
- [ ] `src/spec-driven/id-registry.ts` - ID管理システム完全実装
- [ ] `src/spec-driven/traceability-engine.ts` - トレーサビリティエンジン
- [ ] `src/spec-driven/quality-gate.ts` - 品質ゲートシステム
- [ ] `src/spec-driven/git-detector.ts` - Git変更検出

**重要**:
- `.kiro/specs/`配下の仕様書を扱う
- ID形式: `REQ-001`, `DESIGN-001`, `IMPL-001`等
- トレーサビリティマトリックス生成

#### タスク1.3: LocalEnv統合
実装対象:
- [ ] `src/env/LocalEnv.ts`を拡張してモックサービス統合
- [ ] すべてのGAS APIモックを`LocalEnv`経由でアクセス可能に

---

### Phase 2: CLI実装
**推定工数**: 1-2日
**目的**: `sd002`コマンドラインツールの構築

#### タスク2.1: CLIエントリポイント
実装対象:
- [ ] `bin/sd002.js` - メインCLIエントリ
- [ ] `src/cli/index.ts` - CLIコントローラー
- [ ] `src/cli/commands/` - コマンドハンドラー

#### タスク2.2: 仕様書コマンド
実装対象:
- [ ] `sd002 spec:create <name>` - 新規仕様書作成
- [ ] `sd002 spec:validate` - 仕様書検証
- [ ] `sd002 spec:sync` - 仕様書同期
- [ ] `sd002 spec:list` - 仕様書一覧

#### タスク2.3: 品質ゲートコマンド
実装対象:
- [ ] `sd002 qa:test` - テスト実行
- [ ] `sd002 qa:deploy:safe` - デプロイ前検証
- [ ] `sd002 qa:coverage` - カバレッジ確認

---

### Phase 3: テスト実装
**推定工数**: 2-3日
**目的**: カバレッジ80%達成、疑似GAS環境テスト

#### タスク3.1: ユニットテスト
実装場所: `tests/unit/`

テスト対象:
- [ ] `LocalEnv.test.ts` - ローカル環境テスト
- [ ] `GasEnv.test.ts` - GAS環境テスト
- [ ] `id-registry.test.ts` - ID管理テスト
- [ ] `traceability-engine.test.ts` - トレーサビリティテスト
- [ ] `quality-gate.test.ts` - 品質ゲートテスト
- [ ] 各モックサービスのテスト

**目標**: カバレッジ80%以上

#### タスク3.2: 統合テスト
実装場所: `tests/integration/`

テスト対象:
- [ ] `env-integration.test.ts` - 環境切り替えテスト
- [ ] `spec-workflow.test.ts` - 仕様書ワークフローテスト
- [ ] `quality-gate-integration.test.ts` - 品質ゲート統合テスト

#### タスク3.3: E2Eテスト
実装場所: `tests/e2e/`

テスト対象:
- [ ] `gas-mock-e2e.test.ts` - 疑似GAS環境でのE2E
- [ ] `spec-driven-e2e.test.ts` - 仕様書駆動開発フローE2E

**重要**: 疑似GAS環境での完全なユースケース再現

---

### Phase 4: ドキュメント拡充
**推定工数**: 1-2日
**目的**: 利用者向けドキュメント整備

#### タスク4.1: APIリファレンス
実装対象:
- [ ] `docs/api/IEnv.md` - Envインターフェースリファレンス
- [ ] `docs/api/mocks.md` - モックサービスAPI
- [ ] `docs/api/spec-driven.md` - 仕様書駆動API

#### タスク4.2: チュートリアル
実装対象:
- [ ] `docs/tutorials/getting-started.md` - 初めてのSD002
- [ ] `docs/tutorials/gas-development.md` - GAS開発ガイド
- [ ] `docs/tutorials/spec-driven-workflow.md` - 仕様書駆動開発ワークフロー

#### タスク4.3: サンプルプロジェクト
実装対象:
- [ ] `examples/basic-gas-app/` - 基本的なGASアプリ
- [ ] `examples/spec-driven-app/` - 仕様書駆動開発サンプル

---

## ⚠️ 実装時の必須遵守事項

### GAS環境開発原則（CLAUDE.md参照）

#### 原則1: GAS環境を常に意識
- ✅ すべてのコードはGASで動作することを想定
- ❌ Node.js専用機能（`fs`, `path`, `process`）禁止
- ✅ CommonJS形式でエクスポート

#### 原則2: デプロイ前バグ撲滅
- ✅ 疑似GAS環境での徹底的なテスト
- ✅ LocalEnvとGasEnvの完全な互換性
- ✅ カバレッジ80%以上必須

#### 原則3: 手戻り防止
- ✅ 全品質ゲート（8段階）を通過
- ✅ E2Eテストで全ユースケース検証
- ✅ デプロイリハーサル実施

#### 原則4: 疑似GAS環境の精度向上
- ✅ GAS API仕様との100%一致
- ✅ 実際のSpreadsheet/Drive/Gmail等のモック完備

### TypeScript実装ルール

```typescript
// ✅ 正しい実装例
export function processData(env: IEnv, data: string[]): void {
  const sheet = env.spreadsheet.getActiveSheet();
  const logger = env.logger;
  // Env経由でGAS APIにアクセス
}

// ❌ 禁止パターン
import * as fs from 'fs'; // Node.js専用機能禁止
const sheet = SpreadsheetApp.getActiveSheet(); // 直接参照禁止
```

### コード品質基準
- ✅ TypeScript strictモード必須
- ✅ ESLintエラー0件
- ✅ JSDocコメント完備
- ✅ 適切なエラーハンドリング
- ✅ ユニットテストカバレッジ80%以上

---

## 📊 実装完了基準

各フェーズの完了基準:

### Phase 1完了条件
- [ ] 全モックサービス実装済み
- [ ] 仕様書駆動機能実装済み
- [ ] LocalEnvに統合済み
- [ ] `npm run build`成功
- [ ] TypeScriptエラー0件

### Phase 2完了条件
- [ ] `sd002`コマンド実行可能
- [ ] 全サブコマンド実装済み
- [ ] ヘルプドキュメント完備
- [ ] コマンドテスト済み

### Phase 3完了条件
- [ ] カバレッジ80%以上達成
- [ ] 全テストパス
- [ ] E2Eテストで実際のユースケース検証済み
- [ ] 疑似GAS環境テスト済み

### Phase 4完了条件
- [ ] APIリファレンス完成
- [ ] チュートリアル完成
- [ ] サンプルプロジェクト動作確認済み

---

## 🔧 開発環境セットアップ

```bash
# SD002プロジェクトへ移動
cd /d/claudecode/sd002

# 依存関係インストール
npm install

# ビルドテスト
npm run build

# 開発モード起動
npm run dev

# テスト実行
npm test
```

---

## 📚 参照すべき既存実装

### GA001参照ポイント
- **モック実装**: `/d/claudecode/ga001/src/mocks/`
- **テストヘルパー**: `/d/claudecode/ga001/src/helpers/`
- **型定義**: `/d/claudecode/ga001/src/types/`

### SD001参照ポイント
- **仕様書駆動**: `/d/claudecode/sd001/src/spec-driven/`
- **CLIコマンド**: `/d/claudecode/sd001/.claude/commands/`
- **品質ゲート**: `/d/claudecode/sd001/src/quality-gates/`

---

## 🎯 実装の進め方推奨

### Step 1: プロジェクト理解（30分）
1. `CLAUDE.md`を熟読してGAS環境開発原則を理解
2. `docs/architecture.md`でアーキテクチャ把握
3. 既存実装（LocalEnv, GasEnv, IEnv）を確認

### Step 2: Phase 1実装（2-3日）
1. GA001モック移植開始
2. 1つのモック完成ごとにテスト追加
3. LocalEnvに統合
4. SD001機能移植
5. ビルドテスト

### Step 3: Phase 2実装（1-2日）
1. CLIフレームワーク構築
2. コマンド実装
3. 動作確認

### Step 4: Phase 3実装（2-3日）
1. ユニットテスト作成
2. カバレッジ80%達成
3. 統合・E2Eテスト作成

### Step 5: Phase 4実装（1-2日）
1. ドキュメント作成
2. サンプルプロジェクト作成

---

## 🚨 重要な注意事項

### 禁止事項（CLAUDE.md参照）
- ❌ CLAUDE.md、要件定義書の勝手な変更
- ❌ GAS API直接参照（必ずEnv経由）
- ❌ Node.js専用機能の使用
- ❌ テストカバレッジ80%未満
- ❌ 疑似GAS環境でのテスト省略

### Git運用
- ✅ 機能ごとにコミット
- ✅ わかりやすいコミットメッセージ
- ✅ Phase完了時にタグ付け

```bash
git commit -m "feat(phase1): GA001モックサービス移植完了"
git tag -a v1.1.0-phase1 -m "Phase 1: 基盤実装完了"
```

---

## 📞 質問・相談

実装中に不明点があれば、以下を確認:

1. **CLAUDE.md** - プロジェクト指針
2. **docs/architecture.md** - アーキテクチャ設計
3. **既存実装** - LocalEnv、GasEnv、IEnv

それでも解決しない場合は、Claudeに相談してください。

---

## 📈 進捗報告フォーマット

各フェーズ完了時に以下を報告:

```markdown
## Phase X完了報告

### 実装内容
- 実装したファイル一覧
- コード行数
- テストカバレッジ

### 動作確認
- ビルド結果
- テスト結果
- 動作確認スクリーンショット

### 課題・懸念事項
- 発見した問題
- 改善提案

### 次フェーズ準備
- 次に必要な作業
```

---

**実装開始準備OK！頑張ってください！**

最終更新: 2025-11-15
作成者: Claude Code
