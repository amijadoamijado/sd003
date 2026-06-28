# HTML Report Design Tokens

Claude CodeがHTML生成時にインライン展開するCSS設計トークン。
`.claude/rules/ui/web-design-principles.md` の8原則に準拠。

## CSS Custom Properties

```css
:root {
  /* Colors */
  --accent: #2563eb;
  --accent-light: #dbeafe;
  --success: #16a34a;
  --success-light: #dcfce7;
  --warning: #ca8a04;
  --warning-light: #fef9c3;
  --error: #dc2626;
  --error-light: #fee2e2;
  --info: #2563eb;
  --info-light: #dbeafe;

  /* Text */
  --text-primary: #1e293b;
  --text-secondary: #64748b;
  --text-supplementary: #94a3b8;

  /* Background */
  --bg: #ffffff;
  --bg-section: #f8fafc;
  --bg-sidebar: #f1f5f9;
  --bg-code: #f8fafc;

  /* Border */
  --border: #e2e8f0;
  --border-focus: #2563eb;

  /* Spacing (8px grid) */
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-6: 24px;
  --space-8: 32px;
  --space-12: 48px;

  /* Typography */
  --font-body: 'Noto Sans JP', 'Hiragino Sans', sans-serif;
  --font-heading: 'Noto Sans JP', 'Hiragino Sans', sans-serif;
  --font-mono: 'JetBrains Mono', 'Consolas', monospace;

  --text-xs: 12px;
  --text-sm: 14px;
  --text-base: 16px;
  --text-lg: 20px;
  --text-xl: 24px;
  --text-2xl: 30px;

  --weight-normal: 400;
  --weight-medium: 500;
  --weight-bold: 700;

  --leading-tight: 1.25;
  --leading-normal: 1.6;
  --leading-relaxed: 1.8;

  /* Layout */
  --sidebar-width: 240px;
  --max-content: 960px;
  --radius: 6px;

  /* Print */
  --print-margin: 20mm;
}
```

## Font Loading

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap" rel="stylesheet">
```

## 使用ルール

| ルール | 値 |
|--------|-----|
| フォント最大数 | 1種類（Noto Sans JP） |
| 差し色 | 1色（--accent） |
| セマンティック色 | 4色固定（success/warning/error/info） |
| フォントサイズ | 4段階（base/lg/xl/2xl） |
| フォントウェイト | 3段階（400/500/700） |
| 余白 | 8pxグリッド準拠 |

## セマンティック色の用途

| 色 | 用途 | 例 |
|----|------|-----|
| success | 完了・合格・承認 | チェックマーク、達成項目 |
| warning | 注意・保留・確認待ち | 未確認項目、制約事項 |
| error | エラー・不合格・却下 | 必須項目不足、検証失敗 |
| info | 参考・注記・リンク | 補足情報、外部参照 |
