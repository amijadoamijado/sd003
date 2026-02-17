---
description: テスト基準（tests/配下適用）
paths:
  - "tests/**/*"
  - "**/*.test.ts"
  - "**/*.spec.ts"
---

# テスト基準

## カバレッジ要件
- ユニット: 80%以上
- 統合: 70%以上
- E2E: 主要フロー100%

## テスト構造
```typescript
describe('対象', () => {
  beforeEach(() => { /* セットアップ */ });

  describe('メソッド', () => {
    it('should 期待動作 when 条件', () => {
      // Arrange → Act → Assert
    });
  });
});
```

## 必須テストケース
- 正常系: 標準入力
- 異常系: エラーケース
- エッジ: 境界値、null/undefined

## GASテスト - 3層テスト戦略

| Tier | ツール | ディレクトリ | 速度 | 忠実度 | GCP認証 |
|------|--------|------------|------|--------|---------|
| Tier-1 | ローカルモック（GA001依存なし） | `tests/unit/`, `tests/integration/` | < 1s | 低 | 不要 |
| Tier-2 | @mcpher/gas-fakes | `tests/gas-fakes/` | < 30s | 中-高 | 一部必要 |
| Tier-3 | Antigravity E2E | 本番環境 | 分単位 | 最高 | 必要 |

### Tier-1: ローカルモック（ユニット）
- `tests/setup/gas-globals.ts` のローカルモックで疑似GAS環境
- GA001フレームワーク非依存（段階的排除方針）
- Core ビジネスロジックの高速検証

### Tier-2: gas-fakes（統合）
- `@mcpher/gas-fakes` による高忠実度GAS APIエミュレーション
- PropertiesService/CacheService はローカルファイルで動作（GCP不要）
- SpreadsheetApp/DriveApp は GCP認証が必要
- 実行: `npm run test:gas-fakes`
- gas-fakesセットアップ: `gas-fakes init && gas-fakes auth`

### Tier-3: Antigravity E2E（本番）
- 本番/ステージング環境でのUI確認
- `/workflow:test` で TEST_REQUEST を作成
- Antigravity がブラウザベースで実行

### Tier選択基準
| テスト対象 | 推奨Tier |
|-----------|---------|
| Core ビジネスロジック | Tier-1 |
| GAS API統合（Properties, Cache） | Tier-2 |
| GAS API統合（Sheets, Drive） | Tier-2（GCP認証時）/ Tier-3 |
| UI・フロー確認 | Tier-3 |

## ⛔ 禁止事項（最重要）

**カバレッジのためだけの無意味なテスト作成は禁止**

| 禁止 | 理由 |
|------|------|
| 「こう動くはず」と仮定したテスト | 実際の動作を確認していない |
| 数値達成のためだけのテスト | 品質向上に寄与しない |
| 実装を読まずに書くテスト | バグを検出できない |

### 正しいテストの基準
- 実際の動作を確認した上で期待値を設定
- 80%未達でも意味のあるテストを優先
- テストは機能検証が目的、数値達成が目的ではない

### 違反例
```typescript
// ❌ NG: 「多分こう動く」で書いたテスト
it('should return formatted date', () => {
  expect(formatDate(new Date())).toBe('2026-01-01'); // 実際の動作未確認
});

// ✅ OK: 実際の動作を確認して書いたテスト
it('should return formatted date', () => {
  const result = formatDate(new Date('2026-01-15'));
  expect(result).toBe('2026-01-15'); // 実際に動かして確認済み
});
```
