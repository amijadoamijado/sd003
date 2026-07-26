# SD002 技術ステアリング

## 技術スタック

### コア技術
- **言語**: TypeScript 5.x（厳格モード）
- **ランタイム**: Node.js 18.x LTS（開発環境）
- **ターゲット**: Google Apps Script（本番環境）

### 開発ツール
- **ビルド**: TypeScript Compiler
- **テスト**: Jest 29.x
- **リント**: ESLint 8.x + Prettier
- **型定義**: @types/google-apps-script

### フレームワーク統合
- **SD001**: 仕様書駆動開発エンジン（v3.0.0）
- **GA001**: GASローカルテスト環境（v1.2.0）

## アーキテクチャ原則

### 1. 環境独立性（Env Interface Pattern）

**原則**: ビジネスロジックはGAS環境に依存しない

```typescript
// ❌ 悪い例: GAS直接依存
function processData(data: string[]): void {
  const sheet = SpreadsheetApp.getActiveSheet();
  Logger.log('Processing...');
}

// ✅ 良い例: Env経由
function processData(env: IEnv, data: string[]): void {
  const sheet = env.spreadsheet.getActiveSheet();
  env.logger.log('Processing...');
}
```

**メリット**:
- ローカル環境での完全なテスト可能性
- モックによる高速テスト実行
- 環境切り替えの容易性

### 2. 仕様書駆動（Spec-Driven Development）

**原則**: すべての開発は仕様書から開始する

```
要件定義 (.kiro/specs/*/requirements.md)
    ↓
設計書 (.kiro/specs/*/design.md)
    ↓
実装 (src/)
    ↓
テスト (tests/)
```

**トレーサビリティ**: 要件ID → 設計ID → コードID → テストID

### 3. 品質ファースト（8-Stage Quality Gates）

**原則**: デプロイ前にすべての品質問題を検出する

```
構文 → 型 → リント → セキュリティ → テスト → パフォーマンス → ドキュメント → 統合
```

**ブロッキングゲート**: 1, 2, 4, 5, 6, 8
**警告ゲート**: 3, 7

### 4. データ品質の抽象化（Adapter-Core分離パターン）

**原則**: 本番データは「汚い」。システム（Core）は「綺麗」に保つ。汚いデータは「玄関」（Adapter）で処理する。

```
┌─────────────────┐
│ External Data   │ ← 本番の「汚い」データ
└────────┬────────┘
         │
┌────────▼────────┐
│  Input Adapter  │ ← 変換・正規化
└────────┬────────┘
         │
   Standard Format  ← Interface/型定義
         │
┌────────▼────────┐
│      Core       │ ← ビジネスロジック
└────────┬────────┘
         │
   Standard Format
         │
┌────────▼────────┐
│ Output Adapter  │ ← 出力変換
└─────────────────┘
```

**メリット**:
- Coreは「汚さ」を知らず、シンプルに保てる
- Adapterは使い捨て可能（クライアント/データソースごと）
- 変換ロジックの変更がCoreに影響しない

**Env Interfaceとの関係**:
| パターン | 抽象化対象 |
|---------|-----------|
| Env Interface | 実行環境（GAS/Local） |
| Adapter-Core | データ品質（汚い/綺麗） |

**詳細**: `.claude/rules/architecture/adapter-core-pattern.md`

## 設計パターン

### Env Interface Pattern（コアパターン）

```typescript
// インターフェース定義
interface IEnv {
  spreadsheet: SpreadsheetService;
  drive: DriveService;
  logger: LoggerService;
  // ...
}

// ローカル実装
class LocalEnv implements IEnv {
  spreadsheet = new MockSpreadsheetService();
  drive = new MockDriveService();
  logger = new MockLogger();
}

// GAS実装
class GasEnv implements IEnv {
  spreadsheet = SpreadsheetApp;
  drive = DriveApp;
  logger = Logger;
}

// ビジネスロジック（環境非依存）
function myBusinessLogic(env: IEnv): void {
  const sheet = env.spreadsheet.getActiveSheet();
  env.logger.log('Success');
}
```

### Factory Pattern（環境生成）

```typescript
class EnvFactory {
  static create(): IEnv {
    if (isGasEnvironment()) {
      return new GasEnv();
    } else {
      return new LocalEnv();
    }
  }
}
```

### Mock Pattern（テスト容易性）

```typescript
class MockSpreadsheetApp {
  private sheets: Map<string, MockSheet> = new Map();

  getActiveSheet(): MockSheet {
    return this.sheets.get('active') || new MockSheet();
  }

  // GAS APIと完全互換のインターフェース
}
```

### Adapter-Core Pattern（データ品質抽象化）

