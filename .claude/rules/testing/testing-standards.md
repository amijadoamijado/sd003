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

## GASテスト
- LocalEnv使用で疑似GAS環境
- 本番データ相当のテストデータ

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
