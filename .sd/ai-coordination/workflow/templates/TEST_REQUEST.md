# TEST_REQUEST_{NNN}（テスト依頼）

## メタ情報
- **案件ID**: {YYYYMMDD-NNN-slug}
- **依頼番号**: {NNN}
- **発行日**: {YYYY-MM-DD}
- **発行者**: Claude Code
- **テスト担当**: Antigravity

## 1. テスト対象

- **対象実装**: IMPLEMENT_REQUEST_{NNN}.md
- **確認対象URL**: {本番/ステージングURL。@HEAD か固定deploymentかを明記}
- **対象データ**: {実データまたはそのコピー。モック禁止（Real Data First）}

## 2. テスト項目

| # | 項目 | 操作 | 期待結果 |
|---|------|------|---------|
| 1 | {主要フロー} | {操作手順} | {期待される画面・出力} |
| 2 | {エッジケース} | | |

## 3. 探索的テスト（任意）

- {仕様外の動作確認、UX検証の観点}

## 4. 証跡要件

- [ ] 各テスト項目のスクリーンショット（materials/images/{案件ID}/）
- [ ] 実データでの動作ログ

## 5. 報告

- TEST_REPORT_{NNN}.md を作成
- 保存先: .sd/ai-coordination/workflow/review/{案件ID}/
- handoff-log.json に test_report を記録
