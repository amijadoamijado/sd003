---
description: GAS環境制約（src/配下のTypeScriptファイル適用）
paths:
  - "src/**/*.ts"
  - "src/**/*.tsx"
---

# GAS環境制約

## 禁止API
- `fs`, `path`, `process`（Node.js専用）
- ES6 modules（ビルド前）
- グローバルスコープ汚染

## 制限事項
- 実行時間: 6分以内
- CommonJS形式のみ
- 非同期処理: GAS制限を理解

## 必須パターン
- GAS API → Env Interface経由のみ
- ビジネスロジック → GAS非依存

## デプロイ前
- 疑似GAS環境で全テスト通過
- 本番環境との差異確認
