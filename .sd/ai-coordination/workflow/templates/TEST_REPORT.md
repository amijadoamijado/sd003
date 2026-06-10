# TEST_REPORT_{NNN}（テスト報告）

## メタ情報
- **案件ID**: {YYYYMMDD-NNN-slug}
- **報告番号**: {NNN}
- **テスト日**: {YYYY-MM-DD}
- **テスト担当**: Antigravity
- **対応依頼**: TEST_REQUEST_{NNN}.md

## 1. 総合判定

**{Pass / Fail / Conditional Pass}**

## 2. テスト結果

| # | 項目 | 結果 | 証跡 | 備考 |
|---|------|------|------|------|
| 1 | {項目} | {Pass/Fail} | {スクショパス} | |

## 3. 発見事項

| # | 重大度 | 内容 | 再現手順 |
|---|--------|------|---------|
| 1 | {Critical/Major/Minor} | | |

## 4. 証跡一覧

- スクリーンショット: materials/images/{案件ID}/
- 動作ログ: {パス}

## 5. 次アクション

- Pass → Phase 8（工程完了・Claude Code）へ
- Fail → 発見事項を添えて Phase 6（修正対応）へ差し戻し
