# SD002 Framework - 統合アーキテクチャ設計書

## 1. アーキテクチャ概要

SD002は、SD001（仕様書駆動開発フレームワーク）とGA001（GASローカルテスト環境）を統合した、次世代のAI駆動型開発フレームワークです。

### 1.1 設計原則

1. **仕様書ファースト**: すべての開発は仕様書から開始
2. **環境独立性**: ビジネスロジックはインフラから完全分離
3. **品質保証**: 自動化された8段階品質ゲート
4. **トレーサビリティ**: 要件から実装まで完全な追跡可能性

### 1.2 統合戦略

```
┌─────────────────────────────────────────────────────────┐
│                    SD002 Framework                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────┐         ┌──────────────────┐        │
│  │   SD001       │         │     GA001        │        │
│  │  Spec-Driven  │◄────────┤  GAS Testing     │        │
│  │  Development  │  統合   │  Environment     │        │
│  └───────────────┘         └──────────────────┘        │
│         │                           │                   │
│         │                           │                   │
│         ▼                           ▼                   │
│  ┌─────────────────────────────────────────────┐       │
│  │         統合レイヤー（SD002 Core）            │       │
│  │  - 統一CLI                                  │       │
│  │  - ワークフロー自動化                        │       │
│  │  - クロスレイヤー連携                        │       │
│  └─────────────────────────────────────────────┘       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 2. レイヤー構成

### 2.1 仕様書駆動レイヤー（SD001継承）

#### 主要コンポーネント
- **ID Registry**: 要件・設計・実装のID管理
- **Traceability Engine**: トレーサビリティマトリクス生成
- **Quality Gate**: 8段階品質検証
- **Git Change Detector**: 変更検出と仕様書同期

#### ディレクトリ構造
```
.kiro/
├── specs/              # 仕様書（JSON + Markdown）
├── settings/           # プロジェクト設定
├── traceability/       # トレーサビリティデータ
└── ids/                # ID管理データベース
```

#### データフロー
```
要件定義 → ID登録 → 設計 → 実装 → テスト → 品質ゲート → デプロイ
   ↓         ↓       ↓      ↓       ↓         ↓          ↓
  .kiro/specs/    ID Registry    Traceability Matrix
```

### 2.2 GAS抽象化レイヤー（GA001継承）

#### Env Interface Pattern
```typescript
// 統一インターフェース
interface IEnv {
  spreadsheet: ISpreadsheetService;
  logger: ILogger;
  properties: IPropertiesService;
  urlFetch: IUrlFetchService;
  drive: IDriveService;
}

// ローカル実装
class LocalEnv implements IEnv {
  spreadsheet = new MockSpreadsheetService();
  logger = new MockLogger();
  // ... 他のモックサービス
}

// GAS実装
class GasEnv implements IEnv {
  spreadsheet = new GasSpreadsheetService();
  logger = new GasLogger();
  // ... 実際のGASサービス
}
```

#### モックサービス
- `MockSpreadsheetApp`: スプレッドシート操作
- `MockPropertiesService`: プロパティ管理
- `MockUrlFetchApp`: HTTP通信
- `MockDriveApp`: ドライブ操作
- `MockLogger`: ロギング

#### ディレクトリ構造
```
src/
├── env/
│   ├── IEnv.ts              # 環境インターフェース
│   ├── LocalEnv.ts          # ローカル環境実装
│   └── GasEnv.ts            # GAS環境実装
├── mocks/
│   ├── spreadsheet-app/     # スプレッドシートモック
│   ├── properties-service/  # プロパティモック
│   └── ...
└── logic/
    └── business-logic.ts    # GAS非依存ロジック
```

### 2.3 統合レイヤー（SD002独自）

#### 統一CLI
```bash
sd002 spec:create <name>     # 仕様書作成
sd002 spec:validate          # 仕様書検証
sd002 spec:sync              # 仕様書同期
sd002 gas:init               # GAS初期化
sd002 gas:test               # GASテスト
sd002 qa:test                # 品質ゲート実行
sd002 qa:deploy:safe         # デプロイ前検証
```

#### ワークフロー自動化
```
開発ワークフロー:
1. 仕様書作成      → sd002 spec:create
2. ローカル開発    → npm run dev:server
3. テスト実行      → npm test
4. 品質検証        → sd002 qa:test
5. デプロイ前検証  → sd002 qa:deploy:safe
6. GASデプロイ     → npm run gas:deploy
```

#### クロスレイヤー連携
```typescript
// 仕様書駆動 × GAS開発の統合
class SD002Workflow {
  // 仕様書から実装へ
  async generateFromSpec(specPath: string): Promise<void> {
    const spec = await this.loadSpec(specPath);
    const template = this.generateTemplate(spec);
    await this.createFiles(template);
    await this.registerIds(spec);
  }

  // 実装から仕様書へ
  async syncToSpec(codePath: string): Promise<void> {
    const changes = await this.detectChanges(codePath);
    await this.updateSpec(changes);
    await this.updateTraceability();
  }

