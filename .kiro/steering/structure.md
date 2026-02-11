# SD002 構造ステアリング

## プロジェクト構造概要

```
sd002/
├── .kiro/                  # 仕様書駆動開発管理（SD001統合）
│   ├── specs/             # 仕様書（JSON + Markdown）
│   │   └── sd002-framework/
│   │       ├── spec.json           # メタデータ
│   │       ├── requirements.md     # 要件定義
│   │       ├── design.md           # 技術設計
│   │       └── tasks.md            # 実装タスク
│   ├── settings/          # プロジェクト設定
│   │   ├── project.yaml            # プロジェクト設定
│   │   └── quality-gates.yaml      # 品質ゲート設定
│   ├── traceability/      # トレーサビリティマトリックス
│   │   └── matrix.json
│   ├── ids/               # ID管理
│   │   └── registry.json
│   ├── steering/          # ステアリングドキュメント
│   │   ├── product.md              # プロダクト戦略
│   │   ├── tech.md                 # 技術戦略
│   │   ├── structure.md            # 構造管理（本ファイル）
│   │   └── integration.md          # 統合ガイド
│   ├── backups/           # バックアップ
│   ├── sync-reports/      # 同期レポート
│   │   └── creation-report.md
│   ├── implementation-strategy/    # 実装戦略
│   └── tag-manager-config.yaml     # タグ管理設定
│
├── src/                   # ソースコード
│   ├── core/              # コア機能
│   │   └── (SD001/GA001統合コア)
│   ├── mocks/             # GASサービスモック（GA001）
│   │   ├── SpreadsheetApp.mock.ts
│   │   ├── DriveApp.mock.ts
│   │   ├── GmailApp.mock.ts
│   │   ├── Logger.mock.ts
│   │   ├── PropertiesService.mock.ts
│   │   ├── UrlFetchApp.mock.ts
│   │   ├── Utilities.mock.ts
│   │   └── index.ts
│   ├── spec-driven/       # 仕様書駆動エンジン（SD001）
│   │   ├── SpecLoader.ts
│   │   ├── IdManager.ts
│   │   ├── TraceabilityEngine.ts
│   │   └── QualityGateRunner.ts
│   ├── gas-integration/   # GAS統合レイヤー
│   │   ├── GasBuilder.ts
│   │   ├── GasDeployer.ts
│   │   └── GasValidator.ts
│   ├── env/               # 環境抽象化レイヤー（GA001 Env Pattern）
│   │   ├── LocalEnv.ts            # ローカル環境実装
│   │   ├── GasEnv.ts              # GAS環境実装
│   │   └── EnvFactory.ts
│   ├── helpers/           # ヘルパー関数
│   │   └── (共通ユーティリティ)
│   ├── types/             # 型定義
│   │   └── index.ts
│   └── interfaces/        # インターフェース定義
│       ├── IEnv.ts                # 環境インターフェース
│       ├── ISpec.ts               # 仕様書インターフェース
│       └── (その他インターフェース)
│
├── tests/                 # テスト
│   ├── unit/              # ユニットテスト
│   │   ├── mocks/                 # モックテスト
│   │   ├── spec-driven/           # 仕様書駆動テスト
│   │   └── env/                   # 環境レイヤーテスト
│   ├── integration/       # 統合テスト
│   │   ├── env-integration/       # 環境統合テスト
│   │   └── spec-integration/      # 仕様書統合テスト
│   └── e2e/               # E2Eテスト
│       ├── gas-simulation/        # GAS疑似実行テスト
│       └── deployment/            # デプロイテスト
│
├── examples/              # 使用例
│   ├── basic/             # 基本例
│   ├── advanced/          # 応用例
│   └── integration/       # 統合例
│
├── docs/                  # 追加ドキュメント
│   ├── api/               # API仕様書
│   ├── guides/            # ガイド
│   └── tutorials/         # チュートリアル
│
├── bin/                   # CLIスクリプト
│   └── sd002.ts           # メインCLI
│
├── dist/                  # ビルド出力
│   ├── gas/               # GASデプロイ用
│   └── local/             # ローカル実行用
│
├── .claude/               # Claude Code設定
│   └── commands/          # カスタムコマンド
│
├── .git/                  # Gitリポジトリ
├── .gitignore
├── package.json
├── tsconfig.json
├── jest.config.js
├── .eslintrc.js
├── .prettierrc
├── CLAUDE.md              # AI開発司令塔
└── README.md
```

## ディレクトリ役割

### .kiro/ - 仕様書駆動開発管理

**目的**: SD001の仕様書駆動開発フレームワーク統合

**主要ファイル**:
- `specs/sd002-framework/spec.json`: 仕様書メタデータ
- `specs/sd002-framework/requirements.md`: 要件定義書
- `specs/sd002-framework/design.md`: 技術設計書
- `specs/sd002-framework/tasks.md`: 実装タスク

**管理対象**:
- 要件トレーサビリティ
- ID管理（要件ID、設計ID、コードID、テストID）
- 品質ゲート設定
- 仕様書バージョン管理

### src/ - ソースコード

**レイヤー構造**:

```
┌─────────────────────────────────────────┐
│  Application Layer                      │
│  (ビジネスロジック)                      │
│  - GAS非依存                            │
│  - IEnvインターフェース経由のみアクセス   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  Env Abstraction Layer (env/)          │
│  - LocalEnv: ローカル環境実装           │
│  - GasEnv: GAS環境実装                  │
│  - IEnv: 環境インターフェース           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  Mock/GAS Service Layer                │
│  - mocks/: GASサービスモック            │
│  - GAS APIs: 本番GASサービス            │
└─────────────────────────────────────────┘
```

