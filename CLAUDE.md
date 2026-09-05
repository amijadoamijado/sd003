# SD003 Framework - AI Development Command Center

## Session Start

`/sessionread` → 4ファイル自動読込 | Crash Recovery: `claude --continue` + `/sessionread`

## Overview

SD003: Work First + 痛みから生まれた仕組みの集合体。
TypeScript (strict) + Google Apps Script + Env Interface Pattern.
AI協調: Session Lead=入口CLI（Claude/Grok/…） + Codex(レビュー) + Antigravity(実装 & E2E) + Grok(Lead候補・探索実装・独立検証)

Common rules for all AI models: `.handoff/RULES.md`
Handoff on exit: `cp .handoff/DONE.template.md .handoff/DONE.md`

## Work First（最上位・全ルールに優先）

開発順序: 動かす → 実環境で確認 → テスト → 抽象化 → 文書

- コード変更後、必ず実環境（ブラウザ）で動作確認する。「動くはず」は禁止。「動いた」のみが確認
- 変更前に3点固定: 運用ルール、反映方法、確認対象URL
- 変更前に仮説明文化: 症状、仮説、確認方法、失敗時の次手
- 1修正ごとに動作確認。抽象化は同じコードが3回出てから
- 詳細: `docs/rules-reference/global/work-first.md`

## Blueprint Gate（設計ゲート）

1時間以上かかるタスク OR ゴールが言語化できない場合 → `/blueprint-gate` 必須。
承認プロセスなし。動くものが最終判定。詳細: `.claude/skills/blueprint-gate/SKILL.md`

## Build & Test

```bash
npm run build && npm test && npm run lint
npm run test:gas-fakes   # Tier-2 gas-fakes tests only
```

## Required Settings

`.claude/settings.local.json`: `"ENABLE_TOOL_SEARCH": "true"`

## File Safety

- rm禁止（アーカイブ移動）、ユーザー提供ファイル上書き禁止（別名で新規作成）
- ルート直下への新規ファイル作成禁止
- 保存先・URLをユーザーに案内するときは絶対パス（フルパス）で表示する
- 詳細: `.claude/rules/cleanup/file-organization.md`

## Bash Tool Policy

Bashツールは便利だが既知バグが多い（heredoc破壊、パイプstdin消失、長文コマンド誤動作、ランタイムによるワーキングツリーリフレッシュ）。安定性を優先し、代替手段があればそちらを使う。

- **ファイル作成・編集**: Write/Edit tool優先。Bashのheredoc/リダイレクトは避ける
- **.sd/操作**: Bashのみ（Write/Editはhookブロック）。変更後は早めにcommit（未commitはwipe時にL4で復元されない）
- **git commit**: 短い1行コマンドのみ。heredocでのcommitメッセージは避ける
- **監視対象バグ**: anthropics/claude-code #15599, #24956, #11225, #34330 — 解消時: `docs/bug-workaround-sunset.md`
- 詳細: `.claude/rules/git/sd-safe-commit.md`

---

## Core Doctrine（4本柱）

SD003 の全判断の根拠。詳細: `docs/core-doctrine.md`

- **柱1: Output Primacy** — 「完了」=ユーザーが見る画面・成果物が存在し検証済み。内部ファイル数は完了指標ではない
- **柱2: Silent Interior** — 内部は黙って動け。設計の優雅さより動くことが先
- **柱3: Real Data First** — 実データで動かす。テストのためのテスト禁止。バグ再現時のみ最小テスト
- **柱4: Segmented Sequencing** — 非ブロッキングを連続実行、ユーザー確認は末端に1回集約

## Conditional Context

IMPORTANT: タスクの「完了」判定は柱1 — ユーザーが見る画面/成果物が存在し検証済みであること。画面ゼロは進捗ゼロ。Details: `docs/rules-reference/global/output-primacy.md`

