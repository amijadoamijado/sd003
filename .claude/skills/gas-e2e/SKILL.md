---
name: gas-e2e
description: |
  GAS Web AppのE2Eテスト実行スキル。4つのモードを提供:
  Mode 1: claude-in-chrome（スクリーンショット・外観確認のみ。iframe内操作は不可）
  Mode 2: chrome-devtools-mcp（★推奨★ iframe内操作可能、Google認証済み、29ツール）
  Mode 3: connect_over_cdp（Playwright + 認証済みChromeプロファイル）
  Mode 4: persistent_context（Playwright単独、CI向け）
  Use when: GAS Web Appの画面確認、E2Eテスト、デプロイ後確認
allowed-tools: Bash, Read, Write, Glob, Grep, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__read_page, mcp__claude-in-chrome__find, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__form_input, mcp__claude-in-chrome__get_page_text, mcp__claude-in-chrome__javascript_tool, mcp__claude-in-chrome__read_console_messages, mcp__claude-in-chrome__read_network_requests, mcp__claude-in-chrome__gif_creator, mcp__claude-in-chrome__screenshot, mcp__claude-in-chrome__resize_window, mcp__claude-in-chrome__upload_image, mcp__chrome-devtools__navigate_page, mcp__chrome-devtools__new_page, mcp__chrome-devtools__list_pages, mcp__chrome-devtools__close_page, mcp__chrome-devtools__select_page, mcp__chrome-devtools__click, mcp__chrome-devtools__fill, mcp__chrome-devtools__fill_form, mcp__chrome-devtools__hover, mcp__chrome-devtools__drag, mcp__chrome-devtools__press_key, mcp__chrome-devtools__type_text, mcp__chrome-devtools__upload_file, mcp__chrome-devtools__take_screenshot, mcp__chrome-devtools__take_snapshot, mcp__chrome-devtools__evaluate_script, mcp__chrome-devtools__list_console_messages, mcp__chrome-devtools__get_console_message, mcp__chrome-devtools__list_network_requests, mcp__chrome-devtools__get_network_request, mcp__chrome-devtools__wait_for, mcp__chrome-devtools__handle_dialog, mcp__chrome-devtools__emulate, mcp__chrome-devtools__resize_page
---

# gas-e2e: GAS Web App E2Eテストスキル

## 概要

GAS Web AppのE2Eテストを安定実行するためのスキル。
Google認証が必要なGAS Web Appに対して、4つのモードで対応する。

## 🔧 事前インストール済み環境

| 項目 | パス |
|------|------|
| **Chromium** (Playwright用) | `D:\playwright-browsers\chromium-1194\chrome-win\chrome.exe` |
| **Chromium Headless Shell** | `D:\playwright-browsers\chromium_headless_shell-1194\` |
| **PLAYWRIGHT_BROWSERS_PATH** | `D:\playwright-browsers` |

**重要**: Mode 3/4でPlaywrightを使う場合は、必ず`PLAYWRIGHT_BROWSERS_PATH=D:/playwright-browsers`を設定すること。
Chromeが見つからないエラーが出た場合は`executablePath`でChromiumパスを直接指定する。

## 🚨 GAS Web App iframe制約（最重要 - 全モード共通知識）

**GAS Web Appは `script.googleusercontent.com` ドメインのsandbox iframe内でレンダリングされる。**
これにより以下の制約が発生する:

### iframe構造
```
script.google.com/macros/s/XXX/exec  （親ページ）
  └─ <iframe sandbox="allow-scripts allow-forms ...">
       src="script.googleusercontent.com/..."  （子iframe = アプリ本体）
