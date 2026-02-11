---
description: Env Interface Pattern（環境抽象化レイヤー適用）
paths:
  - "src/env/**/*"
  - "src/interfaces/**/*"
---

# Env Interface Pattern

## 原則
ビジネスロジックはIEnvのみに依存。GAS API直接参照禁止。

## 実装パターン
```typescript
// ビジネスロジック
export function processData(env: IEnv, data: string[]): void {
  const sheet = env.spreadsheet.getActiveSheet();
  const logger = env.logger;
}

// 環境切り替え
const localEnv = new LocalEnv();  // テスト
const gasEnv = new GasEnv();      // 本番
```

## 互換性保証
- LocalEnv = GasEnv 100%互換
- 同一コードが両環境で動作

## テスト戦略
- LocalEnvで疑似GAS環境テスト
- デプロイ前に全ケース検証
