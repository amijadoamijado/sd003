# SD003 Framework - AI Development Command Center

## Session Start

`/sessionread` → 4ファイル自動読込 | Crash Recovery: `claude --continue` + `/sessionread`

## Overview

SD003: Work First + 痛みから生まれた仕組みの集合体。
TypeScript (strict) + Google Apps Script + Env Interface Pattern.
AI協調: Claude Code(司令塔) + Codex(レビュー) + Gemini(実装) + Antigravity(E2E)

Common rules for all AI models: `.handoff/RULES.md`
Handoff on exit: `cp .handoff/DONE.template.md .handoff/DONE.md`

## Work First（最上位・全ルールに優先）

開発順序: 動かす → 実環境で確認 → テスト → 抽象化 → 文書

- コード変更後、必ず実環境（ブラウザ）で動作確認する
- 「動くはず」は禁止。「動いた」のみが確認
- 変更前に3点固定: 運用ルール、反映方法、確認対象URL
- 変更前に仮説明文化: 症状、仮説、確認方法、失敗時の次手
- 詳細: `.claude/rules/global/work-first.md`

## Blueprint Gate（設計ゲート）

1時間以上かかるタスク OR ゴールが言語化できない場合 → `/blueprint-gate` 必須。
ゴール未定義で走り出して修正の嵐になるのは Work First違反。

- 対話でゴール→アウトプット→検証観点→背景→現状を引き出す
- 承認プロセスなし。動くものが最終判定
- 詳細: `.claude/skills/blueprint-gate/SKILL.md`

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
- 詳細: `.claude/rules/cleanup/file-organization.md`

## Bash Tool Policy

Bashツールは便利だが既知バグが多い（heredoc破壊、パイプstdin消失、長文コマンド誤動作、ランタイムによるワーキングツリーリフレッシュ）。安定性を優先し、代替手段があればそちらを使う。バグが解消されればBash利用を解禁する。

- **ファイル作成・編集**: Write/Edit tool優先。Bashのheredoc/リダイレクトは避ける
- **.sd/操作**: Write/Edit + pre-commit hookで自動ステージ。Bashでのgit add .sd/は不要
- **git commit**: 短い1行コマンドのみ。heredocでのcommitメッセージは避ける
- **Bash使用OK**: git status, ls, npm, 短いコマンド
- **監視対象バグ**: anthropics/claude-code #15599, #24956, #11225, #34330 — 解消確認後にBash制限を緩和
- 詳細: `.claude/rules/git/sd-safe-commit.md`

---

## Conditional Context

IMPORTANT: When starting any task, determine which project branch applies: GAS (Google Apps Script app), Cowork (SD003 framework/AI coordination), or Sukima Digital (IT coordination/business design). If the task can be accomplished by AI direct execution without building anything, don't build. Details: `.claude/rules/global/project-branching.md`, `docs/development-philosophy.md`

IMPORTANT: When writing or modifying GAS code, use Env Interface Pattern. Node.js APIs (`fs`, `path`, `process`) are prohibited. Known constraints (iframe, CORS, @HEAD vs fixed deployment) must be reflected in code immediately. Details: `.claude/rules/gas/env-interface.md`, `.claude/rules/gas/gas-constraints.md`

IMPORTANT: When running tests or writing test code, enforce production data TDD. Mock/dummy/empty data is prohibited for Adapter layer. Fallback tests (skip on failure) are prohibited. Coverage-only tests are prohibited. The sole purpose of tests is finding production bugs. VTD validation required. Details: `.claude/rules/testing/testing-standards.md`, `.claude/rules/testing/production-data-tdd.md`

IMPORTANT: When coordinating with other AIs (Codex, Gemini, Antigravity), all documents go to `.sd/ai-coordination/`. Never create in `.antigravity/` or project root. Trigger keywords: "...に依頼", "指示書作成", "test request", "implement", "review". Auto-chain: request → impl → review → test. Details: `.claude/rules/workflow/ai-coordination.md`

