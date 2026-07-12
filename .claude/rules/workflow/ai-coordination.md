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
>
> **2026-07-12 変更**: Grok **Lead mode** を正式採用。司令塔は「常に Claude」ではなく
> **そのセッションを開いた入口 CLI** に紐づく。Grok は汎用控えではなく、
> Lead / 探索実装 / 独立検証 / 調査主導の第一候補になりうる。

## 司令塔ルール（Session Lead）

| 原則 | 内容 |
|------|------|
| 入口 = 司令塔 | ユーザーが開いた CLI がそのセッションの **Session Lead（司令塔）** |
| Claude 固定ではない | Claude Code はよく使う Lead 候補の1つ。常時必須ではない |
| Lead の責任 | 工程判断、変更方針、完了判定、ユーザーへの最終報告、必要時の他AIへの handoff |
| Assist の責任 | Lead またはユーザーから渡された範囲だけを実行し、repo 所有権を奪わない |

### Lead の判定

| 起動状況 | Session Lead | 備考 |
|----------|--------------|------|
| ユーザーが Grok CLI / Grok TUI を直接起動 | **Grok** | **Lead mode**（正本: `.grok/GROK_NATIVE.md`） |
| ユーザーが Claude Code を直接起動 | **Claude Code** | 既定の日常入口の1つ |
| ユーザーが Codex を直接起動 | **Codex** | Native: `.codex/CODEX_NATIVE.md` |
| ユーザーが agy を直接起動 | **agy** | 実装/E2E セッション |
| 他AIから非対話ディスパッチされた | 呼び出し元が Lead、被呼び出しは **Assist** | Grok は `grok-dispatch` 経由なら Assist |

明示トリガーで Lead を切り替えられる（会話中でも可）:

- `Grok主導で` / `grokで進めて` / `このセッションはGrok` / `Grokに任せる` → **Grok Lead**
- `Claudeに戻す` / `司令塔はClaude` → **Claude Lead**

## 対応AI（4種類）と役割

| AI | 役割 | 呼び出し |
|----|------|---------|
| Claude Code | Session Lead 候補・計画・工程管理・他AIディスパッチ | — |
| Codex | レビュー主担当・公式品質印・調査/rescue | `/codex:review`, `/codex:adversarial-review`, `/codex:rescue` |
| Antigravity (agy) | 実装・E2E・本番確認の主担当 | `agy --prompt ...`（詳細: `antigravity.md`） |
| Grok | **Lead 候補** / 探索実装 / 独立検証 / 調査主導 / Assist（セカンドパス） | 直接起動=Lead、`grok-dispatch`=Assist |

**廃止/置換**: Cursor, Windsurf。Gemini CLI は agy に置換済み（`gemini-dispatch` は歴史的経緯で残存するが新規は agy/Grok に寄せる）。

### 役割分岐（誰にやらせるか）

| 状況 | 第一担当 | 理由 |
|------|----------|------|
| ユーザーが Grok を直接起動した作業全般 | **Grok Lead** | 入口=司令塔。Claude 経由は不要 |
| コードレビュー・公式品質チェック | **Codex** | レビュー主担当（`/codex:*`） |
| 本番 E2E・iframe 操作・本番確認 | **agy** | E2E 主担当 |
| 探索実装・worktree 改修・中規模実装（依頼時に明示） | **Grok または agy** | 同時書き込み禁止。担当を1つに固定 |
| 調査・セカンドオピニオン・並列検証・独立第二実装パス | **Grok** | 独立視点。最終品質印は Codex に渡してよい |
| 設計批判・adversarial 第二意見 | **Grok または Codex** | 公式印が要るなら Codex、速い第二意見なら Grok |
| 計画・工程・最終判断 | **そのセッションの Lead** | Claude 固定ではない |

### Grok の所有ドメイン（Lead 時の第一候補）

| ドメイン | Grok | 譲る相手 |
|----------|------|----------|
| セッション工程・完了報告 | Lead として実施 | — |
| 探索実装 / worktree 実装 | 第一候補 | 本番直 E2E は agy |
| 調査・Web/X 起点の判断 | 第一候補 | — |
| 独立検証・セカンドパス | 第一候補 | 公式レビュー印は Codex |
| 公式品質印のみのレビュー | 第二意見可 | **Codex が主** |
| 本番 GAS iframe E2E | 準備・分析まで | **agy が主** |
| `clasp deploy` / 固定URL操作 | 禁止（明示指示なし） | ユーザー判断 |

> **排他ルール**: 同一 repo への**複数AI同時書き込みは禁止**（git 競合回避）。
> Lead が repo lock を持つ。Assist は Lead の範囲外を勝手に編集しない。
> プリフライトで RAM だけでなく既存 grok/codex/agy 稼働も確認する。

## 依頼のかけ方（アドホック優先）

- **アドホックな相談・レビュー・実装は会話内で完結してよい**（書面依頼は不要）。
  - Codex: `/codex:*`
  - Grok Assist: `grok-dispatch`（非対話）
  - Grok Lead: ユーザーが Grok を直接起動（対話 TUI / Native）
  - agy: `antigravity.md` の非対話呼び出し
- **案件IDが明示された正式な依頼・報告のときだけ** `.sd/ai-coordination/` 配下に保存する（下記）。

### 保存ルール（正式依頼時のみ）

| 種別 | 保存先 |
|------|--------|
| 依頼書 | `.sd/ai-coordination/workflow/spec/{案件ID}/` |
| 報告書 | `.sd/ai-coordination/workflow/review/{案件ID}/` |
| 引き継ぎログ | `.sd/ai-coordination/handoff/handoff-log.json` |
| Grok セッションメモ | `.sd/ai-coordination/sessions/grok/`（任意・長時間 Lead 時） |

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
| `.grok/` | Grok の仕様・Native・Skills | **NO** |
| `.sd/ai-coordination/` | 正式依頼・報告・ログの集約 | **YES**（案件IDあり時） |

## ディスパッチの実務リンク

- **Codex**: `.claude/skills/codex-dispatch/`（`/codex:review`, `/codex:adversarial-review`, `/codex:rescue`）
- **Grok Assist**: `.claude/skills/grok-dispatch/`（`grok-run.ps1`・非対話）
- **Grok Lead / Native**: `.grok/GROK_NATIVE.md`、入口 `grok.md`、運用 `.sd/ai-coordination/workflow/GROK_GUIDE.md`
- **agy**: `antigravity.md`（非対話は OAuth 済み＋二重起動回避が前提。ハング時は人手ハンドオフへ）

## Grokトリガー語

### Assist mode（他 Lead から呼ぶ / 下請け）

`grokに依頼` / `グロックに` / `grokに相談` / `grokにレビュー` / `grokで実装`（Claude 等から委譲）  
→ `grok-dispatch` で非対話ディスパッチ。

### Lead mode（Grok が司令塔）

`Grok主導で` / `grokで進めて` / `このセッションはGrok` / `Grokに任せる` / ユーザーが Grok CLI を直接起動  
→ Grok が Session Lead。`.grok/GROK_NATIVE.md` に従い自己完結する。Claude 経由は不要。

## 全AIモデル共通

このルールは Claude Code / Codex / Antigravity(agy) / Grok 全てに適用される。
