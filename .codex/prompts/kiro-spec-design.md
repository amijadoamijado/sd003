# Kiro Spec Design

仕様書の技術設計を作成します。

## 引数
- `$ARGUMENTS`: 対象の仕様書名

## 対象ファイル
`.kiro/specs/{feature}/design.md`

## 設計構造
```markdown
# Technical Design

## Architecture Overview
[アーキテクチャ図・説明]

## Component Design
### Component: [名前]
- Responsibility: [責務]
- Interface: [インターフェース]
- Dependencies: [依存関係]

## Data Model
[データモデル定義]

## API Design
[API仕様]

## Error Handling
[エラーハンドリング戦略]
```

## 実行手順
1. 要件を読み込み
2. アーキテクチャを設計
3. コンポーネントを定義
4. インターフェースを設計
5. 要件とのトレーサビリティを確保

## Task Completion Report Required
```
## Task Completion Report
### Summary
{feature} の技術設計を作成完了
### Changes Made
| File | Action | Description |
|------|--------|-------------|
### Next Steps
- [ ] /prompts:kiro-validate-design {feature}
- [ ] /prompts:kiro-spec-tasks {feature}
```
