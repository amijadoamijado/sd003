# DONE - Session 2026-03-15 (2nd)

## 完了事項
- cf001プロジェクトの短期借入金元本返済(13期)処理フロー徹底調査
- BUG確定 #1: FinancialStatementService.ts calculateMonthlyCF() で短期借入金(321)がCF未反映
- BUG確定 #2: FinancialStatementService.ts updateBS() で短期借入金(321)のBS残高更新なし
- 預金コード不整合の発見: CF計算は'111'、仕訳生成は'131'

## 未完了
- [ ] cf001 FinancialStatementService.ts の calculateMonthlyCF() に321チェック追加
- [ ] cf001 FinancialStatementService.ts の updateBS() に321残高更新処理追加
- [ ] 預金コード '111' vs '131' 整合性確認・修正
- [ ] 修正後の13期CF・BS出力検証（実データ）

## 次のステップ
- cf001 FinancialStatementService.ts バグ修正（CF + BS）
- 対象ファイル: D:/claudecode/cf001/src/core/FinancialStatementService.ts
- cf001ブランチ: feature/data-update-2603

## 関連ファイル
- `D:/claudecode/cf001/src/core/FinancialStatementService.ts` (バグ箇所)
- `D:/claudecode/cf001/tests/manual/export-journals-v2.ts` (正常な参考実装)
- `D:/claudecode/cf001/src/core/AggregateAccountMapping.ts` (科目コード定義)
- `D:/claudecode/cf001/active/input/13_tb.csv` (13期試算表)
