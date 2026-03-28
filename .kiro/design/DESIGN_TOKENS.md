# デザイントークン

## 概要

プロジェクトのカラー・フォント・余白・ボーダー等のデザイン変数を定義する。
CSS custom properties（`:root { ... }`）にそのまま貼れる形式。

**初回セットアップ**: カラーパレットのprimary/accentだけ変更すれば使える。

---

## カラーパレット

```css
:root {
  /* --- Brand --- */
  --color-primary: #2563eb;      /* Blue 600 — メインブランドカラー ★ここを変更 */
  --color-primary-light: #3b82f6; /* Blue 500 — hover状態等 */
  --color-primary-dark: #1d4ed8;  /* Blue 700 — active状態等 */
  --color-accent: #2563eb;        /* 差し色（原則1色 = primaryと同じ）★必要なら変更 */

  /* --- Semantic --- */
  --color-success: #16a34a;  /* Green 600 */
  --color-warning: #ca8a04;  /* Yellow 600 */
  --color-error: #dc2626;    /* Red 600 */
  --color-info: #2563eb;     /* Blue 600 */

  /* --- Neutral (Gray Scale) --- */
  --color-bg: #ffffff;           /* 背景 */
  --color-bg-secondary: #f9fafb; /* 背景（セカンダリ） */
  --color-surface: #ffffff;      /* カード・パネル背景 */
  --color-border: #e5e7eb;       /* ボーダー (Gray 200) */
  --color-border-strong: #d1d5db; /* 強調ボーダー (Gray 300) */
  --color-text: #111827;         /* テキスト (Gray 900) */
  --color-text-secondary: #6b7280; /* 補助テキスト (Gray 500) */
  --color-text-muted: #9ca3af;   /* 薄いテキスト (Gray 400) */
  --color-text-on-primary: #ffffff; /* primary背景上のテキスト */
}
```

## タイポグラフィ

```css
:root {
  /* --- Font Family --- */
  --font-sans: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  --font-mono: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace;

  /* --- Font Size Scale (4段階) --- */
  --text-xs: 0.75rem;   /* 12px — 注釈、キャプション */
  --text-sm: 0.875rem;  /* 14px — 補助テキスト */
  --text-base: 1rem;    /* 16px — 本文 */
  --text-lg: 1.125rem;  /* 18px — 小見出し */
  --text-xl: 1.5rem;    /* 24px — セクション見出し */
  --text-2xl: 2rem;     /* 32px — ページタイトル */

  /* --- Line Height --- */
  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  /* --- Font Weight --- */
  --font-normal: 400;
  --font-medium: 500;
  --font-bold: 700;
}
```

## スペーシング（8px Grid）

```css
:root {
  --space-1: 0.25rem;  /*  4px — 密接な要素間 */
  --space-2: 0.5rem;   /*  8px — 関連要素間 */
  --space-3: 0.75rem;  /* 12px — 軽い分離 */
  --space-4: 1rem;     /* 16px — 標準の分離 */
  --space-6: 1.5rem;   /* 24px — セクション内の区切り */
  --space-8: 2rem;     /* 32px — セクション間の分離 */
  --space-12: 3rem;    /* 48px — 大きな区切り */
  --space-16: 4rem;    /* 64px — ページセクション間 */
}
```

## ボーダー・シャドウ

```css
:root {
  /* --- Border Radius --- */
  --radius-sm: 0.25rem;  /* 4px */
  --radius-md: 0.5rem;   /* 8px */
  --radius-lg: 0.75rem;  /* 12px */
  --radius-full: 9999px; /* 円形 */

  /* --- Box Shadow --- */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}
```

## ブレークポイント

```css
/* デスクトップファースト（業務用途） */
/* @media (max-width: 1024px) { ... }  — lg以下 */
/* @media (max-width: 768px)  { ... }  — md以下（主要折り返し） */
/* @media (max-width: 640px)  { ... }  — sm以下 */
```

---

## 初回セットアップ手順

1. このファイルをコピーして編集する
2. `--color-primary` をプロジェクトのブランドカラーに変更
3. 必要に応じて `--color-accent` を設定（primaryと別の差し色を使う場合のみ）
4. HTMLの `<style>` タグ内、または外部CSSファイルの先頭に `:root { ... }` を貼り付ける
5. CSSで `var(--color-primary)`, `var(--space-4)` 等で参照する

## Tailwind CSS との対応

Tailwind CSS CDNを使う場合は、以下のように `tailwind.config` で上書きする:

```html
<script>
  tailwind.config = {
    theme: {
      extend: {
        colors: {
          primary: 'var(--color-primary)',
          accent: 'var(--color-accent)',
        }
      }
    }
  }
</script>
```

## ダークモード（オプション）

ダークモード対応が必要な場合は、`:root` の値を `[data-theme="dark"]` で上書きする。
デフォルトでは未対応（業務用途ではライトモードのみが一般的）。
