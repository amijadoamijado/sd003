# Kiro Validate Design

技術設計の品質を検証します。

## 引数
- `$ARGUMENTS`: 対象の仕様書名

## 検証対象
- `.kiro/specs/{feature}/requirements.md`
- `.kiro/specs/{feature}/design.md`

## 検証項目
```markdown
# Design Validation Report

## Requirement Coverage
| Requirement ID | Design Component | Status |
|----------------|------------------|--------|

## Architecture Quality
- [ ] 単一責任原則
- [ ] 依存関係の方向性
- [ ] インターフェース分離

## GAS Compatibility
- [ ] Node.js API未使用
- [ ] Env Interface Pattern適用
- [ ] 6分制限考慮

## Testability
- [ ] モック可能性
- [ ] 依存性注入
- [ ] 境界の明確さ
```

## 実行手順
1. 要件と設計を読み込み
2. カバレッジを検証
3. 設計品質をチェック
4. GAS互換性を確認
5. レポート生成

## Task Completion Report Required
```
## Task Completion Report
### Summary
{feature} の設計検証完了
### Validation Results
| Check | Status |
|-------|--------|
### Issues Found
- [問題点があれば記載]
### Next Steps
- [ ] 問題修正 or タスク作成
```
