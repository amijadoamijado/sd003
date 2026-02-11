# Kiro Validate Implementation

実装の品質を検証します。

## 引数
- `$ARGUMENTS`: 対象の仕様書名

## 検証対象
- `.kiro/specs/{feature}/` 全ファイル
- 関連する `src/` ファイル
- 関連する `tests/` ファイル

## 検証項目

### 8段階品質ゲート
| Gate | Check |
|------|-------|
| 1. Syntax | TypeScriptコンパイル |
| 2. Type | 型整合性 |
| 3. Lint | ESLintエラー0件 |
| 4. Security | 脆弱性スキャン |
| 5. Test | カバレッジ80%以上 |
| 6. Performance | 6分制限確認 |
| 7. Documentation | JSDoc完備 |
| 8. Integration | E2Eテスト |

### 要件トレーサビリティ
- 全要件が実装されているか
- テストでカバーされているか

## 実行手順
1. 品質ゲートを順次実行
2. 要件カバレッジを確認
3. 問題点をリスト化
4. レポート生成

## Task Completion Report Required
```
## Validation Complete

### Quality Gate Status
| Gate | Status |
|------|--------|
| 1. Syntax | ✅/❌ |
| 2. Type | ✅/❌ |
| ... | ... |

### Requirement Coverage
- Covered: X/Y (XX%)

### Issues Found
- [問題があれば記載]

### Next Steps
- [ ] 問題修正 or デプロイ準備
```