```

### 制約一覧（検証済み・2026-03-10）
| 制約 | 影響 | 検証結果 |
|------|------|---------|
| **cross-origin iframe** | 親ページからiframe内DOMにアクセス不可 | `iframe.contentDocument` → null |
| **findツール無効** | アクセシビリティツリーにiframe内要素が出ない | ボタン・入力欄が見つからない |
| **座標クリック無効** | claude-in-chromeの座標クリックがiframe境界を越えない | クリックイベントが届かない |
| **JSインジェクション無効** | `javascript_tool`はトップフレームでのみ実行 | iframe内関数を呼べない |
| **`window.location.href` 無効** | iframe内でのページ遷移に使えない | `google.script.run` + `google.script.host.close()` を使う |
| **CORS差異** | `script.googleusercontent.com` は通常のGoogle APIとCORS設定が異なる | fetch先の設定に注意 |

### Mode別iframe対応能力
| 操作 | Mode 1 (claude-in-chrome) | Mode 2 (chrome-devtools) | Mode 3/4 (Playwright) |
|------|--------------------------|--------------------------|----------------------|
| スクリーンショット | ✅ | ✅ | ✅ |
| iframe外テキスト読み取り | ✅ | ✅ | ✅ |
| **iframe内テキスト読み取り** | ❌ | ✅ (snapshot) | ✅ (frame locator) |
| **iframe内ボタンクリック** | ❌ | ✅ (click uid) | ✅ (frame locator) |
| **iframe内フォーム入力** | ❌ | ✅ (fill uid) | ✅ (frame locator) |
| **iframe内ファイルアップロード** | ❌ | ✅ (upload_file) | ✅ (set_input_files) |
| **iframe内JS実行** | ❌ | ✅ (evaluate_script) | ✅ (frame.evaluate) |
| GIF記録 | ✅ | ❌ | ❌（別途ツール必要） |

### Mode 2でのiframe操作手順（推奨パターン）
```
Step 1: navigate_page → GAS URL
Step 2: wait_for → iframe読み込み完了を待機
Step 3: take_snapshot → iframe内を含むDOM全体を取得（uid付き）
Step 4: click/fill → uid指定でiframe内要素を操作
Step 5: take_screenshot → 証跡取得
```

**重要: `take_snapshot` がiframe内要素のuidも返す。これがMode 2の最大の利点。**

---

## ⚡ モード選択フローチャート（AIは必ずこれに従う）

```
E2Eテスト要求
    │
    ├─ iframe内の操作が必要？（ボタン、フォーム、ファイルアップロード）
    │   ├─ YES → Mode 1は使用不可 → Mode 2へ
    │   │         ├─ chrome-devtools MCP設定済み？
    │   │         │   ├─ YES → Mode 2で実行
    │   │         │   └─ NO  → Mode 2をインストールして実行
    │   │         └─ Mode 2失敗 → Mode 3へフォールバック
    │   │
    │   └─ NO（スクリーンショットのみ、外観確認のみ）
    │       └─ claude-in-chrome動作中？
    │           ├─ YES → Mode 1で実行
    │           └─ NO  → Mode 2で実行
    │
    └─ CI/CD環境 or ヘッドレス必須
        └─ Mode 4
