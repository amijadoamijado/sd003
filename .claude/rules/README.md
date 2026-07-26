---
description: ルール集の目次（人間向け）。ルール編集時のみ注入。
paths:
  - ".claude/rules/**/*"
---

# .claude/rules/

SD003 の開発ルール集。**読み込み機構に注意**:

| フロントマター | 挙動 |
|---------------|------|
| `paths:` なし | **毎セッション全文が常時ロードされる**（トークン固定費）|
| `paths:` あり | 該当パスのファイルを扱うときのみロード（条件ロード）|

> 2026-07-26 Claude 5世代lean化: 常時ロードは要点圧縮した3ファイルのみに削減。
> ドクトリン・手順の全文は `docs/rules-reference/` へ移設（CLAUDE.md の IMPORTANT 行が要約とパスを保持）。
> **新規ルールを追加するときは原則 `paths:` を付ける。常時ロード追加は最小限に。**

## 常時ロード（要点のみ・3ファイル）

| ファイル | 内容 |
|---------|------|
| `cleanup/file-organization.md` | 保存先規約・rm禁止・上書き禁止（hook未整備のため文で維持） |
| `git/sd-safe-commit.md` | .sd/ 操作規約・L1-L4防御・手動復元手順 |
| `specs/spec-driven.md` | 仕様書配置 `.sd/specs/`・`spec.md` 命名（hook裏付けあり） |

## 条件ロード（paths: 付き）

| ファイル | トリガー |
|---------|---------|
| `architecture/adapter-core-pattern.md` | アーキテクチャ関連パス |
| `gas/env-interface.md` / `gas/gas-constraints.md` | GASコード |
| `global/claude-md-style.md` | CLAUDE.md編集 |
| `global/playwright-cache.md` | Playwright関連 |
| `global/quality-standards.md` | ソースコード |
| `session/session-management.md` | `.sessions/**` |
| `skills/skill-trust-policy.md` / `skills/skill-check-before-action.md` | スキル関連 |
| `specs/spec-versioning.md` | 仕様書 |
| `testing/testing-standards.md` / `testing/production-data-tdd.md` | テストコード |
| `ui/web-design-principles.md` / `ui/visual-review-checklist.md` | UI関連 |
| `workflow/ai-coordination.md` | AI協調 |

## 参照文書（常時ロード対象外・docs/rules-reference/）

4本柱詳細（output-primacy / silent-interior / real-data-first / segmented-sequencing）、
work-first、known-unknowns、quiz-gate、project-branching、branch-strategy、
artifact-confirmation、fullpath-display、artifact-output-location、
root-cause-first、bug-quick、dialogue-resolution、memory-nudge、learning-nudge、
および Phase2 圧縮前の原本（*-full.md）。

要約は `CLAUDE.md` の Conditional Context（IMPORTANT 行）が保持し、
詳細が必要なときに AI が `Details:` パスを読みに行く（progressive disclosure）。
