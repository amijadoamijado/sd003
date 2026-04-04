# GAS開発ガイド

SD003フレームワークにおけるGoogle Apps Script (GAS)開発の原則と制約。

## 基本原則

### 原則1: GAS環境を常に意識した開発
すべての開発は**Google Apps Script (GAS)環境での動作**を前提とします。
- ローカル開発 = GAS本番環境の疑似実行環境
- 全てのコードはGASにデプロイされることを想定
- Node.js専用機能の使用は厳禁

### 原則2: デプロイ前バグ撲滅
**デプロイ前に想定されるバグを100%修正する**ことを目標とします。
- 疑似GAS環境での徹底的なテスト
- 本番環境との差異を極限まで縮小
- デプロイ後の手戻りコストは開発コストの10倍以上

### 原則3: 手戻り防止戦略
**デプロイ後の手戻りを極限まで減少させる**ための戦略：
- ローカル環境でGAS環境を完全再現
- 本番デプロイ前に8段階品質ゲートを通過
- E2Eテストで実際のユースケースを網羅

### 原則4: 疑似GAS環境の精度向上
**疑似GAS環境をGAS本番環境と同じ状態にする**ことでテスト精度を最大化：
- LocalEnvとGasEnvの完全な動作互換性
- GAS API仕様との100%一致
- 実際のSpreadsheet/Drive/Gmail等のモック完備

## GAS環境制約

### 使用禁止API
| API | 理由 |
|-----|------|
| `fs` | Node.js専用 |
| `path` | Node.js専用 |
| `process` | Node.js専用 |
| `require()` (dynamic) | GAS非対応 |

### モジュール制限
- **ES6モジュール制限**: GASはCommonJS形式のみサポート
- `import/export` 構文は使用不可（ビルド時に変換必要）

### 実行制限
- **実行時間**: 最大6分（スクリプト実行）
- **メモリ**: 制限あり（大量データ処理に注意）
- **API呼び出し**: レート制限あり

### グローバルスコープ
- GASグローバルスコープを汚染しない
- 必要なグローバル関数のみエクスポート

## Env Interface Pattern

ビジネスロジックをGAS APIから分離するパターン。

### 基本構造
```typescript
// インターフェース定義
interface IEnv {
  spreadsheet: ISpreadsheetService;
  logger: ILoggerService;
  // ... 他のサービス
}

// ビジネスロジックはIEnvのみに依存
export function processData(env: IEnv, data: string[]): void {
  const sheet = env.spreadsheet.getActiveSheet();
  const logger = env.logger;
  // GAS API直接参照は禁止
}
```

### 環境切り替え
```typescript
// ローカル環境（テスト用）
const localEnv = new LocalEnv();
processData(localEnv, testData);

// GAS環境（本番用）
const gasEnv = new GasEnv();
processData(gasEnv, realData);
```

### メリット
1. **テスタビリティ**: ローカルで完全なテストが可能
2. **保守性**: 環境差異を1箇所で吸収
3. **信頼性**: 本番環境と同じコードパスをテスト

## 疑似GAS環境

### LocalEnvの実装方針
- GAS APIと100%互換のインターフェース
- 実際のSpreadsheet操作をメモリ上で再現
- エラー挙動もGASと同一に

### モック対象サービス
| サービス | モッククラス |
|---------|------------|
| SpreadsheetApp | MockSpreadsheetApp |
| DriveApp | MockDriveApp |
| GmailApp | MockGmailApp |
| Logger | MockLogger |
| UrlFetchApp | MockUrlFetchApp |
| PropertiesService | MockPropertiesService |

## 関連ドキュメント
- [品質ゲート](quality-gates.md)
- [デプロイ戦略](deployment-strategy.md)
- [コーディング規約](coding-standards.md)
