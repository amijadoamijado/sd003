# Codexレビュー運用ガイド

## 概要

CodexはSD002プロジェクトにおいてレビュー・チェックを担当します。
カスタムスラッシュコマンドは `/prompts:*` 形式で利用します。

### コマンド運用

- 一覧表示: `/prompts`
- 例: `/prompts:workflow-review {projectID} {num}`
- 例: `/prompts:kiro-spec-init "description"`

## 対応するレビュー種別

| 種別 | 入力 | 出力 |
|------|------|------|
| 発注書レビュー | WORK_ORDER.md | REVIEW_WORK_ORDER.md |
| 実装レビュー | commit + 仕様書 | REVIEW_IMPL_XXX.md |

---

## 1. 発注書レビュー

### 1.1 入力ファイル
```
.kiro/ai-coordination/workflow/spec/{案件ID}/WORK_ORDER.md
```

### 1.2 レビュー観点
1. **目的の明確性**: ビジネス目的が具体的か
2. **成功条件の数値化**: 測定可能な指標があるか
3. **スコープの明確性**: やること/やらないことが明確か
4. **業務ルールの完全性**: 必要なルールが網羅されているか
5. **データ定義の正確性**: 入出力、型、バリデーションが定義されているか
6. **例外処理の網羅性**: エラーケースが考慮されているか
7. **テスト要件の妥当性**: テストケースが十分か
8. **リスク分析の妥当性**: リスクと回避策が適切か

### 1.3 出力ファイル
```
.kiro/ai-coordination/workflow/review/{案件ID}/REVIEW_WORK_ORDER.md
```

### 1.4 判定基準
| 判定 | 条件 |
|------|------|
| Approve | 全観点で問題なし |
| Request Changes | 修正が必要な箇所あり |
| Reject | 根本的な見直しが必要 |

### 1.5 レビュー手順

```bash
# 1. 発注書を読み込む
# ファイル: .kiro/ai-coordination/workflow/spec/{案件ID}/WORK_ORDER.md

# 2. 各観点をチェック

# 3. レビュー結果を作成
# テンプレート: .kiro/ai-coordination/workflow/templates/REVIEW_REPORT.md

# 4. 結果を保存
# 保存先: .kiro/ai-coordination/workflow/review/{案件ID}/REVIEW_WORK_ORDER.md
```

---

## 2. 実装レビュー

### 2.1 入力ファイル
```
対象コミット: git log / git diff で確認
発注書: .kiro/ai-coordination/workflow/spec/{案件ID}/WORK_ORDER.md
実装指示: .kiro/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{タスク番号}.md
```

### 2.2 レビュー準備コマンド
```bash
# 変更内容確認
git log -1 --stat
git diff HEAD~1

# テスト実行
npm test
npm run lint
npm run build
npx tsc --noEmit
```

### 2.3 レビュー観点（6項目）

#### 2.3.1 仕様適合性
- 発注書の要件を満たしているか
- 実装指示の範囲内か
- スコープ逸脱がないか

#### 2.3.2 異常系処理
- エラーハンドリングが適切か
- バリデーションが実装されているか
- エッジケースが考慮されているか

#### 2.3.3 データ整合性
- 型安全性が確保されているか
- データフローが正しいか
- 状態管理が適切か

#### 2.3.4 セキュリティ
- 入力検証が十分か
- 機密情報の漏洩リスクがないか
- アクセス制御が適切か

#### 2.3.5 ログ・監査
- 必要なログが出力されているか
- トレーサビリティが確保されているか
- デバッグに必要な情報があるか

#### 2.3.6 テスト
- テストカバレッジが80%以上か
- テストケースが網羅的か
- テストの品質が十分か

### 2.4 出力ファイル
```
.kiro/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{タスク番号}.md
```

### 2.5 判定基準
| 判定 | 条件 |
|------|------|
| Approve | Must指摘0件、全観点Pass |
| Request Changes | Must指摘あり、または重要観点Fail |
| Reject | 設計根本問題、または発注書との重大な乖離 |

---

## 3. レビュー完了後の連絡

### 3.1 Approve時
```markdown
## レビュー完了: Approve

- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **レビュー結果**: .kiro/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{タスク番号}.md
- **次のアクション**: Claude Codeによる工程更新
```

### 3.2 Request Changes時
```markdown
## レビュー完了: Request Changes

- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **Must指摘**: X件
- **Should指摘**: X件
- **レビュー結果**: .kiro/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{タスク番号}.md
- **次のアクション**: Gemini CLIによる修正対応
```

### 3.3 Reject時
```markdown
## レビュー完了: Reject

- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **却下理由**: {理由}
- **レビュー結果**: .kiro/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{タスク番号}.md
- **次のアクション**: Claude Codeによる発注書/実装指示の見直し
```

---

## 4. チェックリスト

### 4.1 発注書レビュー前
- [ ] WORK_ORDER.md を全文読んだ
- [ ] 関連する既存仕様書を確認した
- [ ] 業務ルールの妥当性を検討した

### 4.2 実装レビュー前
- [ ] git diff で変更内容を確認した
- [ ] npm test を実行した
- [ ] npm run lint を実行した
- [ ] npm run build を実行した
- [ ] 発注書の要件を再確認した
- [ ] 実装指示の範囲を再確認した

### 4.3 レビュー結果作成時
- [ ] 全観点を評価した
- [ ] Must/Should/Could を正しく分類した
- [ ] 修正案を具体的に記載した
- [ ] 再レビュー条件を明確にした

---

## 5. トラブルシューティング

### Q: テストが失敗する場合
1. エラーメッセージを確認
2. 失敗したテストケースを特定
3. Must指摘として報告

### Q: ビルドエラーの場合
1. TypeScriptエラーを確認
2. 型の不整合を特定
3. Must指摘として報告

### Q: 判断に迷う場合
1. 発注書の要件を再確認
2. 不明点はClaude Codeに確認依頼
3. 保守的な判定（Request Changes）を選択

---

## 6. 関連ドキュメント

- テンプレート: `.kiro/ai-coordination/workflow/templates/REVIEW_REPORT.md`
- 品質ゲート: `docs/quality-gates.md`
- コーディング規約: `docs/coding-standards.md`

---
最終更新: 2025-12-30
