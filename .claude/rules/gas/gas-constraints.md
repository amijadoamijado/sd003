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

## GASデプロイルール（厳守）

| コマンド | 許可 | 条件 |
|---------|------|------|
| `clasp push` | 常時許可 | コード反映の標準手段 |
| `clasp deploy` | **ユーザー明示指示のみ** | 新規デプロイメント作成のリスクあり |
| `clasp deploy -i <id>` | **ユーザー明示指示のみ** | 既存デプロイメント更新 |
| `clasp undeploy` | **ユーザー明示指示のみ** | デプロイメント削除 |

### 禁止事項
- **`clasp deploy` を自己判断で実行してはならない**
- 固定URL（`/exec`）の更新が必要でも、まずユーザーに確認する
- 引数なし `clasp deploy` は新規デプロイメントを作成するため特に危険
- `@HEAD`（`/dev`）はpushで自動反映されるため、deployは不要

### 正しいフロー
```
コード修正 → clasp push → @HEAD で動作確認 → OK
                                              ↓ 固定URL更新が必要な場合
                                         ユーザーに確認 → clasp deploy -i <id>
```

## デプロイ前
- 疑似GAS環境で全テスト通過
- 本番環境との差異確認
