---
name: html-report
description: |
  人間向けの自己完結HTML文書を生成するスキル。要件定義書、仕様書、レビュー結果などを
  リッチなHTML + インラインCSS + 軽いインタラクションで出力する。
  Use when: 人間が読む文書をリッチに提示したい時。
  特に Blueprint Gate の要件定義書出力で使用。
allowed-tools: Read, Write, Edit
---

# HTML Report Skill

人間向け文書を自己完結HTMLで生成する。

## いつHTMLを使うか

| 場面 | HTML | 理由 |
|------|------|------|
| 要件定義書（Blueprint Gate出力） | ✅ | ユーザーが一覧性高く確認・編集する |
| レビュー結果の報告 | ✅ | スコア・指摘事項を視覚的に見せる |
| セッション概要の共有 | ✅ | 外部関係者にURLで渡せる |
| ステークホルダー向けの仕様書 | ✅ | 図解・テーブル・色分けが効く |

## いつmarkdownのままにするか

| 場面 | markdown | 理由 |
|------|----------|------|
| CLAUDE.md / AGENTS.md / SKILL.md | ✅ | AIが読む道具。差分管理の軽さ優先 |
| slash command の指示 | ✅ | 編集しやすい素の文章が適切 |
| 高頻度で更新する運用ドキュメント | ✅ | HTMLは差分ノイズが大きい |
| AI間の引き継ぎ（DONE.md等） | ✅ | AIが直接パースする |

## 生成手順

```
1. references/design-tokens.md を読み込む（CSS custom properties）
2. assets/report-template.html を読み込む（HTML構造）
3. コンテンツ（要件定義書等）をテンプレートのプレースホルダに注入
4. materials/html/ に保存
5. ユーザーにフルパスを案内
```

### プレースホルダ一覧

| プレースホルダ | 内容 | 例 |
|---------------|------|-----|
| `{{TITLE}}` | 文書タイトル | `at001 OCR機能` |
| `{{DOC_TYPE}}` | 文書種別 | `要件定義書` |
| `{{DATE}}` | 作成日 | `2026-05-10` |
| `{{SECTION_1_CONTENT}}` ~ `{{SECTION_6}}` | 各セクションの本文 | 要件定義書の各項目 |
| `{{VALIDATION_ITEM_N}}` | 検証観点のチェック項目 | `〇〇が動作すること` |

### コンテンツ注入時の変換ルール

- markdownの箇条書き → `<ul><li>` に変換
- markdownの太字 `**text**` → `<strong>text</strong>` に変換
- コードブロック → `<pre><code>` に変換
- テーブル → `<table class="data-table">` に変換
- 改行 → `<br>` に変換

### 保存先

| 文書種別 | 保存先 |
|---------|--------|
| 要件定義書 | `materials/html/{feature}-blueprint.html` |
| 仕様書 | `materials/html/{feature}-spec.html` |
| レビュー結果 | `materials/html/{case-id}-review.html` |
| セッション概要 | `materials/html/session-{YYYYMMDD}.html` |

## 読み戻し方法

ユーザーがHTMLを編集した後、AIが内容を読み戻す方法:

1. **Copy as Markdown ボタン**（推奨）: HTML内のボタンでMarkdownをクリップボードにコピー → ユーザーがClaude Codeにペースト
2. **ファイルRead**: ユーザーが保存したHTMLファイルをReadツールで読み取り、content from contenteditable divsをパース

## テンプレート拡張パターン

report-template.html はBlueprint Gateの要件定義書向け。
他の文書種別では、セクション構成を適宜変更する:

| 種別 | セクション構成 |
|------|---------------|
| 仕様書 | 背景 / 要件 / 技術設計 / データモデル / API / 非機能 |
| レビュー結果 | 概要 / スコア（テーブル） / 指摘事項 / 推奨対応 |
| セッション概要 | 作業内容 / 完了項目 / 未解決 / 次回タスク |

構成を変える際も design-tokens.md のCSS変数を共通で使用する。

## デザイン品質

生成するHTMLは `.claude/rules/ui/visual-review-checklist.md` の7項目で50/70以上を満たすこと:
- 視覚階層: セクション番号 + 見出しサイズ3段階
- 余白: 8pxグリッド準拠
- 色: accent 1色 + semantic 4色のみ
- タイポグラフィ: Noto Sans JP 1種、4段階サイズ
- 状態表現: チェックボックス（checked/unchecked）
- レスポンシブ: 768px以下でサイドバー非表示
- 印刷: Print stylesheet内蔵
