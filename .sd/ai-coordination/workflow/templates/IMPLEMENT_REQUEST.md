# IMPLEMENT_REQUEST_{NNN}（実装指示）

## メタ情報
- **案件ID**: {YYYYMMDD-NNN-slug}
- **指示番号**: {NNN}
- **発行日**: {YYYY-MM-DD}
- **発行者**: Claude Code
- **実装担当**: Antigravity

## 1. 対象
- **発注書**: WORK_ORDER.md
- **対象ファイル**: {変更対象のパス}

## 2. ゴール（ユーザーが見る画面・受け取るもの）

{ここに「完成時にユーザーが見るもの」を書く。ファイル一覧ではない。
この欄が空の IMPLEMENT_REQUEST は発行禁止（Output Primacy / Template Reject）}

## 3. 実装内容

### 3.1 {タスク名}
- {具体的な変更内容}

## 4. 変更前の3点固定（Work First）

| # | 項目 | 値 |
|---|------|-----|
| 1 | 運用ルール | {例: clasp push のみ、deploy禁止} |
| 2 | 反映方法 | {例: push → @HEAD で確認} |
| 3 | 確認対象URL | {URL または成果物パス} |

## 5. Acceptance Criteria（受入基準）

- [ ] {実環境で検証可能な基準}
- [ ] 実環境（ブラウザ等）で動作確認済み（「動くはず」は不可）
- [ ] スクリーンショットまたは動作ログを materials/ に保存済み

## 6. 禁止事項

- モック/ダミーデータでの動作確認（Real Data First）
- 画面・成果物未確認での完了報告（Output Primacy）
- {案件固有の禁止事項}

## 7. 完了時の報告

- 実装完了 → /workflow:review {案件ID} {NNN} へ自動連鎖
- 報告保存先: .sd/ai-coordination/workflow/review/{案件ID}/
- handoff-log.json に implement_complete を記録