```typescript
// 標準形式（最初に定義）
interface ICustomerData {
  id: string;
  name: string;
  registeredAt: Date;
}

// Input Adapter: 汚いデータ → 標準形式
class SpreadsheetAdapter {
  convert(rawRow: unknown[]): ICustomerData | null {
    if (this.isEmptyRow(rawRow)) return null;
    return {
      id: this.normalizeId(rawRow[0]),      // 全角→半角
      name: this.normalizeName(rawRow[1]),  // トリム
      registeredAt: this.normalizeDate(rawRow[2]) // 複数形式対応
    };
  }
}

// Core: 標準形式のみ受け付ける
class CustomerService {
  getActive(customers: ICustomerData[]): ICustomerData[] {
    // 「汚さ」を一切知らない
    return customers.filter(c => c.status === 'active');
  }
}
```

**開発順序**:
1. 標準形式（Interface）を最初に定義
2. Coreを標準形式前提で開発
3. Adapterは最後に接続

## コード品質基準

### TypeScript設定

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

### ESLint設定

```json
{
  "rules": {
    "no-console": "error",
    "no-debugger": "error",
    "no-unused-vars": "error",
    "prefer-const": "error"
  }
}
```

### テストカバレッジ基準

- **ユニットテスト**: 80%以上必須
- **統合テスト**: 70%以上必須
- **E2Eテスト**: 60%以上必須
- **ブランチカバレッジ**: 75%以上必須

## パフォーマンス基準

### GAS実行時間制限

- **1回の実行**: 最大6分（360秒）
- **推奨**: 2分以内に完了
- **警告閾値**: 4分超過

### メモリ使用量

- **制限**: 100MB（GAS制限）
- **推奨**: 50MB以内
- **警告閾値**: 80MB超過

### API呼び出し最適化

- **バッチ処理**: 可能な限りバッチAPI使用
- **キャッシュ**: 頻繁なアクセスはキャッシュ
- **遅延評価**: 不要な処理は実行しない

## セキュリティ基準

### GAS権限最小化

- **必要最小限の権限のみ要求**
- **ユーザーデータアクセスは明示的に宣言**
- **認証フローは標準OAuth2.0**

### 依存関係管理

- **定期的な依存関係更新**
- **脆弱性スキャン（npm audit / snyk）**
- **ゼロ高/致命的脆弱性維持**

### コード検証

- **インジェクション攻撃対策**
- **入力値検証必須**
- **出力エスケープ必須**

## デプロイ戦略

### 段階的デプロイ

```
ローカルテスト（LocalEnv）
    ↓
ステージング環境（GasEnv - Test Project）
    ↓
カナリアデプロイ（10%ユーザー）
    ↓
本番デプロイ（全ユーザー）
```

### ロールバック戦略

- **即座ロールバック**: 本番エラー発生時
- **バージョン管理**: claspによる自動バージョニング
- **復旧手順**: 自動化スクリプト完備

## 技術的負債管理

### 負債の分類

- **P0（即座対応）**: セキュリティ脆弱性、本番障害
- **P1（1週間以内）**: パフォーマンス劣化、API互換性
- **P2（1ヶ月以内）**: コード品質、ドキュメント
- **P3（四半期内）**: リファクタリング、最適化

### 負債の測定

- **SonarQube**: コード品質スコア
- **ESLint**: リント違反数
- **TypeScript**: 型エラー数
- **テストカバレッジ**: 未カバー率

## イノベーション領域

### 現在検討中

- **AI支援テスト生成**: LLMによるテストケース自動生成
- **自動仕様書同期**: コードから仕様書への逆生成
- **パフォーマンス自動最適化**: ボトルネック自動検出・最適化提案

### 技術調査

- **WebAssembly**: GAS上でのWasm実行可能性
- **GraphQL**: GAS APIのGraphQLラッパー
- **Serverless Framework**: GASデプロイ自動化

## 技術決定記録（ADR）

### ADR-001: Env Interface Pattern採用
- **決定**: IEnv抽象化レイヤーを導入
- **理由**: GAS環境依存を排除し、テスト容易性を確保
- **影響**: 全ビジネスロジックはIEnvに依存

### ADR-002: TypeScript厳格モード必須
- **決定**: strictモードをプロジェクト全体で強制
- **理由**: 型安全性によるランタイムエラー削減
- **影響**: 初期開発コスト増加、長期的品質向上

### ADR-003: 8段階品質ゲート採用
- **決定**: デプロイ前に8つの品質ゲートを通過
- **理由**: デプロイ後手戻り撲滅
- **影響**: デプロイまでの時間増加、本番バグ激減

### ADR-004: Adapter-Core分離パターン採用
- **決定**: 外部データとコアロジックをAdapter層で分離
- **理由**: 本番データの「汚さ」をCoreから隔離し、テスト容易性を確保
- **影響**: 標準形式（Interface）の先行定義が必須、Adapterは使い捨て可

### ADR-005: 変則TDD（本番データ駆動テスト）採用
- **決定**: Adapter層は本番データコピーでテスト、Core層はモックTDD可
- **理由**: モックデータでは本番の「汚さ」を再現できない
- **影響**: 本番データのサンプリング・匿名化プロセスが必要

---

最終更新: 2026-01-03
次回レビュー: 2026-02-01
