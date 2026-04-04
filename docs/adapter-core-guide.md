# Adapter-Core分離パターン 詳細ガイド

SD003における外部データ統合の設計パターン。

## 背景・動機

### 問題

本番環境のデータは「汚い」：

| 汚さの種類 | 例 |
|-----------|-----|
| 結合セル | セルが結合されている |
| 空白行/列 | 予期しない位置に空白 |
| 全角/半角混在 | `123` と `１２３` |
| 日付形式バラバラ | `2024/1/1`, `2024-01-01`, `R6.1.1` |
| 数値に見える文字列 | `"1234"` (文字列型) |

### 従来の失敗パターン

1. **モックTDD → 本番でコケる**
   - 綺麗なモックデータではテスト通過
   - 汚い本番データで予期しないエラー

2. **Core内でデータクレンジング → Coreが肥大化**
   - `if` 文の嵐
   - ビジネスロジックが見えなくなる

3. **1クライアント対応 → 別クライアントで全面改修**
   - データ形式の違いがCore全体に波及

### 解決策

「玄関」（Adapter）で汚さを吸収し、Coreを綺麗に保つ。

---

## アーキテクチャ図

```
       ┌─────────────────┐
       │ External Data   │ ← 本番の「汚い」データ
       │ (Spreadsheet等) │
       └────────┬────────┘
                │
       ┌────────▼────────┐
       │  Input Adapter  │ ← 変換・正規化・検証
       │  (使い捨て可)   │
       └────────┬────────┘
                │
         Standard Format  ← Interface/型定義
                │
       ┌────────▼────────┐
       │      Core       │ ← ビジネスロジック
       │  (綺麗な世界)   │    標準形式のみ知る
       └────────┬────────┘
                │
         Standard Format
                │
       ┌────────▼────────┐
       │ Output Adapter  │ ← 出力変換
       │  (出力先別)     │
       └────────┬────────┘
                │
       ┌────────▼────────┐
       │ External System │ ← 各システム向け出力
       └─────────────────┘
```

---

## 実装パターン

### 1. 標準形式の定義（最初に行う）

```typescript
// src/interfaces/standard-formats.ts

/**
 * 顧客データの標準形式
 * すべてのAdapter/Coreはこの形式を介してやり取りする
 */
export interface ICustomerData {
  id: string;
  name: string;
  email: string;
  registeredAt: Date;
  status: 'active' | 'inactive' | 'pending';
}
```

**ポイント**：
- 型を厳密に定義
- Core/Adapterの「契約」となる
- 変更コストが最も高いため慎重に設計

### 2. Input Adapter

```typescript
// src/adapters/input/spreadsheet-customer-adapter.ts

import { ICustomerData } from '../../interfaces/standard-formats';

/**
 * スプレッドシートからの顧客データAdapter
 *
 * 本番データの「汚さ」をここで吸収:
 * - 全角→半角変換
 * - 日付正規化
 * - 空行スキップ
 */
export class SpreadsheetCustomerAdapter {

  convert(rawRow: unknown[]): ICustomerData | null {
    // 空行スキップ
    if (this.isEmptyRow(rawRow)) return null;

    return {
      id: this.normalizeId(rawRow[0]),
      name: this.normalizeName(rawRow[1]),
      email: this.normalizeEmail(rawRow[2]),
      registeredAt: this.normalizeDate(rawRow[3]),
      status: this.normalizeStatus(rawRow[4]),
    };
  }

  private normalizeId(value: unknown): string {
    // 全角→半角、トリム
    return String(value)
      .replace(/[０-９]/g, s =>
        String.fromCharCode(s.charCodeAt(0) - 0xFEE0)
      )
      .trim();
  }

  private normalizeDate(value: unknown): Date {
    // 複数形式対応: 2024/1/1, 2024-01-01, R6.1.1
    const str = String(value);
    // ... 実装
    return new Date();
  }

  private isEmptyRow(row: unknown[]): boolean {
    return row.every(cell => cell === '' || cell === null);
  }
}
```

**ポイント**：
- Coreは「汚さ」を一切知らない
- 変換ロジックはAdapterに閉じ込める
- Adapterは使い捨て可（クライアントごとに作成）

### 3. Core（ビジネスロジック）

```typescript
// src/core/customer-service.ts

import { ICustomerData } from '../interfaces/standard-formats';
import { IEnv } from '../interfaces/IEnv';

/**
 * 顧客サービス（Core）
 *
 * 標準形式のみを受け取る。
 * 本番データの「汚さ」を一切知らない。
 */
export class CustomerService {

  constructor(private readonly env: IEnv) {}

  getActiveCustomers(customers: ICustomerData[]): ICustomerData[] {
    return customers.filter(c => c.status === 'active');
  }

  sortByRegistration(customers: ICustomerData[]): ICustomerData[] {
    return [...customers].sort(
      (a, b) => a.registeredAt.getTime() - b.registeredAt.getTime()
    );
  }
}
```

