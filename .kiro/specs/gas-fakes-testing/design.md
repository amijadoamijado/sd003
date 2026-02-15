# gas-fakes Testing Integration 技術設計書

## 基本情報
- **機能名**: gas-fakes Testing Integration
- **バージョン**: 1.0.0
- **ステータス**: 実装中
- **作成日**: 2026-02-15

## 1. アーキテクチャ概要

### 1.1 3層テスト構成

```
Tier-1: GA001 Mock (既存)
  └── tests/unit/, tests/integration/
  └── 高速・低忠実度・GCP認証不要

Tier-2: gas-fakes (新規)
  └── tests/gas-fakes/
  └── 中速・中〜高忠実度・GCP部分必要

Tier-3: Antigravity E2E (既存)
  └── 本番環境テスト
  └── 低速・最高忠実度・GCP認証必須
```

### 1.2 ファイル構成

```
tests/gas-fakes/
├── setup.ts                           # Jest セットアップ
├── spreadsheet.gas-fakes.test.ts     # SpreadsheetApp テスト
├── properties.gas-fakes.test.ts      # PropertiesService テスト
└── drive.gas-fakes.test.ts           # DriveApp テスト
```

## 2. ESM/CJS 互換設計

### 2.1 課題
- gas-fakes: ESM-only パッケージ
- プロジェクト: ts-jest (CJS) を使用

### 2.2 解決策
- setup.ts で動的 import() を使用
- globalThis にGASサービスの存在を確認
- 不在時は describeIfGasFakes でテストを自動スキップ

### 2.3 条件付きテストパターン

```typescript
const describeIfGasFakes = (name: string, fn: () => void) => {
  const hasService = typeof (globalThis as any).ServiceName !== 'undefined';
  if (!hasService) {
    describe.skip(name, fn);
    return;
  }
  describe(name, fn);
};
```

## 3. GCP認証フロー

```
gas-fakes init → .gas-fakes/ 設定ディレクトリ作成
gas-fakes auth → GCPサービスアカウント認証
gas-fakes enable --edrive → DriveApp有効化
gas-fakes enable --espreadsheet → SpreadsheetApp有効化
```

### 3.1 認証不要なサービス
- PropertiesService（ローカルファイルベース）
- CacheService（ローカルファイルベース）

### 3.2 認証必要なサービス
- SpreadsheetApp（GCP Sheets API）
- DriveApp（GCP Drive API）

## 4. Jest設定

### 4.1 package.json 変更

```json
{
  "scripts": {
    "test:gas-fakes": "jest --testPathPattern=tests/gas-fakes/"
  },
  "devDependencies": {
    "@mcpher/gas-fakes": "^1.2.0"
  }
}
```

### 4.2 テスト実行

```bash
npm test                    # 全Tier (Tier-1 + Tier-2)
npm run test:gas-fakes      # Tier-2 のみ
```

---
最終更新: 2026-02-15
