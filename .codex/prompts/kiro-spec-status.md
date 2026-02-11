# Kiro Spec Status

仕様書の進捗状況を確認します。

## 引数
- `$ARGUMENTS`: 対象の仕様書名

## 確認対象
- `.kiro/specs/{feature}/spec.json`
- `.kiro/specs/{feature}/requirements.md`
- `.kiro/specs/{feature}/design.md`
- `.kiro/specs/{feature}/tasks.md`

## 出力形式
```markdown
# Spec Status: {feature}

## Overview
| Phase | Status |
|-------|--------|
| Requirements | ✅ Complete / 🔄 In Progress / ⏳ Pending |
| Design | ✅ Complete / 🔄 In Progress / ⏳ Pending |
| Tasks | ✅ Complete / 🔄 In Progress / ⏳ Pending |
| Implementation | ✅ Complete / 🔄 In Progress / ⏳ Pending |

## Requirements Summary
- Total: X requirements
- Implemented: Y
- Tested: Z

## Task Progress
| ID | Name | Status |
|----|------|--------|
| TASK-001 | ... | ✅/🔄/⏳ |

## Quality Gates
| Gate | Status |
|------|--------|
| 1-8 | ... |

## Blockers
- [ブロッカーがあれば記載]

## Next Actions
1. [次のアクション]
```

## 実行手順
1. 仕様書ファイルを読み込み
2. 進捗状況を集計
3. ステータスレポート生成
4. 次のアクションを提案
