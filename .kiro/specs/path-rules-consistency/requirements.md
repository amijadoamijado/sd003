# Path Rules Consistency - Requirements

## Overview

全AIモデル（Claude Code, Codex, Gemini CLI, Antigravity）が同一のパスルールで動作するよう、
Single Source of Truth（RULES.md）を定義し、全設定ファイルに展開する。

## Background

Codexに要件定義書を作成させたところ、`.kiro/specs/` ではなく `.kiro/ai-coordination/workflow/spec/` に保存された。
原因は AGENTS.md の「ALL documents in .kiro/ai-coordination/」という記述が仕様書パスと矛盾していたため。

パスルール全27箇所中、正しく定義されているのはわずか6箇所（22%）。

## Requirements

### REQ-001: RULES.mdに全パスルールを一元定義

- `.handoff/RULES.md` にファイル配置ルール（File Location Rules）セクションを追加
- 仕様書、AI協調ワークフロー、セッション、配置禁止の4カテゴリを網羅
- バージョンを v1.0 → v2.0 に更新

### REQ-002: 全AI設定ファイルにパスルールセクションを含める

- CLAUDE.md, AGENTS.md, gemini.md の各テンプレートに「Common Rules」+「File Location Rules」セクションを追加
- RULES.md参照を必須化

### REQ-003: AGENTS.mdテンプレートを新規作成

- `.claude/skills/kiro-deploy/templates/AGENTS.md.template` を新規作成
- Codex用設定として、正しいパスルールを含める
- 「ALL documents in .kiro/ai-coordination/」という矛盾記述を排除

### REQ-004: 全テンプレートに「RULES.md参照必須」を明記

- 各テンプレートに `**MUST READ**: .handoff/RULES.md` を記載
- RULES.mdが正規定義、各設定ファイルはサブセットであることを明確化

### REQ-005: 既存プロジェクトの後方互換性を維持

- 既存の cm001 プロジェクトの設定ファイルを更新
- 既存の機能・セクションを維持しつつパスルールを追加

## Success Criteria

- 全設定ファイルに「File Location Rules」セクションが存在する
- 仕様書パスが `.kiro/specs/{feature}/` と全ファイルで統一されている
- AGENTS.mdに「ALL documents in .kiro/ai-coordination/」がない
- パスルールカバレッジ: 22% → 100%

---
Created: 2026-02-15
