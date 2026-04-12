# REVIEW_REPORT_{種別}_{NNN}

> Codex レビュー結果。`.claude/rules/workflow/ai-coordination.md` Phase 5 で使用。
> **UIスコア欄は必須**（柱1 Output Primacy）。空欄では Approve 不可。
>
> 実体コピー時: このファイルを `.sd/ai-coordination/workflow/review/{案件ID}/REVIEW_{種別}_{NNN}.md` にコピーし、各欄を具体化する。

---

## 基本情報
- **案件ID**: {案件ID}
- **対象タスク**: {タスク番号}
- **対象ファイル**: {変更対象}
- **レビュー種別**: {WORK_ORDER / IMPL / TEST}
- **レビュー日時**: {YYYY-MM-DD HH:MM:SS}
- **レビュアー**: Codex

## スコアリング（柱1に従い UI/アウトプット優先）

### UI/アウトプット評価（60点満点・柱1）⭐ 必須

IMPLEMENT_REQUEST Section 2「ユーザーが見る画面・受け取るもの」と一致しているか。

| 項目 | 配点 | 評価 |
|------|------|------|
| 画面スクリーンショット存在 | 10 | {0-10} |
| Section 2 記述と一致 | 15 | {0-15} |
| 視覚的品質（`.claude/rules/ui/visual-review-checklist.md` 7項目） | 35 | {0-35} |

**UIスコア合計**: {N}/60

> ⚠️ UIスコア 30/60 未満は自動 Request Changes（柱1違反）。

### 機能動作（30点満点）

実データで意図通り動作するか。

| 項目 | 配点 | 評価 |
|------|------|------|
| dev server 起動確認 | 5 | {0-5} |
| 実データで主要機能が動く | 15 | {0-15} |
| エラーケースも処理される | 10 | {0-10} |

**機能スコア合計**: {N}/30

### 内部コード品質（10点満点・柱2 Silent Interior）

> ⚠️ 内部品質は「黙って動くための最低ライン」のみ評価。優雅さは評価対象外。

| 項目 | 配点 | 評価 |
|------|------|------|
| Quality Prerequisites (Section 0) 全通過 | 5 | {0-5} |
| VTD-001〜005 通過 | 3 | {0-3} |
| 命名・構造の一貫性 | 2 | {0-2} |

**内部スコア合計**: {N}/10

### 総合スコア

**合計**: {UI + 機能 + 内部}/100

| 合計スコア | 判定 |
|-----------|------|
| 80-100 | Approve |
| 60-79 | Approve with comments |
| 40-59 | Request Changes |
| 0-39 | Reject |

**ただしUIスコア 30/60 未満は合計スコアに関わらず Request Changes。**

## 判定

- [ ] ✅ Approve
- [ ] 🟡 Approve with comments（軽微な改善提案）
- [ ] 🔴 Request Changes（修正必須）
- [ ] ❌ Reject（大幅見直し）

## 指摘事項

### UI/アウトプットに関する指摘（優先度：高）
{Section 2 との乖離、視覚的品質の低項目、スクショ不足等}

### 機能動作に関する指摘（優先度：中）
{実データで動かない箇所、エラーケースの未処理等}

### 内部コード品質に関する指摘（優先度：低・柱2準拠）
{Quality Prerequisites 違反。ただし「綺麗さ」の提案は別タスク化}

## 次のアクション

- {Gemini への修正指示 / Approve して Phase 7 に進む / エスカレーション}

## 添付

- スクリーンショット: `materials/images/{案件ID}/`
- ログ: `.sd/ai-coordination/workflow/log/{案件ID}/`
