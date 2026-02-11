# Kiro Spec Requirements

仕様書の要件定義を作成します。

## 引数
- `$ARGUMENTS`: 対象の仕様書名

## 対象ファイル
`.kiro/specs/{feature}/requirements.md`

## 要件構造
```markdown
# Requirements

## Functional Requirements
### FR-001: [要件名]
- Description: [説明]
- Priority: High/Medium/Low
- Acceptance Criteria: [受け入れ基準]

## Non-Functional Requirements
### NFR-001: [要件名]
- Category: Performance/Security/Usability
- Description: [説明]
- Metrics: [測定基準]
```

## 実行手順
1. ユーザーの要求を分析
2. 機能要件を洗い出し
3. 非機能要件を定義
4. ID管理システムに登録

## Task Completion Report Required
```
## Task Completion Report
### Summary
{feature} の要件定義を作成完了
### Changes Made
| File | Action | Description |
|------|--------|-------------|
### Next Steps
- [ ] /prompts:kiro-validate-gap {feature}
- [ ] /prompts:kiro-spec-design {feature}
```