  // GAS環境でのテスト
  async testWithGasEnv(): Promise<void> {
    const env = new LocalEnv();
    await this.runTests(env);
    await this.qualityGate();
  }
}
```

## 3. データフロー

### 3.1 仕様書駆動フロー

```
┌──────────────┐
│ 要件定義     │
│ (.md)        │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 仕様書作成   │
│ (.kiro/specs)│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ ID登録       │
│ (ID Registry)│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 実装         │
│ (src/logic)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ トレーサビリティ│
│ 更新         │
└──────────────┘
```

### 3.2 GASローカル開発フロー

```
┌──────────────┐
│ ビジネスロジック│
│ 実装         │
│ (src/logic)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ LocalEnvで  │
│ テスト       │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 品質ゲート   │
│ (8段階)      │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ GasEnvで    │
│ デプロイ     │
└──────────────┘
```

## 4. 品質保証アーキテクチャ

### 4.1 8段階品質ゲート

```typescript
class QualityGate {
  async execute(): Promise<QualityReport> {
    const results = await Promise.all([
      this.stage1_syntaxValidation(),    // 構文検証
      this.stage2_typeValidation(),      // 型検証
      this.stage3_lintValidation(),      // リント検証
      this.stage4_securityValidation(),  // セキュリティ検証
      this.stage5_testValidation(),      // テスト検証
      this.stage6_performanceValidation(),// パフォーマンス検証
      this.stage7_documentationValidation(),// ドキュメント検証
      this.stage8_integrationValidation() // 統合検証
    ]);

    return this.generateReport(results);
  }
}
```

### 4.2 テスト戦略

```
テストピラミッド:

         ┌─────────┐
         │  E2E    │  (Playwright)
         ├─────────┤
         │ 統合    │  (Jest + LocalEnv)
         ├─────────┤
         │ ユニット │  (Jest)
         └─────────┘
```

#### テストレベル
1. **ユニットテスト**: 個別関数・クラス
2. **統合テスト**: LocalEnv環境でのワークフロー
3. **E2Eテスト**: Playwright による実環境テスト

## 5. セキュリティアーキテクチャ

### 5.1 環境分離

```
開発環境 (LocalEnv)
├── モックデータ
├── ローカルストレージ
└── テスト用認証情報

本番環境 (GasEnv)
├── 実データ
├── GASストレージ
└── 本番認証情報（Script Properties）
```

### 5.2 認証情報管理

```typescript
// ローカル環境
class LocalEnv implements IEnv {
  properties = {
    getProperty: (key: string) => process.env[key]
  };
}

// GAS環境
class GasEnv implements IEnv {
  properties = {
    getProperty: (key: string) => PropertiesService.getScriptProperties().getProperty(key)
  };
}
```

## 6. パフォーマンス最適化

### 6.1 ビルド最適化

```
TypeScript → トランスパイル → 最適化 → バンドル
    ↓            ↓            ↓         ↓
  型チェック    ES2022      Tree Shaking  圧縮
```

### 6.2 テスト最適化

```
並列実行 + キャッシング + インクリメンタルテスト
    ↓            ↓              ↓
  Jest         Results Cache   Changed Files Only
```

## 7. 拡張性設計

### 7.1 プラグインアーキテクチャ

```typescript
interface IPlugin {
  name: string;
  version: string;
  initialize(config: PluginConfig): Promise<void>;
  execute(context: ExecutionContext): Promise<PluginResult>;
}

class PluginManager {
  private plugins: Map<string, IPlugin> = new Map();

  registerPlugin(plugin: IPlugin): void {
    this.plugins.set(plugin.name, plugin);
  }

  async executePlugins(context: ExecutionContext): Promise<void> {
    for (const plugin of this.plugins.values()) {
      await plugin.execute(context);
    }
  }
}
```

### 7.2 カスタムモック追加

```typescript
// カスタムGASサービスのモック
class CustomServiceMock implements ICustomService {
  // モック実装
}

// LocalEnvへの追加
class ExtendedLocalEnv extends LocalEnv {
  customService = new CustomServiceMock();
}
```

## 8. デプロイメントアーキテクチャ

### 8.1 CI/CDパイプライン

```
GitHub Push
    ↓
GitHub Actions
    ↓
┌───────────────┐
│ 1. Install    │
├───────────────┤
│ 2. Build      │
├───────────────┤
│ 3. Test       │
├───────────────┤
│ 4. Quality    │
│    Gates      │
├───────────────┤
│ 5. Deploy     │
│    Guard      │
├───────────────┤
│ 6. GAS Deploy │
│    (Manual)   │
└───────────────┘
```

### 8.2 デプロイ戦略

```
開発 → ステージング → 本番
 ↓         ↓          ↓
Local    GAS Test   GAS Prod
Env      Script     Script
```

## 9. 監視・ロギング

### 9.1 ロギング戦略

```typescript
interface ILogger {
  log(message: string, level: LogLevel): void;
  error(message: string, error: Error): void;
  warn(message: string): void;
  info(message: string): void;
}

// ローカル環境: Console
class LocalLogger implements ILogger {
  log(message: string, level: LogLevel): void {
    console.log(`[${level}] ${message}`);
  }
}

// GAS環境: Logger + Stackdriver
class GasLogger implements ILogger {
  log(message: string, level: LogLevel): void {
    Logger.log(`[${level}] ${message}`);
    // Stackdriver Loggingへも送信
  }
}
```

## 10. 移行戦略

### 10.1 既存プロジェクトからの移行

```
既存プロジェクト
    ↓
┌────────────────────┐
│ 1. 仕様書作成      │
│    (手動)          │
├────────────────────┤
│ 2. Env導入         │
│    (自動スクリプト)│
├────────────────────┤
│ 3. ロジック分離    │
│    (半自動)        │
├────────────────────┤
│ 4. テスト移行      │
│    (手動)          │
└────────────────────┘
    ↓
SD002プロジェクト
```

### 10.2 段階的移行パス

1. **Phase 1**: SD002環境セットアップ
2. **Phase 2**: 既存コードのEnv化
3. **Phase 3**: テストの移行
4. **Phase 4**: 仕様書の作成
5. **Phase 5**: 完全移行

---

**設計原則**: 仕様書ファースト・環境独立・品質保証・トレーサビリティ

最終更新: 2025-11-15
バージョン: 1.0.0
