---
name: gas-e2e
description: |
  GAS Web AppのE2Eテスト実行スキル。3つのモードを提供:
  Mode 1: claude-in-chrome（推奨、Google認証済み）
  Mode 2: connect_over_cdp（Playwright + 認証済みChrome）
  Mode 3: persistent_context（Playwright単独、CI向け）
  Use when: GAS Web Appの画面確認、E2Eテスト、デプロイ後確認
allowed-tools: Bash, Read, Write, Glob, Grep
---

# gas-e2e: GAS Web App E2Eテストスキル

## 概要

GAS Web AppのE2Eテストを安定実行するためのスキル。
Google認証が必要なGAS Web Appに対して、3つのモードで対応する。

---

## Mode 1: claude-in-chrome（推奨）

**最速・最安定。Google認証済みChromeセッションをそのまま利用。**

### 使い方

1. `mcp__claude-in-chrome__tabs_context_mcp` で現在のタブ状況を確認
2. `mcp__claude-in-chrome__tabs_create_mcp` で新タブ作成
3. `mcp__claude-in-chrome__navigate` でGAS Web App URLにアクセス
4. `mcp__claude-in-chrome__read_page` で画面内容を確認
5. `mcp__claude-in-chrome__find` で要素を検索
6. `mcp__claude-in-chrome__computer` でクリック・入力操作

### 特徴
- セットアップ不要（claude-in-chrome拡張が動作中であれば即使用可能）
- Google認証は既存Chromeセッションで突破済み
- スクリーンショット取得可能
- フォーム入力・ボタンクリック等のインタラクション対応

### 適用場面
- GAS Web Appの画面目視確認
- デプロイ後の動作確認
- フォーム入力・ボタン操作のE2Eテスト
- Google認証が必要なページの確認

---

## Mode 2: connect_over_cdp（Playwright接続）

**スクリプト制御が必要な場合に使用。認証済みChromeに接続。**

### 前提条件

Chromeを `--remote-debugging-port=9222` で起動済みであること:

```powershell
# PowerShell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
```

### 使い方（Playwrightスクリプト）

```typescript
import { chromium } from 'playwright';

const browser = await chromium.connectOverCDP('http://localhost:9222');
const context = browser.contexts()[0];
const page = context.pages()[0] || await context.newPage();

await page.goto('https://script.google.com/macros/s/XXXX/exec');
// 既存セッションのcookie/認証をそのまま利用
```

### 特徴
- 既存Chromeセッションの認証情報をそのまま利用
- Playwrightのフルスクリプト制御が可能
- 複雑なテストシナリオの自動化に適する

### 注意事項
- Chrome使用中に接続するとSingletonLock問題は発生しない
- ただしユーザーの操作と競合する可能性がある

---

## Mode 3: persistent_context（CI向け）

**CI/CD環境向け。専用プロファイルでGoogle認証を保持。**

### 初回セットアップ

```bash
npm run e2e:setup
```

これにより以下が実行される:
1. Playwright Chromiumブラウザのインストール
2. 専用E2Eプロファイルディレクトリの作成（`F:\playwright-browsers\gas-e2e-profile\`）

### 初回のみ: Googleログイン

```typescript
import { chromium } from 'playwright';

const context = await chromium.launchPersistentContext(
  'F:\\playwright-browsers\\gas-e2e-profile',
  { channel: 'chrome', headless: false }
);
const page = context.pages()[0];
await page.goto('https://accounts.google.com');
// 手動でGoogleアカウントにログイン
// 以降、セッションは保持される
```

### 2回目以降

```typescript
const context = await chromium.launchPersistentContext(
  'F:\\playwright-browsers\\gas-e2e-profile',
  { channel: 'chrome' }
);
// Google認証済みの状態で開始
```

### 注意事項
- **Chrome閉じた状態で実行必須**（SingletonLock回避）
- 初回のみ手動Googleログインが必要
- プロファイルが破損した場合はディレクトリを削除して再ログイン

---

## モード選択ガイド

| 目的 | 推奨モード | 理由 |
|------|-----------|------|
| GAS画面の目視確認 | Mode 1 (claude-in-chrome) | セットアップ不要、最速 |
| GASフローの自動テスト | Mode 2 (connect_over_cdp) | スクリプト制御 + 認証済み |
| CI/CD自動テスト | Mode 3 (persistent_context) | ヘッドレス実行可能 |
| ローカルWeb App | webapp-testing スキル | Google認証不要のため別スキル |

## セットアップ

```bash
# Playwrightブラウザとプロファイルの初期セットアップ（Mode 2/3用）
npm run e2e:setup

# Mode 1はセットアップ不要（claude-in-chrome拡張のみ）
```

## 関連スキル

| スキル | 用途 |
|--------|------|
| `webapp-testing` | ローカルWeb AppのE2Eテスト（Anthropic公式） |
| `playwright-e2e-testing` | Playwright汎用E2Eテスト |