**ポイント**：
- 入力は必ず`ICustomerData`型
- `if (typeof value === 'string')` のような型判定は不要
- ビジネスロジックに集中できる

### 4. 統合（エントリーポイント）

```typescript
// src/main.ts

import { SpreadsheetCustomerAdapter } from './adapters/input/spreadsheet-customer-adapter';
import { CustomerService } from './core/customer-service';
import { ICustomerData } from './interfaces/standard-formats';

export function processCustomerData(env: IEnv): void {
  const sheet = env.spreadsheet.getActiveSheet();
  const rawData = sheet.getDataRange().getValues();

  // Input Adapter: 汚い→綺麗
  const adapter = new SpreadsheetCustomerAdapter();
  const customers = rawData
    .map(row => adapter.convert(row))
    .filter((c): c is ICustomerData => c !== null);

  // Core: 綺麗な世界でのビジネスロジック
  const service = new CustomerService(env);
  const activeCustomers = service.getActiveCustomers(customers);
  const sorted = service.sortByRegistration(activeCustomers);

  // Output...
}
```

---

## 変則TDD（本番データ駆動テスト）

### Adapter層のテスト

```typescript
// tests/adapters/spreadsheet-customer-adapter.test.ts

describe('SpreadsheetCustomerAdapter', () => {
  let adapter: SpreadsheetCustomerAdapter;

  beforeEach(() => {
    adapter = new SpreadsheetCustomerAdapter();
  });

  describe('本番データ形式の変換', () => {
    // 本番からコピーした実データを使用
    it('should normalize full-width numbers', () => {
      const rawRow = ['００１', '山田太郎', 'test@example.com', '2024/1/1', 'active'];
      const result = adapter.convert(rawRow);
      expect(result?.id).toBe('001');
    });

    it('should handle Japanese era dates', () => {
      const rawRow = ['001', '山田太郎', 'test@example.com', 'R6.1.1', 'active'];
      const result = adapter.convert(rawRow);
      expect(result?.registeredAt).toEqual(new Date(2024, 0, 1));
    });

    it('should skip empty rows', () => {
      const rawRow = ['', '', '', '', ''];
      const result = adapter.convert(rawRow);
      expect(result).toBeNull();
    });
  });
});
```

### Core層のテスト（従来TDD）

```typescript
// tests/core/customer-service.test.ts

describe('CustomerService', () => {
  // 標準形式のモックデータでテスト可能
  const mockCustomers: ICustomerData[] = [
    {
      id: '001',
      name: 'A',
      email: 'a@test.com',
      registeredAt: new Date(2024, 0, 1),
      status: 'active'
    },
    {
      id: '002',
      name: 'B',
      email: 'b@test.com',
      registeredAt: new Date(2024, 0, 2),
      status: 'inactive'
    },
  ];

  it('should filter active customers', () => {
    const service = new CustomerService(mockEnv);
    const result = service.getActiveCustomers(mockCustomers);
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('001');
  });
});
```

---

## 開発順序（推奨）

| 順序 | 作業 | 理由 |
|------|------|------|
| 1 | 標準形式（Interface）定義 | Core/Adapterの契約を先に確立 |
| 2 | Coreを標準形式前提で開発 | TDDで綺麗に開発可能 |
| 3 | Adapterを最後に接続 | 本番データを見てから実装 |

**なぜこの順序か**：
- 標準形式の変更コストが最も高い
- Coreはビジネスロジックに集中できる
- Adapterは使い捨て可なので気軽に作成

---

## Env Interface Patternとの併用

```typescript
export function processData(env: IEnv): void {
  // Env Interface: 環境抽象化
  const sheet = env.spreadsheet.getActiveSheet();

  // Adapter-Core: データ抽象化
  const adapter = new SpreadsheetAdapter();
  const core = new BusinessCore(env);

  const rawData = sheet.getValues();
  const cleanData = adapter.convert(rawData);
  core.process(cleanData);
}
```

| パターン | 抽象化対象 |
|---------|-----------|
| Env Interface | 実行環境（GAS/Local） |
| Adapter-Core | データ品質（汚い/綺麗） |

---

## 関連ドキュメント

- [Env Interface Pattern](../.claude/rules/gas/env-interface.md)
- [テスト基準](../.claude/rules/testing/testing-standards.md)
- [変則TDD](../.claude/rules/testing/production-data-tdd.md)
- [GAS開発ガイド](gas-development-guide.md)
