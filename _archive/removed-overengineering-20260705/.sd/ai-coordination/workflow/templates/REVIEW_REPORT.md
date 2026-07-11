# REVIEW_{種別}_{NNN}（レビュー報告）

## メタ情報
- **案件ID**: {YYYYMMDD-NNN-slug}
- **レビュー対象**: {IMPLEMENT_REQUEST_NNN.md / WORK_ORDER.md}
- **レビュー日**: {YYYY-MM-DD}
- **レビュアー**: Codex

## 1. 判定

**{Approve / Request Changes}**

## 2. スコアリング（Output Primacy 配点）

| 項目 | 配点 | スコア | 根拠 |
|------|------|--------|------|
| UI/アウトプット品質 | 60 | /60 | {視覚評価70点満点を換算} |
| 機能動作（実データで動くか） | 30 | /30 | |
| 内部コード品質（型、命名、構造） | 10 | /10 | |
| **合計** | 100 | /100 | |

## 3. UI評価（Web UI案件のみ・visual-review-checklist 7項目）

| # | 評価項目 | スコア | メモ |
|---|---------|--------|------|
| 1 | 視覚階層 | /10 | |
| 2 | 余白・整列 | /10 | |
| 3 | カラー一貫性 | /10 | |
| 4 | タイポグラフィ | /10 | |
| 5 | 状態表現 | /10 | |
| 6 | レスポンシブ | /10 | |
| 7 | 全体印象 | /10 | |
| **合計** | | **/70** | 50未満は Request Changes |

スクショ: materials/images/{案件ID}/

## 4. 指摘事項

| # | 重大度 | 指摘 | 該当箇所 | 修正要否 |
|---|--------|------|---------|---------|
| 1 | {Critical/Major/Minor} | | | |

注: 「内部の綺麗さ」のみを理由とする Request Changes は禁止（Silent Interior）。
output に影響がある場合のみブロックする。改善提案はコメント扱い。

## 5. 次アクション

- Approve → /workflow:test {案件ID} {NNN} へ自動連鎖
- Request Changes → Phase 6（修正対応・Antigravity）へ差し戻し
- handoff-log.json に review_complete を記録
