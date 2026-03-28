# 実装指示書（IMPLEMENT_REQUEST_{NNN}）

## 案件情報

- **案件ID**: {YYYYMMDD-NNN-slug}
- **依頼元**: {Claude Code / etc.}
- **依頼先**: {Gemini CLI / Codex / etc.}
- **種別**: {新規実装 / 改修 / バグ修正}
- **優先度**: {P0 / P1 / P2}
- **日付**: {YYYY-MM-DD}

## 概要

{1-3行で何を実装するか}

## 機能要件

- [ ] {具体的な要件1}
- [ ] {具体的な要件2}
- [ ] {具体的な要件3}

## UI要件（Web UIがある場合）

> このセクションはWeb UIを含む案件のみ記載。バックエンドのみの案件では省略可。

- **デザイントークン**: `.kiro/design/DESIGN_TOKENS.md` を参照
- **画面構成**: {ページ構成の概要}
- **必須状態UI**: loading / empty / error / success の4状態を実装すること
- **デザイン原則**: `.claude/rules/ui/web-design-principles.md` に従う

## 受入基準（Acceptance Criteria）

> レビュアーはこの基準に照らして各項目を PASS/FAIL で判定する。
> 曖昧な「Approve」ではなく、基準と結果の照合で判定すること。

### 機能

- [ ] 全機能要件がブラウザ実動作で確認済み
- [ ] エラーハンドリングが実装されている

### コード品質

- [ ] コード品質スコア: **35/50 以上**（REVIEW_REPORT参照）
- [ ] TypeScript strict mode エラーなし（該当する場合）
- [ ] ESLint エラーなし（該当する場合）

### UI品質（Web UIがある場合）

- [ ] UI品質スコア: **50/70 以上**（visual-review-checklist.md参照）
- [ ] レスポンシブ確認済み（768px以下で崩れない）
- [ ] デザイントークン準拠
- [ ] スクリーンショット添付（実画面確認の証跡）

### テスト

- [ ] テストが追加/更新されている（該当する場合）
- [ ] 既存テストがパスする

## 品質スコア合格ライン

| 評価 | 合格ライン | 評価方法 |
|------|-----------|---------|
| コード品質 | 35/50 | `.kiro/ai-coordination/workflow/templates/REVIEW_REPORT.md` |
| UI品質 | 50/70 | `.claude/rules/ui/visual-review-checklist.md` |

## 参照ファイル一覧

| ファイル | 用途 |
|---------|------|
| {src/xxx.ts} | {対象ソースコード} |
| {tests/xxx.test.ts} | {対象テスト} |

## 備考

{補足事項、制約、注意点}
