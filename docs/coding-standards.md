# コーディング規約

SD003フレームワークにおけるコーディング規約と品質基準。

## コード品質基準

### 必須事項
- **TypeScript厳格モード**: すべてのコードで必須
- **ESLintエラー0件**: リント違反は許容しない
- **適切なエラーハンドリング**: すべてのエラーケースを処理
- **JSDocコメント**: 公開API全てに必須

## 命名規則

| 種類 | 規則 | 例 |
|-----|------|-----|
| クラス | PascalCase | `MockSpreadsheetApp` |
| ファイル | kebab-case | `spreadsheet-app.mock.ts` |
| インターフェース | `I`プレフィックス or `Type`サフィックス | `IEnv`, `ConfigType` |
| 定数 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 関数 | camelCase | `processData` |
| 変数 | camelCase | `userData` |
| プライベート | `_`プレフィックス | `_internalState` |

## ファイル構造

### ソースファイル
```typescript
// 1. Imports (グループ化)
import { External } from 'external-lib';    // 外部ライブラリ
import { Internal } from '../internal';      // 内部モジュール
import { Types } from './types';             // ローカル

// 2. Types/Interfaces
interface IConfig {
  // ...
}

// 3. Constants
const DEFAULT_CONFIG: IConfig = {
  // ...
};

// 4. Main exports
export class MyClass {
  // ...
}

// 5. Helper functions (private)
function helperFunction(): void {
  // ...
}
```

### テストファイル
```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { MyClass } from './my-class';

describe('MyClass', () => {
  let instance: MyClass;

  beforeEach(() => {
    instance = new MyClass();
  });

  describe('methodName', () => {
    it('should do something when condition', () => {
      // Arrange
      const input = 'test';

      // Act
      const result = instance.methodName(input);

      // Assert
      expect(result).toBe('expected');
    });
  });
});
```

## JSDoc規約

### 関数
```typescript
/**
 * データを処理して結果を返す
 *
 * @param env - 環境インターフェース
 * @param data - 処理対象データ
 * @returns 処理結果
 * @throws {ValidationError} データが不正な場合
 *
 * @example
 * ```typescript
 * const result = processData(env, ['item1', 'item2']);
 * ```
 */
export function processData(env: IEnv, data: string[]): ProcessResult {
  // ...
}
```

### クラス
```typescript
/**
 * スプレッドシート操作のモッククラス
 *
 * @description
 * GAS SpreadsheetAppのローカル実行用モック。
 * 本番環境と同一のインターフェースを提供。
 *
 * @example
 * ```typescript
 * const mock = new MockSpreadsheetApp();
 * const sheet = mock.getActiveSheet();
 * ```
 */
export class MockSpreadsheetApp implements ISpreadsheetApp {
  // ...
}
```

## エラーハンドリング

### カスタムエラー
```typescript
export class ValidationError extends Error {
  constructor(
    message: string,
    public readonly field: string,
    public readonly value: unknown
  ) {
    super(message);
    this.name = 'ValidationError';
  }
}
```

### エラー処理パターン
```typescript
try {
  const result = await riskyOperation();
  return result;
} catch (error) {
  if (error instanceof ValidationError) {
    logger.warn(`Validation failed: ${error.field}`);
    throw error;
  }
  logger.error('Unexpected error', error);
  throw new Error('Operation failed');
}
```

## 禁止事項

### コード
- ❌ `any` 型の使用（やむを得ない場合は `unknown` を使用）
- ❌ `console.log` の使用（Logger経由のみ）
- ❌ マジックナンバー（定数化必須）
- ❌ 深いネスト（3階層以上は早期リターン）

### GAS固有
- ❌ GAS API直接参照（Env経由のみ）
- ❌ Node.js専用API（`fs`, `path`, `process`）
- ❌ ES6モジュール構文（ビルド前）
- ❌ グローバルスコープ汚染

## 推奨パターン

### 早期リターン
```typescript
// ❌ Bad
function process(data: Data | null): Result {
  if (data) {
    if (data.isValid) {
      return doProcess(data);
    }
  }
  return defaultResult;
}

// ✅ Good
function process(data: Data | null): Result {
  if (!data) return defaultResult;
  if (!data.isValid) return defaultResult;
  return doProcess(data);
}
```

### 純粋関数
```typescript
// ❌ Bad - 副作用あり
function addItem(list: string[], item: string): void {
  list.push(item);
}

// ✅ Good - 純粋関数
function addItem(list: string[], item: string): string[] {
  return [...list, item];
}
```

## 関連ドキュメント
- [GAS開発ガイド](gas-development-guide.md)
- [品質ゲート](quality-gates.md)