```

**重要: iframe内操作 → Mode 2必須。Mode 1はスクリーンショット・外観確認のみ。**

---

## Mode 1: claude-in-chrome（スクリーンショット・外観確認専用）

**⚠️ GAS Web Appのiframe内操作は不可。スクリーンショット取得と外観確認のみ。**
**iframe内のボタン・フォーム・ファイルアップロードが必要な場合はMode 2を使うこと。**

### できること / できないこと
| できること | できないこと |
|-----------|-------------|
| GAS URLへのナビゲーション | iframe内ボタンクリック |
| スクリーンショット取得 | iframe内フォーム入力 |
| GIF記録（操作の証跡） | iframe内ファイルアップロード |
| 親ページのテキスト読み取り | iframe内テキスト読み取り |
| コンソールログ確認 | iframe内JS実行 |

### 実行手順（外観確認用）

```
Step 1: tabs_context_mcp でタブ状況確認
Step 2: tabs_create_mcp で新タブ作成
Step 3: navigate でGAS Web App URLにアクセス
Step 4: computer(screenshot) でスクリーンショット取得
Step 5: gif_creator で操作記録（必要に応じて）
※ iframe内の操作はMode 2に切り替えること
```

### ツール一覧

| ツール | 用途 |
|--------|------|
| `mcp__claude-in-chrome__tabs_context_mcp` | タブ状況確認（最初に必ず実行） |
| `mcp__claude-in-chrome__tabs_create_mcp` | 新タブ作成 |
| `mcp__claude-in-chrome__navigate` | URL遷移 |
| `mcp__claude-in-chrome__read_page` | ページ内容読み取り |
| `mcp__claude-in-chrome__get_page_text` | テキスト抽出 |
| `mcp__claude-in-chrome__find` | 要素検索 |
| `mcp__claude-in-chrome__computer` | クリック・入力操作 |
| `mcp__claude-in-chrome__form_input` | フォーム入力 |
| `mcp__claude-in-chrome__javascript_tool` | JS実行 |
| `mcp__claude-in-chrome__read_console_messages` | コンソールログ確認 |
| `mcp__claude-in-chrome__read_network_requests` | ネットワーク確認 |
| `mcp__claude-in-chrome__gif_creator` | 操作のGIF記録 |
| `mcp__claude-in-chrome__upload_image` | ファイルアップロード |

### 特徴
- セットアップ不要（claude-in-chrome拡張が動作中であれば即使用可能）
- Google認証は既存Chromeセッションで突破済み
- スクリーンショット取得・GIF記録に最適
- **⚠️ iframe内操作は一切不可（GAS Web App固有の制約）**

### トラブルシューティング
| 症状 | 対処 |
|------|------|
| tabs_context_mcp がエラー | Chrome拡張が停止 → Mode 2にフォールバック |
| navigate後に空白ページ | GAS URLが間違っている → deployments確認 |
| Google認証画面が出る | 別プロファイルで開いている → 通常プロファイルを確認 |
| **findでボタンが見つからない** | **iframe制約 → Mode 2に切り替え（Mode 1では解決不可）** |
| **座標クリックが効かない** | **iframe制約 → Mode 2に切り替え（Mode 1では解決不可）** |
| **javascript_toolでcross-origin** | **iframe制約 → Mode 2に切り替え（Mode 1では解決不可）** |

---

## Mode 2: chrome-devtools-mcp（★GAS E2E推奨★）

**Google公式のChrome DevTools MCPサーバー。29ツール搭載。iframe内操作可能。**

### 🚨 もたつき防止ルール（AIは厳守）

**以下の行動は禁止。全てMode 2では不要:**
| 禁止行動 | 理由 |
|---------|------|
| `--remote-debugging-port=9222` でChrome起動 | **autoConnectでは不要** |
| `Stop-Process -Name chrome` でChrome終了 | **autoConnectでは不要、ユーザーの作業を壊す** |
| プロファイルコピー (`cp -r "User Data"`) | **autoConnectでは不要、5分以上かかる** |
| `curl localhost:9222/json/version` で接続確認 | **autoConnectでは不要** |
| DevToolsActivePort ファイルの確認 | **autoConnectでは不要** |
| Chrome閉じてよいか確認 | **autoConnectでは不要** |

**autoConnect = Chromeに一切触らない。既存のChromeにそのまま接続する。**

### 接続方式: autoConnect（唯一の推奨方式）

**前提条件（初回のみ1回だけ設定）:**
1. Chrome **144以上**であること（現環境: 145 ✅）
2. Chromeで `chrome://inspect/#remote-debugging` を開く
3. リモートデバッグ接続を有効にする（UIの指示に従う）
4. MCP接続時にChromeが許可ダイアログを表示 → 許可する

**⚠️ `chrome://flags` は一切関係ない。`chrome://inspect` のページで設定する。**
**⚠️ `--remote-debugging-port` は一切不要。autoConnectはChrome M144の新しい接続方式を使う。**

### MCP設定

```bash
# インストール（初回のみ）
claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp@latest --autoConnect --no-usage-statistics
```

**Note**: `--executable-path`は不要。autoConnectは既存のChromeに接続するため新しいブラウザを起動しない。

### 3つの接続方式の比較（検証済み 2026-03-10）

