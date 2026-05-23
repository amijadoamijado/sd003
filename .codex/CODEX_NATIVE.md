# Codex Native Operation Guide

このファイルはSD003をCodexで扱う時の実行優先順位を定義する。
Claude Code正本を変更せず、Codexが自分の強みを出すための薄い実行レイヤーである。

## 原則

1. CodexはClaude Codeのスラッシュコマンドを実行しない。意図を読み、同等の作業を直接行う。
2. Codex内で `/codex:*` を呼び直さない。レビュー、調査、実装はCodex自身が行う。
3. 正式Workflowと日常相談を分ける。案件IDがない場合は軽量レビュー・軽量調査として会話内で完結する。
4. `.claude/` 配下の正本は編集しない。Codex改善は `AGENTS.md`、`.codex/`、Codex生成アダプタに閉じる。
5. 既存の未コミット変更は他AIまたはユーザーの作業として扱い、明示指示なしに戻さない。

## Fast Review

案件IDなしでレビューやチェックを依頼された場合:

1. `git status --short` で作業ツリーを確認する。
2. `git diff --stat` と必要な `git diff` を読む。
3. 可能な範囲で関連テスト、型チェック、lintを実行する。
4. 指摘は重大度順に、場所・影響・修正案を示す。
5. `.sd/ai-coordination/` には保存しない。

## Workflow Review

案件IDとタスク番号がある場合:

1. `.sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{番号}.md` を読む。
2. 実装コミットまたは未コミット差分を確認する。
3. Codex自身がレビューする。`/codex:review` は呼ばない。
4. `.sd/ai-coordination/workflow/review/{案件ID}/REVIEW_IMPL_{番号}.md` に保存する。
5. `handoff-log.json` が存在する場合のみ追記する。存在しない場合は作成可否を確認する。

## Handoff Recovery

Claude Codeのレート制限・停止時:

1. `sessionread` 相当として、グローバル設定、プロジェクト設定、`.sessions/session-current.md`、`.sessions/TIMELINE.md` を読む。
2. `git status --short` と直近コミットを確認する。
3. P0/P1タスク、未コミット変更、検証不足を分ける。
4. 次に安全に進められる最小単位を実行する。

## Direct Implementation

Codexへ実装が委譲された場合:

1. 依頼文または `IMPLEMENT_REQUEST` を読む。
2. 変更対象を限定し、既存パターンに合わせて編集する。
3. `apply_patch` を優先し、不要なリファクタを避ける。
4. 実行可能な検証を行い、失敗時は原因と残作業を明記する。
5. ユーザーの明示指示なしに `clasp deploy`、`clasp undeploy`、破壊的git操作をしない。
