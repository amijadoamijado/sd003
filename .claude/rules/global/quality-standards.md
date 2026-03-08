---
description: SD003フレームワーク品質基準（全ファイル適用）
---

# 品質基準

## TypeScript
- strict mode必須
- ESLintエラー0件
- 型安全性確保

## テスト
- カバレッジ80%以上
- ユニット/統合/E2E全層
- **テストの唯一の目的は本番エラーの発見と修正**（詳細: `.claude/rules/testing/testing-standards.md`）
- テストデータ品質の自動検証: `npm run test:validate-data`（VTD-001〜005）

## コード品質
- JSDoc: 公開API必須
- 命名: PascalCase(class), camelCase(func), UPPER_SNAKE(const)
- エラーハンドリング: 全ケース処理

## 禁止事項
- `any`型使用
- `console.log`（Logger経由のみ）
- マジックナンバー
- 深いネスト（3階層以上）
- **テストのためのテスト**（本番エラー発見以外の全目的を禁止）
  - モックデータ・ダミーデータ・空データでの検証は禁止
  - フォールバック付きテスト（失敗時にスキップ/デフォルト値で通過）は禁止
  - カバレッジ数値のためだけのテストは禁止
  - 80%未達でもエラーを発見できるテストを優先
  - 詳細: `.claude/rules/testing/testing-standards.md`
- **フロントエンドをユーザーに見せずに次に進む**
  - UI実装後は必ずユーザーに画面を見せて確認を取る
  - ユーザー確認なしでバックエンド統合やデプロイに進むことは禁止
  - 「動くはず」ではなく「実際に見せて確認」が必須

## 品質ゲート
8段階ゲート全通過必須（詳細: docs/quality-gates.md）
