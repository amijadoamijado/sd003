# Kiro Spec Tasks

仕様書の実装タスクを生成します。

## 引数
- `$ARGUMENTS`: 対象の仕様書名

## 対象ファイル
`.kiro/specs/{feature}/tasks.md`

## タスク構造
```markdown
# Implementation Tasks

## Task 1: [タスク名]
- **ID**: TASK-001
- **Requirement**: FR-001
- **Description**: [説明]
- **Files**: [対象ファイル]
- **Acceptance Criteria**:
  - [ ] 基準1
  - [ ] 基準2
- **Dependencies**: [依存タスク]
- **Estimated Effort**: S/M/L

## Parallel Analysis
以下のタスクは並列実行可能:
- TASK-001, TASK-002

以下は順次実行が必要:
- TASK-003 → TASK-004
```

## 実行手順
1. 設計を読み込み
2. 実装単位を分割
3. タスクを定義
4. 並列実行可能性を分析
5. 依存関係を明確化

## Task Completion Report Required
```
## Task Completion Report
### Summary
{feature} のタスク生成完了（X件）
### Task Summary
| ID | Name | Effort |
|----|------|--------|
### Parallel Opportunities
[並列実行可能なタスク]
### Next Steps
- [ ] /prompts:kiro-spec-impl {feature}
```
