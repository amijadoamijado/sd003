# Kiro Validate Gap

要件と既存実装のギャップを分析します。

## 引数
- `$ARGUMENTS`: 対象の仕様書名

## 分析対象
- `.kiro/specs/{feature}/requirements.md`
- 既存のソースコード (`src/`)
- 既存のテスト (`tests/`)

## 出力形式
```markdown
# Gap Analysis Report

## Covered Requirements
| ID | Requirement | Coverage |
|----|-------------|----------|

## Gaps Identified
| ID | Requirement | Missing Implementation |
|----|-------------|----------------------|

## Recommendations
1. [推奨事項]
```

## 実行手順
1. 要件を読み込み
2. 既存コードベースをスキャン
3. カバー率を算出
4. ギャップを特定
5. レポート生成

## Task Completion Report Required
```
## Task Completion Report
### Summary
{feature} のギャップ分析完了
### Gap Summary
- Covered: X requirements
- Gaps: Y requirements
### Next Steps
- [ ] ギャップ対応の設計
```