IMPORTANT: When deploying SD003 to another project, use `/sd-deploy` command only. Manual deploy is prohibited. Details: `.claude/skills/sd-deploy/SKILL.md`

IMPORTANT: When refactoring, use checkpoint-based batches with `/refactor:init`. Context auto-compact at 70%, auto-clear at 85%. Rollback requires user confirmation. Details: `.claude/rules/refactoring/refactoring-system.md`

IMPORTANT: If a file operation involves Excel, CSV, PDF, or images, check `.claude/skills/` first for applicable skill. Follow SKILL.md instructions exactly. Skipping this check has caused data corruption (cf001 incident). Details: `.claude/rules/skills/skill-check-before-action.md`

IMPORTANT: When debugging, use the 3-tier system: `/bug-quick` (5-15min, flow comparison) → `/bug-trace` (30-60min, 3-agent parallel) → `/dialogue-resolution` (AI reasoning check). Escalate on 2nd same error. Details: `.claude/rules/troubleshooting/`

IMPORTANT: When in a loop session (`/sd003:loop-*`), follow Ralph Loop rules. Midpoint: loop freely. Endgame: same error 2x → stop and escalate. Night mode: `/ralph-wiggum:*`. Details: `.claude/rules/ralph-loop.md`

IMPORTANT: When building or modifying Web UI (HTML/CSS/JS), follow the 8 design principles, apply design tokens, and check visual quality score (50/70 minimum). Details: `.claude/rules/ui/web-design-principles.md`, `.claude/rules/ui/visual-review-checklist.md`

IMPORTANT: When running Playwright or any tool that downloads Chromium, use the shared cache at `D:\playwright-browsers`. Never set `PLAYWRIGHT_BROWSERS_PATH` to a project-local path. Details: `.claude/rules/global/playwright-cache.md`

IMPORTANT: When showing UI to the user, always present the screen for confirmation before proceeding to backend integration or deployment. "Should work" is not confirmation — "user saw it and approved" is.

IMPORTANT: When committing .sd/ files, MUST complete git add + commit in the SAME bash command. Splitting across bash calls causes .sd/ directory to vanish (Claude Code runtime bug). settings.json must be in .gitignore. Details: `.claude/rules/git/sd-safe-commit.md`

IMPORTANT: When any anomaly or error occurs, do NOT implement fixes before identifying root cause. Follow: 1) describe symptom, 2) list own recent actions, 3) hypothesize own actions as cause FIRST (external factors LAST), 4) verify hypothesis, 5) THEN implement fix + register + commit + package. "Being careful" is not a fix. Details: `.claude/rules/troubleshooting/root-cause-first.md`

IMPORTANT: After completing a major task (tests pass, implementation done, bug fixed), self-evaluate whether any discoveries or corrections from this session should be persisted to auto-memory or session notes. Non-blocking, non-interactive. Details: `.claude/rules/session/memory-nudge.md`

IMPORTANT: When running `/sessionwrite`, include a learning evaluation in the session record: review user corrections during the session, record them in the notes section, and suggest rule/skill/memory creation if 2+ corrections detected. Non-blocking. Details: `.claude/rules/skills/learning-nudge.md`

---

## Quick Command Reference

| Category | Commands |
|----------|----------|
| Blueprint | `/blueprint-gate` |
| AI Workflow | `/workflow:init`, `order`, `request`, `impl`, `review`, `test`, `status` |
| Loop | `/sd003:loop-test`, `loop-lint`, `loop-type` |
| Night | `/ralph-wiggum:run`, `status`, `plan` |
| Debug | `/bug-quick`, `/bug-trace`, `/dialogue-resolution` |
| Session | `/sessionread`, `/sessionwrite`, `/sessionhistory`, `/session-search` |
| Skills | `/sd:skills-find`, `skills-add`, `skills-list` |
| Refactor | `/refactor:init`, `plan`, `batch`, `complete`, `rollback` |
| Cleanup | `/cleanup`, `restore`, `history` |

---
SD003 v3.1.0 | Updated: 2026-04-11 | Style: `.claude/rules/global/claude-md-style.md`