IMPORTANT: 内部設計（adapter/core/interface/types）は柱2 — 動くアウトプットが先、内部パターンは安定後。types→interface→adapter→core の順で始めない。Details: `docs/rules-reference/global/silent-interior.md`

IMPORTANT: テストは柱3 — 本番バグの再現・固定時のみ、実データ（またはコピー）で書く。モック・カバレッジ目標・テストのためのテストは禁止（VTD-001〜005自動検出）。Adapter層のみ本番データコピーで徹底検証。Details: `docs/rules-reference/global/real-data-first.md`, `.claude/rules/testing/`

IMPORTANT: 段取りは柱4 — 非ブロッキング（tsc/lint/test/dev server/スクショ）を連続実行し、ユーザー確認は AskUserQuestion で末端に1回。確認の省略も毎ステップ確認も禁止。Details: `docs/rules-reference/global/segmented-sequencing.md`

IMPORTANT: タスク開始時に分岐判定 — GAS（Google Workspaceアプリ）/ Cowork（SD003自体）/ Sukima Digital（業務設計）。AI直接実行で済むものは作らない。Details: `docs/rules-reference/global/project-branching.md`, `docs/development-philosophy.md`

IMPORTANT: 非自明な作業の着手前・完了宣言前に無知の知（Known Unknowns）— 知らないことを先に宣言する。GREEN=証拠確認済 / YELLOW=要確認（条文・実データ・コードで確認後に昇格）/ RED=想定外乖離→`/bug-trace`。blindspot pass は1問のみ、フォーム化・儀式化は禁止。未知の宣言は報酬であり罰しない。Details: `docs/rules-reference/global/known-unknowns.md`

IMPORTANT: Blueprint Gate必須ライン（1時間超/ゴール未定義）の実装完了主張には Quiz Gate — `/codex:review` で Evaluator が差分に即したクイズを1〜3問出題。自己申告のみは証拠ゼロ。fail-open（警告のみ、マージブロックしない）。Details: `docs/rules-reference/global/quiz-gate.md`

IMPORTANT: When writing or modifying GAS code, use Env Interface Pattern. Node.js APIs (`fs`, `path`, `process`) are prohibited. iframe/CORS/@HEAD等の既知制約は即コードに反映。Details: `.claude/rules/gas/`

IMPORTANT: AI協調文書は `.sd/ai-coordination/` へ（`.antigravity/` やルート禁止）。アドホック相談は各AIのディスパッチスキルを使う。Details: `.claude/rules/workflow/ai-coordination.md`

IMPORTANT: Codexへのアドホック相談・レビュー（「codexにレビューさせて」等）は公式プラグインを使う — `/codex:review`（読み取り）/ `/codex:adversarial-review`（批判的）/ `/codex:rescue`（調査・修正委譲）。未セットアップ時は `/codex:setup` を一度実行。

IMPORTANT: Grokは2モード。**Lead mode**（ユーザーがGrok直接起動、「Grok主導で」「grokで進めて」等）→ Claudeはオーケストレーションせずハンドオフ（`.grok/GROK_NATIVE.md`）。**Assist mode**（「grokに相談/依頼/実装」等）→ `grok-dispatch` スキル（`pwsh -File grok-run.ps1 <repo> <out> "<prompt>"`、モデル名は固定せず省略=CLI既定、`--output-format plain`）。Grok=探索実装・独立検証・リサーチ / Codex=正式レビュー / agy=本番E2E。Details: `.claude/rules/workflow/ai-coordination.md`

IMPORTANT: SD003の他プロジェクト展開は `/sd-deploy` のみ。手動デプロイ禁止。Details: `.claude/skills/sd-deploy/SKILL.md`

IMPORTANT: 仕様書は `.sd/specs/{feature}/` のみ、メインは `spec.md`（`design.md` 禁止=Antigravity予約）。hook `enforce-spec-location.sh` が違反書き込みを物理deny。Details: `.claude/rules/specs/spec-driven.md`

