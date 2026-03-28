# SD002 Framework Rules for Cursor

## プロジェクト概要
SD002は仕様書駆動開発(SD001)とGASモック環境(GA001)を統合したAI駆動型開発フレームワーク。

## 必読ドキュメント
1. `CLAUDE.md` - プロジェクト設定
2. `.sd/specs/` - 仕様書
3. `docs/` - 詳細ドキュメント

## 開発原則

### 仕様書駆動開発
- Requirements → Design → Tasks → Implementation
- 仕様書なしの実装禁止
- `.sd/specs/{feature}/` に仕様書配置

### GAS環境制約
- Node.js API禁止（`fs`, `path`, `process`）
- Env Interface Pattern必須
- 6分実行制限

### 品質基準
- TypeScript strict mode
- テストカバレッジ80%以上
- ESLintエラー0件

## ワークフローコマンド

### Phase 1: Specification
```
/sd:spec-init "description"
/sd:spec-requirements {feature}
/sd:spec-design {feature}
/sd:spec-tasks {feature}
```

### Phase 2: Implementation
```
/sd:spec-impl {feature}
/sd:spec-status {feature}
```

## タスク完了報告

全タスクは以下の形式で報告：

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

## 禁止事項
- 仕様書の無断変更
- テスト省略
- GAS API直接参照