| 方式 | フラグ | `--remote-debugging-port`? | `chrome://inspect` 設定? | Chrome版数 |
|------|--------|--------------------------|-------------------------|-----------|
| **autoConnect（推奨）** | `--autoConnect` | **不要** | **必要**（初回のみ） | **144+** |
| manual port | `--browserUrl http://127.0.0.1:9222` | **必要**（認証デッドロック問題あり） | 不要 | 任意 |
| WebSocket | `--wsEndpoint <url>` | 対象による | 不要 | 任意 |

### ⚠️ 接続方式の注意点（検証済み）
- `chrome://inspect/#remote-debugging` が開くポート9222は **従来のCDP HTTP APIではない**
- `/json/version` や `/json` エンドポイントは404を返す
- したがって `--browserUrl http://127.0.0.1:9222` では接続**できない**
- **`--autoConnect` 専用**の接続方式であり、MCP側がこの新方式に対応している必要がある
- **MCP再登録後は新しいClaude Codeセッションで起動が必要**（現セッションでは反映されない）

### 接続失敗時の対処（AIは上から順に試す）

```
list_pages がエラー（"Could not find DevToolsActivePort"）
    │
    ├─ Step 1: 「chrome://inspect/#remote-debugging でリモートデバッグを有効にしてください」
    │   └─ ユーザーが設定 → 再試行
    │
    ├─ Step 2: Chrome再起動が必要かも → 「Chrome再起動してください」と依頼
    │   └─ ユーザーが再起動 → 再試行
    │
    ├─ Step 3: 接続時に許可ダイアログが出る → 「許可してください」と依頼
    │
    └─ Step 4: 上記で解決しない → Mode 3にフォールバック（最終手段）
```

**⛔ AIが勝手にChromeを閉じる・再起動するのは禁止。ユーザーに依頼する。**

### ツール一覧（29ツール）

**入力操作:**
| ツール | 用途 |
|--------|------|
| `click` | 要素クリック（uid指定） |
| `fill` | テキスト入力・セレクト選択 |
| `fill_form` | 複数フォーム一括入力 |
| `hover` | ホバー |
| `drag` | ドラッグ&ドロップ |
| `press_key` | キー入力（ショートカット対応） |
| `type_text` | テキストタイプ |
| `upload_file` | ファイルアップロード |
| `handle_dialog` | ダイアログ処理（accept/dismiss） |

**ナビゲーション:**
| ツール | 用途 |
|--------|------|
| `navigate_page` | URL遷移 |
| `new_page` | 新規ページ |
| `list_pages` | ページ一覧 |
| `select_page` | ページ切替 |
| `close_page` | ページ閉じ |
| `wait_for` | 条件待機 |

**デバッグ:**
| ツール | 用途 |
|--------|------|
| `take_screenshot` | スクリーンショット |
| `take_snapshot` | DOMスナップショット（uid付き） |
| `evaluate_script` | JS実行 |
| `list_console_messages` | コンソールメッセージ一覧 |
| `get_console_message` | コンソールメッセージ詳細 |
| `list_network_requests` | ネットワークリクエスト一覧 |
| `get_network_request` | ネットワークリクエスト詳細 |

**パフォーマンス・エミュレーション:**
| ツール | 用途 |
|--------|------|
| `emulate` | デバイスエミュレーション |
| `resize_page` | ページリサイズ |
| `performance_start_trace` | パフォーマンストレース開始 |
| `performance_stop_trace` | トレース停止 |
| `performance_analyze_insight` | パフォーマンス分析 |
| `take_memory_snapshot` | メモリスナップショット |
| `lighthouse_audit` | Lighthouseオーディット |

### 特徴
- **Google公式（ChromeDevTools org）**
- `--autoConnect` で既存Chrome（認証済み）にそのまま接続
- ダイアログ処理対応（claude-in-chromeの弱点を補完）
- パフォーマンス分析・Lighthouse内蔵
- puppeteer ベースで安定した自動化

### GAS E2E実行手順

