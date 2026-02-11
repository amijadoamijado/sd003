# Production Mode Workflow

## 発動キーワード
以下を検出したら即座に本番モードへ：
- 「本番」「本番テスト」「本番モード」
- 「プロダクション」「デプロイ前」「最終確認」

## 本番モード行動規範

### ❌ 絶対禁止
- コードの飛ばし読み
- 部分的な確認
- 推測による判断
- 「たぶん大丈夫」
- サンプルデータのみのテスト

### ✅ 必須事項
- 全コードを1行ずつ精読
- 正常系・異常系・エッジケース全テスト
- 本番環境と同じ条件
- 全エラーケース確認
- 8段階品質ゲート全通過

## 品質ゲートチェック

```markdown
## Production Ready Report

### Quality Gate Status
| Gate | Status | Check |
|------|--------|-------|
| 1. Syntax | ✅/❌ | TypeScriptコンパイル |
| 2. Type | ✅/❌ | 型整合性 |
| 3. Lint | ✅/❌ | ESLintエラー0件 |
| 4. Security | ✅/❌ | 脆弱性スキャン |
| 5. Test | ✅/❌ | カバレッジ80%以上 |
| 6. Performance | ✅/❌ | 6分制限確認 |
| 7. Documentation | ✅/❌ | JSDoc完備 |
| 8. Integration | ✅/❌ | E2Eテスト |

### Verification Commands
npm run build
npm test
npm run lint
npm run qa:deploy:safe

### Rollback Plan
[ロールバック手順を記載]
```

## 成功の定義
- **唯一の成功**: 「必ず動く」
- 全テストケースがパス
- 全エラーケースが適切にハンドリング
- 本番環境で確実に動作する保証

## 失敗の定義
上記以外の全て
- 1つでもテストが失敗 → 失敗
- 推測や想定を含む → 失敗
