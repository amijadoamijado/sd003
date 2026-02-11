# Kiro Spec Implementation

仕様書に基づいて実装を行います。

## 引数
- `$ARGUMENTS`: 対象の仕様書名 [タスクID...]

## 参照ファイル
- `.kiro/specs/{feature}/requirements.md`
- `.kiro/specs/{feature}/design.md`
- `.kiro/specs/{feature}/tasks.md`

## 実装ルール

### GAS制約遵守
- Node.js API禁止（fs, path, process）
- Env Interface Pattern必須
- 6分実行制限考慮

### 品質基準
- TypeScript strict mode
- ESLint エラー0件
- テストカバレッジ80%以上

### TDD推奨
1. テスト作成
2. 実装
3. リファクタリング

## 実行手順
1. 対象タスクを確認
2. テストを先に作成
3. 実装を行う
4. リント・型チェック
5. テスト実行

## Task Completion Report Required (CRITICAL)
```
## Implementation Complete

### Summary
Implemented [feature] - [task description]

### Changes
| File | Action | Lines |
|------|--------|-------|
| src/xxx.ts | Created | +150 |
| tests/xxx.test.ts | Created | +80 |

### Test Results
All tests passing. Coverage: XX%

### Verification Commands
npm test
npm run lint

### Next Steps
- [ ] 次のタスク
```