**主要ディレクトリ**:
- `core/`: フレームワークコア機能
- `mocks/`: GAS APIモック実装
- `spec-driven/`: 仕様書駆動エンジン
- `gas-integration/`: GAS統合ツール
- `env/`: 環境抽象化レイヤー

### tests/ - テスト

**テスト戦略**:

```
ユニットテスト (tests/unit/)
  ↓
統合テスト (tests/integration/)
  ↓
E2Eテスト (tests/e2e/)
```

**カバレッジ目標**:
- ユニット: 80%以上
- 統合: 70%以上
- E2E: 60%以上

### examples/ - 使用例

**目的**: フレームワーク利用者向けサンプルコード

**構成**:
- `basic/`: 基本的な使い方
- `advanced/`: 応用的な使い方
- `integration/`: SD001/GA001統合例

## ファイル命名規則

### TypeScriptファイル

```
ファイル種別              命名規則                     例
──────────────────────────────────────────────────────
クラス                   PascalCase.ts               MockSpreadsheetApp.ts
インターフェース          I-PascalCase.ts            IEnv.ts
型定義                   kebab-case.types.ts        spec-types.ts
テスト                   *.test.ts                  LocalEnv.test.ts
モック                   *.mock.ts                  DriveApp.mock.ts
ヘルパー                 kebab-case.ts              string-utils.ts
```

### Markdownファイル

```
ファイル種別              命名規則                     例
──────────────────────────────────────────────────────
仕様書                   lowercase.md                requirements.md
ステアリング              lowercase.md                product.md
レポート                 UPPERCASE.md                CREATION_REPORT.md
ガイド                   kebab-case.md              integration-guide.md
README                   README.md                   README.md
```

### 設定ファイル

```
ファイル種別              命名規則                     例
──────────────────────────────────────────────────────
YAML設定                 kebab-case.yaml            project.yaml
JSON設定                 kebab-case.json            spec.json
TypeScript設定           tsconfig*.json             tsconfig.json
Package設定              package.json               package.json
```

## コード配置ルール

### ビジネスロジック（src/core/）

**配置基準**: GAS非依存のロジック

```typescript
// ✅ 正しい配置
export function processData(env: IEnv, data: string[]): void {
  // IEnv経由でのみGAS機能アクセス
  const sheet = env.spreadsheet.getActiveSheet();
}

// ❌ 間違った配置（GAS直接依存）
export function processData(data: string[]): void {
  const sheet = SpreadsheetApp.getActiveSheet();
}
```

### モック（src/mocks/）

**配置基準**: GAS APIの完全互換モック

```typescript
// ✅ 正しい配置
export class MockSpreadsheetApp {
  getActiveSheet(): MockSheet {
    // GAS APIと同じシグネチャ
  }
}
```

### 環境レイヤー（src/env/）

**配置基準**: IEnv実装クラス

```typescript
// ✅ 正しい配置
export class LocalEnv implements IEnv {
  spreadsheet = new MockSpreadsheetApp();
  logger = new MockLogger();
}
```

### テスト（tests/）

**配置基準**: ソースコードと同じディレクトリ構造

```
src/env/LocalEnv.ts  →  tests/unit/env/LocalEnv.test.ts
src/mocks/DriveApp.mock.ts  →  tests/unit/mocks/DriveApp.mock.test.ts
```

## 依存関係ルール

### 許可される依存関係

```
Application Layer
    ↓ (OK)
Env Abstraction Layer
    ↓ (OK)
Mock/GAS Service Layer
```

### 禁止される依存関係

```
Application Layer
    ↓ (NG - 直接依存禁止)
Mock/GAS Service Layer
```

## 拡張ポイント

### 新しいGAS APIモック追加

1. `src/mocks/XxxApp.mock.ts` を作成
2. GAS APIと完全互換のインターフェース実装
3. `src/mocks/index.ts` にエクスポート追加
4. `src/interfaces/IEnv.ts` にサービス追加
5. `src/env/LocalEnv.ts` にモック統合
6. `tests/unit/mocks/XxxApp.mock.test.ts` 作成

### 新しい品質ゲート追加

1. `.kiro/settings/quality-gates.yaml` に定義追加
2. `src/spec-driven/QualityGateRunner.ts` に実装追加
3. テスト追加

### 新しいCLIコマンド追加

1. `bin/sd002.ts` にコマンド定義追加
2. `src/core/` に実装追加
3. ドキュメント更新

## 移行ガイド

### 旧構造からの移行

```
旧: 01_requirements/01_requirements.md
新: .kiro/specs/sd002-framework/requirements.md

旧: 02_technical_design/01_architecture.md
新: .kiro/specs/sd002-framework/design.md

旧: docs/IMPLEMENTATION_TASKS.md
新: .kiro/specs/sd002-framework/tasks.md

旧: docs/integration-guide.md
新: .kiro/steering/integration.md

旧: docs/CREATION_REPORT.md
新: .kiro/sync-reports/creation-report.md
```

**削除されたディレクトリ**:
- `01_requirements/` → `.kiro/specs/`に統合
- `02_technical_design/` → `.kiro/specs/`に統合
- `03_frontend_design/` → 該当なし（GASプロジェクトのため削除）
- `04_library_docs/` → `docs/api/`に移動

**保持されたディレクトリ**:
- `05_management/` → プロジェクト管理として継続使用

## バージョン管理

### Git管理対象

- すべてのソースコード（`src/`）
- すべてのテスト（`tests/`）
- 仕様書（`.kiro/`）
- 設定ファイル
- ドキュメント

### Git管理対象外

```
node_modules/
dist/
.kiro/backups/
.kiro/sync-reports/
test-results/
coverage/
*.log
.env
```

---

最終更新: 2025-11-15
次回レビュー: 2025-12-01
