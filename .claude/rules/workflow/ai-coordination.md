---
description: AI協調体制（Codex/Antigravity/Grok連携の正本）。協調文書作成時に適用。要約とトリガー語はCLAUDE.mdの条件ブロック参照。
paths:
  - ".sd/ai-coordination/**/*"
---

# AI協調体制（軽量ディスパッチ版）

> **2026-07-05 変更**: 旧「7段階ワークフロー」（`/workflow:init/order/request/impl/review/test/status` による
> WORK_ORDER→IMPLEMENT_REQUEST→REVIEW_REPORT→TEST_REQUEST の自動連鎖）は**過剰設計として撤去**した。
> 現在のモデルは実装→失敗→修正→再実行を自己完結でき、書面受け渡しの儀式は不要。各AIへは
> **軽量CLIディスパッチで直接依頼**する。旧コマンド・テンプレ機構は
> `_archive/removed-overengineering-20260705/` にアーカイブ（git履歴で復元可）。

## 対応AI（4種類）と役割

| AI | 役割 | 呼び出し |
|----|------|---------|
| Claude Code | 計画・工程管理・最終判断（司令塔） | — |
| Codex | レビュー・チェック・タスク委譲 | `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`（公式プラグイン） |
| Antigravity (agy) | 実装・E2E・探索調査・本番確認 | `agy --prompt ... --dangerously-skip-permissions`（詳細: `antigravity.md`） |
| Grok | 汎用（実装補助・調査・セカンドオピニオン・並列検証） | `grok-dispatch`（`grok-build`モデル・非対話） |

**廃止/置換**: Cursor, Windsurf。Gemini CLI は agy に置換済み（`gemini-dispatch` は歴史的経緯で残存するが新規は agy/Grok に寄せる）。

### 役割分岐（誰にやらせるか・司令塔の迷い防止）

| 状況 | 担当 | 理由 |
|------|------|------|
| コードレビュー・チェック | **Codex** | レビュー主担当（`/codex:*`） |
| 実装・E2E・本番確認 | **agy** | 実装主担当（非対話ディスパッチ） |
| セカンドオピニオン・補助調査・並列検証・軽い実装相談 | **Grok** | 汎用。Codex/agy と競合する作業は重複させない |
| 計画・工程管理・最終判断 | **Claude Code** | 司令塔 |

> **排他ルール**: 同一 repo への**複数AI同時書き込みは禁止**（git 競合回避）。
> プリフライトで RAM だけでなく既存 grok/codex/agy 稼働も確認する。

## 依頼のかけ方（アドホック優先）

- **アドホックな相談・レビュー・実装補助は会話内で完結してよい**（書面依頼は不要）。
  Codex は `/codex:*`、Grok は `grok-dispatch`、agy は `antigravity.md` の非対話呼び出し。
- **案件IDが明示された正式な依頼・報告のときだけ** `.sd/ai-coordination/` 配下に保存する（下記）。

### 保存ルール（正式依頼時のみ）

| 種別 | 保存先 |
|------|--------|
| 依頼書 | `.sd/ai-coordination/workflow/spec/{案件ID}/` |
| 報告書 | `.sd/ai-coordination/workflow/review/{案件ID}/` |
| 引き継ぎログ | `.sd/ai-coordination/handoff/handoff-log.json` |

### 禁止

| 禁止 | 理由 |
|------|------|
| `.antigravity/` / プロジェクトルートへの依頼書作成 | 散らかる・案件と紐付かない |
| 成果物をAppData隠しディレクトリに保存 | ユーザーが探せない（詳細: `.claude/rules/workflow/artifact-output-location.md`） |

### AI別設定フォルダの用途（依頼書は置かない）

| フォルダ | 用途 | 依頼書を置く？ |
|---------|------|--------------|
| `.antigravity/` | agyの動作ルール設定 | **NO** |
| `.claude/` | Claude Codeの動作ルール設定 | **NO** |
| `.sd/ai-coordination/` | 正式依頼・報告・ログの集約 | **YES**（案件IDあり時） |

## ディスパッチの実務リンク

- **Codex**: `.claude/skills/codex-dispatch/`（`/codex:review`, `/codex:adversarial-review`, `/codex:rescue`）
- **Grok**: `.claude/skills/grok-dispatch/`（`grok-run.ps1 <repo> <out> "<prompt>" [model]`・`--output-format plain`）
- **agy**: `antigravity.md`（非対話は OAuth 済み＋二重起動回避が前提。ハング時は人手ハンドオフへ）

## Grokトリガー語

`grokに依頼` / `グロックに` / `grokに相談` / `grokにレビュー` → `grok-dispatch` でディスパッチ（汎用・セカンドオピニオン）。

## 全AIモデル共通

このルールは Claude Code / Codex / Antigravity(agy) / Grok 全てに適用される。
