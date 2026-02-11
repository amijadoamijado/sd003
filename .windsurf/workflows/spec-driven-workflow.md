# SD002 Spec-Driven Workflow for Windsurf

## プロジェクト概要
SD002は仕様書駆動開発(SD001)とGASモック環境(GA001)を統合したAI駆動型開発フレームワーク。

## ワークフロー構造

### Phase 0: Steering（任意）
プロジェクト戦略ドキュメントの作成・更新
- `.kiro/steering/product.md`
- `.kiro/steering/tech.md`
- `.kiro/steering/structure.md`

### Phase 1: Specification

#### Step 1: 仕様書初期化
```
/prompts:kiro-spec-init "feature description"
```
作成: `.kiro/specs/{feature}/`

#### Step 2: 要件定義
```
/prompts:kiro-spec-requirements {feature}
```
更新: `requirements.md`

#### Step 3: ギャップ分析
```
/prompts:kiro-validate-gap {feature}
```
既存コードとのギャップ確認

#### Step 4: 技術設計
```
/prompts:kiro-spec-design {feature}
```
更新: `design.md`

#### Step 5: 設計検証
```
/prompts:kiro-validate-design {feature}
```
設計品質・GAS互換性確認

#### Step 6: タスク生成
```
/prompts:kiro-spec-tasks {feature}
```
更新: `tasks.md`

### Phase 2: Implementation

#### Step 7: 実装
```
/prompts:kiro-spec-impl {feature} [tasks]
```
TDD推奨、品質基準遵守

#### Step 8: 実装検証
```
/prompts:kiro-validate-impl {feature}
```
8段階品質ゲート通過確認

### Progress Check
```
/prompts:kiro-spec-status {feature}
```

## 品質基準
- TypeScript strict mode
- テストカバレッジ80%以上
- ESLintエラー0件
- 8段階品質ゲート全通過

## GAS制約
- Node.js API禁止
- Env Interface Pattern必須
- 6分実行制限

## タスク完了報告（必須）
```markdown
## Task Completion Report
### Summary
[完了内容]
### Changes Made
| File | Action | Description |
### Verification
npm test && npm run lint
### Next Steps
- [ ] 次のアクション
```