IMPORTANT: Excel/CSV/PDF/画像を扱う前に `.claude/skills/` の該当スキルを確認し SKILL.md に正確に従う（cf001データ破損事故の再発防止）。Details: `.claude/rules/skills/skill-check-before-action.md`

IMPORTANT: デバッグは3階層 — `/bug-quick`（5-15分・フロー照合）→ `/bug-trace`（30-60分・3エージェント並列）→ `/dialogue-resolution`（AI迷走検出・各Step後にAskUserQuestion必須）。同一エラー2回目でエスカレーション。

IMPORTANT: Web UI（HTML/CSS/JS）は8デザイン原則＋デザイントークン適用、視覚品質スコア50/70以上。Details: `.claude/rules/ui/`

IMPORTANT: Playwright等のChromiumダウンロードは共有キャッシュ `D:\playwright-browsers` を使う。プロジェクトローカルの `PLAYWRIGHT_BROWSERS_PATH` 設定禁止。Details: `.claude/rules/global/playwright-cache.md`

IMPORTANT: 全AI（特にagy）の成果物はプロジェクト内へ保存 — ユーザー向けは `materials/`、協調文書は `.sd/ai-coordination/`、FW文書は `docs/`。agyの `~/.gemini/antigravity-cli/brain/<会話ID>/` に唯一のコピーを残さない（CLIから発見不能=柱1違反）。発見時は `scripts/recover-agy-artifacts.sh` で回収しフルパス提示。Details: `docs/rules-reference/workflow/artifact-output-location.md`

IMPORTANT: UIをユーザーに見せる前にバックエンド統合・デプロイへ進まない。「動くはず」ではなく「ユーザーが見て承認した」が確認。

IMPORTANT: 構造化・複数項目の確認事項（計画/マトリクス/レビュー結果/差分要約/進捗）は Artifact で提示（`artifact-design` スキル必読）し、判断は AskUserQuestion で末端集約。単純な二択はインラインのまま（過剰ceremony禁止）。Artifact不可環境はテキストにフォールバック。Details: `docs/rules-reference/global/artifact-confirmation.md`

IMPORTANT: Solo運用 — master/main で直接作業する。ブランチ・PR作成はユーザー指示時のみ（提案は可、無断作成・無断切替・無断削除は禁止）。セッション終了時は commit に加えて `git pull --rebase && git push` まで完了させる（2026-07-26裁定: Beads運用を正とする）。Details: `docs/rules-reference/git/branch-strategy.md`

IMPORTANT: 異常・エラー時は根本原因の特定が先 — 1)症状記述 2)自分の直前の行動を列挙 3)自分原因の仮説を最初に（外部要因は最後）4)検証 5)それから修正+登録+commit。「気をつける」は対策ではない。Details: `docs/rules-reference/troubleshooting/root-cause-first.md`

IMPORTANT: 大きなタスク完了後（テスト通過・実装完了・バグ解決）、保存すべき知見がないか自己評価（非対話・非ブロッキング・控えめ・重複チェック）。Details: `docs/rules-reference/session/memory-nudge.md`

IMPORTANT: `/sessionwrite` 時は学習評価 — セッション中のユーザー修正をレビューし備考に記録、2回以上でルール/スキル/メモリ化を提案（提案のみ・自動作成禁止）。Details: `docs/rules-reference/skills/learning-nudge.md`

---

## Quick Command Reference

| Category | Commands |
|----------|----------|
| Blueprint | `/blueprint-gate` |
| Debug | `/bug-quick`, `/bug-trace`, `/dialogue-resolution`, `/ai-suspect` |
| Session | `/sessionread`, `/sessionwrite`, `/sessionhistory`, `/session-search` |
| Skills | `/sd:skills-find`, `skills-add`, `skills-list` |
| Cleanup | `/cleanup`, `restore`, `history` |

---
SD003 Framework v2.19.1 | deploy v3.5.0 | Updated: 2026-09-05 (Codex手順・配布時の保護フォルダ対応) | Style: `.claude/rules/global/claude-md-style.md`