```
Step 1: take_snapshot でページ状態取得（uid一覧取得）
Step 2: navigate_page でGAS URLにアクセス
Step 3: take_snapshot で画面要素確認
Step 4: click / fill / fill_form で操作（uid指定）
Step 5: wait_for で画面遷移を待機
Step 6: take_screenshot で証跡取得
```

---

## Mode 3: connect_over_cdp（Playwright接続）

**スクリプト制御が必要な場合のフォールバック。**

### ⚠️ Chrome制約（重要）

Chromeのデフォルトプロファイルは `--remote-debugging-port` を**無視する**。
以下のエラーが出る:
```
DevTools remote debugging requires a non-default data directory.
Specify this using --user-data-dir.
```

**→ `--user-data-dir` を指定すると新プロファイル（認証なし）になるデッドロック問題がある。**

### 解決策: デフォルトプロファイルをコピーして使用

```powershell
# Step 1: Chromeを完全に閉じる
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Start-Sleep 3

# Step 2: デフォルトプロファイルをコピー（初回のみ）
$src = "$env:LOCALAPPDATA\Google\Chrome\User Data"
$dst = "D:\playwright-browsers\chrome-debug-profile"
if (-not (Test-Path $dst)) {
    Copy-Item $src $dst -Recurse
}

# Step 3: コピーしたプロファイルでChromeを起動
& "C:\Program Files\Google\Chrome\Application\chrome.exe" `
    --remote-debugging-port=9222 `
    --user-data-dir="D:\playwright-browsers\chrome-debug-profile"
```

### AIの自律実行手順

```bash
# Step 1: Chromeプロセスを終了
powershell.exe -Command "Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue"
sleep 3

# Step 2: プロファイルコピー（初回のみ）
SRC="$LOCALAPPDATA/Google/Chrome/User Data"
DST="D:/playwright-browsers/chrome-debug-profile"
if [ ! -d "$DST" ]; then
    cp -r "$SRC" "$DST"
fi

# Step 3: コピーしたプロファイルでChromium起動（Chromeでも可）
# Chromium（事前インストール済み）を使用
"D:/playwright-browsers/chromium-1194/chrome-win/chrome.exe" \
    --remote-debugging-port=9222 \
    --user-data-dir="D:/playwright-browsers/chrome-debug-profile" &
# または Chrome: "/c/Program Files/Google/Chrome/Application/chrome.exe" \
#     --remote-debugging-port=9222 --user-data-dir="D:/playwright-browsers/chrome-debug-profile" &

# Step 4: 接続確認（最大3回リトライ）
for i in 1 2 3; do
    sleep 3
    if curl -s http://localhost:9222/json/version > /dev/null 2>&1; then
        echo "CDP接続成功"
        break
    fi
    echo "リトライ $i/3..."
done
```

### Playwrightスクリプト

```typescript
import { chromium } from 'playwright';

const browser = await chromium.connectOverCDP('http://localhost:9222');
const context = browser.contexts()[0];
const page = context.pages()[0] || await context.newPage();

await page.goto('https://script.google.com/macros/s/XXXX/exec');
// コピーしたプロファイルの認証情報を利用
```

### 注意事項
- **プロファイルコピーは時間がかかる（数GB）** → 初回のみ
- コピー後にデフォルトChromeを使うとプロファイルが古くなる → 定期的に再コピー
- ユーザーの通常Chrome利用を中断する（Chromeを閉じる必要がある）
- **Mode 1/2で済む場合はMode 1/2を使うこと**

---

## Mode 4: persistent_context（CI向け）

**CI/CD環境向け。専用プロファイルでGoogle認証を保持。**

### 初回セットアップ

```bash
npm run e2e:setup
```

これにより以下が実行される:
1. Playwright Chromiumブラウザのインストール
2. 専用E2Eプロファイルディレクトリの作成（`D:\playwright-browsers\gas-e2e-profile\`）

### 初回のみ: Googleログイン

```typescript
import { chromium } from 'playwright';

