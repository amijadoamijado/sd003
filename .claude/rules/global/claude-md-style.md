---
description: CLAUDE.md スタイルガイド（200行以下・条件付きブロック規約）。CLAUDE.md編集時に適用。
paths:
  - "CLAUDE.md"
  - "**/CLAUDE.md.template"
---

# CLAUDE.md スタイルガイド（条件付きブロック規約）

## 原則

CLAUDE.mdは**200行以下**に保ち、条件付きブロック（When {条件}）で文脈を制御する。
詳細は `.claude/rules/` に委譲し、CLAUDE.mdは方針とルーティングのみを担う。

## 構造

```markdown
# プロジェクト名

## Always Active（常時適用・~50行）
  - セッション開始手順
  - 技術スタック概要
  - 最上位原則（Work First等）
  - ビルド・テストコマンド
  - ファイル安全ルール

## Conditional Context（条件付き・~80行）
  When {条件}, {ルール要約}. Details: {rules/パス}
  When {条件}, {ルール要約}. Details: {rules/パス}
  ...

## Quick Command Reference（参照・~20行）
  コマンド一覧テーブル

## フッター（バージョン・更新日）
```

## 条件付きブロックの書き方

### 構文
```
When {具体的な条件}, {守るべきルール}. Details: {詳細ファイルパス}
```

`IMPORTANT:` 等の強調は付けない。全ブロックに付けると強調が情報を失い、現行モデルでは過剰適用を招く。
強調は、実測で守られなかった1ルールに限って理由と一緒に付ける。

### 良い例（条件が狭く具体的）
```
When writing or modifying GAS code, use Env Interface Pattern.
When coordinating with other AIs, all documents go to `.sd/ai-coordination/`.
If a file operation involves Excel/CSV/PDF, check `.claude/skills/` first.
```

### 悪い例（条件が広すぎて常時発火 = 効果なし）
```
When you are writing code, follow best practices.
When working on this project, be careful.
```

## ルール

| ルール | 理由 |
|--------|------|
| CLAUDE.mdは200行以下 | 長すぎるとLLMが「流し読み」する |
| 詳細はrules/に委譲 | CLAUDE.mdはルーティングに徹する |
| 条件は狭く具体的に | 広い条件は常時発火し効果がない |
| 1ブロック = 1トピック | 複数トピックを混ぜない |
| Details:でパスを示す | LLMが必要時に自律的に読みに行ける |

## デプロイ時の適用

`/sd-deploy` でCLAUDE.mdテンプレートを生成する際、この規約に従う。
deploy.ps1のPhase 5でテンプレートから生成されるCLAUDE.mdは200行以下であること。
