# Playwright ブラウザキャッシュ共有ルール

## 原則

> Playwright の Chromium バイナリは **全プロジェクトで `D:\playwright-browsers` を共有する**。
> プロジェクト直下に `.playwright-browsers` を作らない。

## 背景

Playwright の Chromium は 149MB。プロジェクトごとにダウンロードすると:

- ディスク浪費（プロジェクト数 × 149MB〜650MB）
- ダウンロード待ち時間
- ネットワーク帯域の無駄

実測値（2026-04-12）: cr001/oc001/ta001 の3プロジェクトだけで **1.85GB** のローカル複製が発生していた。

## 規約

### 正規パス（固定）

```
PLAYWRIGHT_BROWSERS_PATH=D:\playwright-browsers
```

- User環境変数として永続設定済み
- 全シェル・全プロジェクトで自動的に参照される

### 禁止事項

| 禁止 | 理由 |
|------|------|
| `$env:PLAYWRIGHT_BROWSERS_PATH = "...\{project}\.playwright-browsers"` | ローカル上書きは全プロジェクトで再DLを誘発 |
| `export PLAYWRIGHT_BROWSERS_PATH=...` をプロジェクト固有パスで設定 | 同上 |
| プロジェクト直下に `.playwright-browsers` ディレクトリを作る | 共有キャッシュを迂回する |
| `.env` / `.env.local` で `PLAYWRIGHT_BROWSERS_PATH` を上書き | 同上 |

### 許可

- `npx playwright install chromium` — パス指定なしで実行。自動的に `D:\playwright-browsers` に配置される
- `npx playwright install` — 同上
- `.claude/skills/gas-e2e/scripts/setup-e2e.ps1` や `setup-e2e.sh` — 既に正規パスを指定しており、defensive として機能

## 新規プロジェクトセットアップ手順

```bash
# シンプルにこれだけ。パス指定不要
npx playwright install chromium
```

既に `D:\playwright-browsers` にバイナリがあれば "chromium ... is already installed" と表示されてダウンロードは走らない。

## 想定外のダウンロードが発生した場合

1. 現在の環境変数を確認:
   ```bash
   powershell -Command "[Environment]::GetEnvironmentVariable('PLAYWRIGHT_BROWSERS_PATH', 'User')"
   ```
   `D:\playwright-browsers` が返らなければ `setx PLAYWRIGHT_BROWSERS_PATH "D:\playwright-browsers"` で修正

2. シェルに一時上書きが残っていないか確認:
   ```bash
   powershell -Command "echo $env:PLAYWRIGHT_BROWSERS_PATH"
   ```

3. プロジェクト直下に `.playwright-browsers` ができていたら削除し、`D:\playwright-browsers` に集約する

## 全AIモデル共通

このルールはClaude Code、Codex、Gemini CLI、Antigravity全てに適用される。
`.handoff/RULES.md` にも記載されている。