// 事前インストール済みChromiumを使用（Chromeインストール不要）
const CHROMIUM_PATH = 'D:\\playwright-browsers\\chromium-1194\\chrome-win\\chrome.exe';

const context = await chromium.launchPersistentContext(
  'D:\\playwright-browsers\\gas-e2e-profile',
  { executablePath: CHROMIUM_PATH, headless: false }
);
const page = context.pages()[0];
await page.goto('https://accounts.google.com');
// 手動でGoogleアカウントにログイン
// 以降、セッションは保持される
```

### 2回目以降

```typescript
const CHROMIUM_PATH = 'D:\\playwright-browsers\\chromium-1194\\chrome-win\\chrome.exe';

const context = await chromium.launchPersistentContext(
  'D:\\playwright-browsers\\gas-e2e-profile',
  { executablePath: CHROMIUM_PATH }
);
// Google認証済みの状態で開始
```

### 注意事項
- **Chrome閉じた状態で実行必須**（SingletonLock回避）
- 初回のみ手動Googleログインが必要
- プロファイルが破損した場合はディレクトリを削除して再ログイン

---

## モード比較表

| 項目 | Mode 1 | Mode 2 ★推奨 | Mode 3 | Mode 4 |
|------|--------|--------|--------|--------|
| **方式** | claude-in-chrome | chrome-devtools-mcp | Playwright CDP | Playwright persistent |
| **セットアップ** | 不要 | MCP追加のみ | プロファイルコピー | npm run e2e:setup |
| **Google認証** | 既存セッション | autoConnectで既存 | コピーしたプロファイル | 手動ログイン |
| **Chrome閉じる必要** | なし | なし | **あり** | **あり** |
| **ツール数** | 13 | **29** | Playwright全機能 | Playwright全機能 |
| **GAS iframe内操作** | **❌ 不可** | **✅ 可能** | **✅ 可能** | **✅ 可能** |
| **ダイアログ処理** | 不可 | **可能** | 可能 | 可能 |
| **パフォーマンス分析** | なし | **あり** | なし | なし |
| **ヘッドレス** | 不可 | 可能 | 可能 | **可能** |
| **AI自律度** | 高（外観のみ） | **高（全操作）** | 中 | 低 |

## フォールバックフロー（AIは必ず従う）

```
E2Eテスト要求
    │
    ├─ iframe内操作が必要？（ほぼ常にYES）
    │   │
    │   ├─ YES → Mode 2 (chrome-devtools-mcp) を試行 ★ここから開始
    │   │   ├─ MCP設定済み → autoConnect で接続 → テスト実行 ✓
    │   │   └─ MCP未設定 → インストール → テスト実行 ✓
    │   │
    │   └─ Mode 2 失敗
    │       │
    │       ├─ Mode 3 へフォールバック
    │       │   ├─ プロファイルコピー済み → Chrome起動 → テスト実行 ✓
    │       │   └─ 未コピー → コピー実行 → Chrome起動 → テスト実行 ✓
    │       │
    │       └─ ⛔ 3回以上のリトライ禁止 → ユーザーに状況報告
    │
    └─ NO（スクリーンショットのみ）
        └─ Mode 1 (claude-in-chrome) で実行
```

**禁止事項:**
- Chrome起動を5回以上リトライする
- ユーザーに手動操作を3回以上依頼する
- 失敗原因を特定せずにリトライする
- Mode 3/4を最初に選ぶ（Mode 1/2を先に試すこと）

## セットアップ

```bash
# Mode 1: セットアップ不要（claude-in-chrome拡張のみ）

# Mode 2: chrome-devtools-mcp インストール
claude mcp add chrome-devtools --scope user -- npx chrome-devtools-mcp@latest --autoConnect --no-usage-statistics

# Mode 3/4: Playwrightブラウザとプロファイルの初期セットアップ
npm run e2e:setup
```

## 関連スキル

| スキル | 用途 |
|--------|------|
| `webapp-testing` | ローカルWeb AppのE2Eテスト（Anthropic公式） |
| `playwright-e2e-testing` | Playwright汎用E2Eテスト |
