# gas-fakes Testing Integration 要件定義書

## 基本情報
- **機能名**: gas-fakes Testing Integration - 3-Tier GAS Local Testing Strategy
- **バージョン**: 1.0.0
- **ステータス**: 実装中
- **作成日**: 2026-02-15
- **最終更新**: 2026-02-15

## 1. 概要

### 1.1 目的
@mcpher/gas-fakesパッケージを導入し、GA001モックでは再現困難な「本番データの汚さ」（結合セル、フォーマット、バイナリデータ等）をTier-2テストで検証可能にする。

### 1.2 背景
- 既存のGA001モック（Tier-1）は軽量だが、GAS APIの忠実度が限定的
- 本番環境のSpreadsheetApp/DriveApp/PropertiesServiceは複雑な動作がある
- gas-fakesはNode.js上でGASランタイムをエミュレートし、中〜高忠実度のテストを実現

### 1.3 成功基準
- @mcpher/gas-fakes がdevDependencyとしてインストールされている
- tests/gas-fakes/ ディレクトリにTier-2テストが存在する
- `npm run test:gas-fakes` でTier-2テストが実行できる
- 既存テスト（Tier-1）に影響がない
- testing-standards.md に3層テスト戦略が記載されている

## 2. 機能要件

### REQ-GF-001: gas-fakes パッケージ導入
- **概要**: @mcpher/gas-fakes をdevDependencyとして追加
- **バージョン**: ^1.2.0
- **制約**: node >= 20.11.0 (ESM対応)
- **優先度**: High

### REQ-GF-002: Jest セットアップ
- **概要**: gas-fakes用のJestセットアップファイル作成
- **ファイル**: tests/gas-fakes/setup.ts
- **内容**: ESM動的インポート、グローバル変数チェック
- **優先度**: High

### REQ-GF-003: SpreadsheetApp テスト
- **概要**: SpreadsheetApp Tier-2テスト
- **ファイル**: tests/gas-fakes/spreadsheet.gas-fakes.test.ts
- **テスト項目**: スプレッドシート作成/取得、シート操作、セル読み書き
- **優先度**: High

### REQ-GF-004: PropertiesService テスト
- **概要**: PropertiesService Tier-2テスト
- **ファイル**: tests/gas-fakes/properties.gas-fakes.test.ts
- **テスト項目**: Script/User/Documentプロパティの CRUD操作
- **優先度**: High

### REQ-GF-005: DriveApp テスト
- **概要**: DriveApp Tier-2テスト
- **ファイル**: tests/gas-fakes/drive.gas-fakes.test.ts
- **テスト項目**: ファイル作成/取得、フォルダ操作、Blob処理
- **優先度**: Medium

### REQ-GF-006: npm スクリプト
- **概要**: gas-fakes専用テスト実行スクリプト
- **コマンド**: `npm run test:gas-fakes`
- **実装**: `jest --testPathPattern=tests/gas-fakes/`
- **優先度**: High

### REQ-GF-007: テスト基準更新
- **概要**: testing-standards.md に3層テスト戦略を追記
- **内容**: Tier-1/2/3の比較表、選択基準
- **優先度**: High

## 3. 非機能要件

### NFR-GF-001: Tier-1との共存
- gas-fakesテストは tests/gas-fakes/ に隔離
- 既存テスト（tests/unit/, tests/integration/）に影響なし
- `npm test` で全Tierが実行される

### NFR-GF-002: Graceful Skip
- GCP認証未設定時はテストを自動スキップ（FAIL扱いにしない）
- コンソールに設定方法を案内出力

## 4. 3層テスト戦略

| Tier | ツール | ディレクトリ | 速度 | 忠実度 | GCP認証 |
|------|--------|-------------|------|--------|---------|
| Tier-1 | GA001 Mock + LocalEnv | tests/unit/, tests/integration/ | < 1s | Low | No |
| Tier-2 | @mcpher/gas-fakes | tests/gas-fakes/ | < 30s | Medium-High | Partial |
| Tier-3 | Antigravity E2E | Production | Minutes | Highest | Yes |

---
最終更新: 2026-02-15
