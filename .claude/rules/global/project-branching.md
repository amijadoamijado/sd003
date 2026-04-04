# プロジェクト分岐ルール

## 原則

> 「作るべきかどうか」を最初に判断する。
> 作らなくて済むなら作らない。AIに直接任せる。

詳細な哲学: `docs/development-philosophy.md`

## 3つの分岐

作業を開始する前に、どの分岐に該当するか判断する。

```
目的が明確
  │
  ├── 作る必要がない → AIに直接指示して実行（目的→指示→実行）
  │
  └── 作る必要がある
        │
        ├── Google Workspace上で動くアプリ → GAS分岐
        │
        ├── SD003フレームワーク自体の開発・改善 → Cowork分岐
        │
        └── 顧客の業務設計・IT選定支援 → Sukima Digital分岐
```

## 各分岐の定義

### GAS分岐

**条件**: Google Workspace上で動くWebアプリ・自動化を作る場合

| 適用ルール | パス |
|-----------|------|
| Env Interface Pattern | `.claude/rules/gas/env-interface.md` |
| GAS環境制約 | `.claude/rules/gas/gas-constraints.md` |
| Work First | `.claude/rules/global/work-first.md` |

**判断基準**: スプレッドシート連携、Google認証、Apps Script実行環境が前提のとき

### Cowork分岐（AI協調）

**条件**: SD003フレームワーク自体の開発、Multi-AI協調基盤の改善

| 適用ルール | パス |
|-----------|------|
| AI協調体制 | `.claude/rules/workflow/ai-coordination.md` |
| Multi-CLI同期 | `scripts/sync-cli-commands.py` |
| Ralph Loop | `.claude/rules/ralph-loop.md` |

**判断基準**: Claude Code/Codex/Gemini/Antigravityの連携、スキル・コマンドの管理

### Sukima Digital分岐（ITコーディネート）

**条件**: 顧客の業務設計、AI導入設計、IT選定支援

| 特性 | 説明 |
|------|------|
| 目的 | 顧客の業務を問い直し、AIの能力を前提に再設計する |
| 成果物 | 設計書、提案書、業務フロー、指示テンプレート |
| やらないこと | 開発代行、専用ツール構築、SaaS販売 |
| 思想 | HUMONAIZ / AI-Bow |

**判断基準**: 顧客向け成果物、ビジネス文書、サービス設計のとき

## 「作らない」判断

以下に該当する場合、開発せずAIに直接任せる：

| パターン | 例 |
|---------|-----|
| 1回きりの処理 | データ変換、集計、レポート生成 |
| 定型化不要の分析 | 業務診断、差異分析 |
| 文書作成 | 提案書、計画書、議事録 |
| 既存AIの能力範囲内 | 6ヶ月後には確実にできること |

**問い**: 「6ヶ月後のLLMはこれを自力でできるか？」
→ Yes → ハーネス側で作り込まない（LLMの進化で不要になる）
→ No → 今のうちに設計に組み込む（6ヶ月後に始めても遅い）

## 分岐の併用

1つのプロジェクトが複数の分岐にまたがることはある。

例: Sukima Digitalの顧客向けにAI-Bow Deskを設計（Sukima Digital分岐）し、
プロトタイプをGASで実装（GAS分岐）する場合。

その場合、各フェーズで該当する分岐のルールを適用する。
