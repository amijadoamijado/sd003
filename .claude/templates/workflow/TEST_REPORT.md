# TEST_REPORT_{NNN}

> Antigravity E2Eテスト結果。
> ⚠️ status は **"Pending" 禁止**（柱1 Output Primacy）。テストが実施されていないなら "Escalated" でエスカレーション。
>
> 実体コピー時: このファイルを `.sd/ai-coordination/workflow/review/{案件ID}/TEST_REPORT_{NNN}.md` にコピーし、各欄を具体化する。

---

## 基本情報
- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **テスト日時**: {YYYY-MM-DD HH:MM:SS}
- **テスター**: Antigravity / Claude Code (Antigravity不在時)

## Status（⛔ Pending 禁止）

- [ ] ✅ **Passed**: 全テストケース通過
- [ ] 🟡 **Passed with notes**: 通過したが軽微な気付きあり
- [ ] 🔴 **Failed**: テストケース未通過
- [ ] 🆘 **Escalated**: Antigravity 不在のため人間判断必要（Pendingの代わりにこれを使う）
- [ ] ⏸️ **Blocked**: 環境未整備等で実行不能（ブロッカー明記必須）

> "Pending" はこのテンプレートには存在しない。
> 実施できない場合は必ず "Escalated" または "Blocked" を選び理由を記載する。

## テスト環境
- **URL**: {確認対象URL}
- **ブラウザ**: {Chrome / Edge / Firefox / Safari}
- **データソース**: {本番 / ステージング / 実データコピー}
- **スクリーンショット保存先**: `materials/images/{案件ID}/`

## テストケース結果

| # | テストケース | 期待結果 | 実際の結果 | 判定 | スクショ |
|---|------------|---------|-----------|------|---------|
| 1 | {ケース名} | {期待} | {実際} | ✅/🔴 | {ファイル名} |
| 2 | | | | | |
| 3 | | | | | |

## UI/アウトプット確認（柱1）

IMPLEMENT_REQUEST Section 2 に記述された「ユーザーが見るもの」が実際に表示されているか:

- [ ] 主要画面がブラウザで開ける
- [ ] 実データで意図通り表示される
- [ ] スクリーンショット取得済み

スクショURL: {materials/images/{案件ID}/*.png}

## 発見事項

### 不具合（要修正）
{実データで発生したバグを列挙。このバグは柱3により最小テストを追加する対象}

### 気付き（任意改善）
{ユーザー体験上の気付き。修正必須ではないもの}

### 未検証領域
{時間・環境制約で未検証の範囲を明記。Pending扱いにはしない}

## 次のアクション

- Passed → PROJECT_STATUS.md 更新、Phase 8（工程完了）へ
- Failed → IMPLEMENT_REQUEST に差し戻し、修正指示
- Escalated → Claude Code がブラウザで確認するか、ユーザーに判断を仰ぐ
- Blocked → ブロッカー解消後に再実施
