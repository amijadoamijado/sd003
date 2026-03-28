# 実装指示書 IMPLEMENT_REQUEST_001

## 案件情報
- **案件ID**: 20260310-001-gas-e2e-mcp
- **依頼元**: Claude Code
- **依頼先**: Gemini CLI
- **種別**: 調査・検証
- **優先度**: P0

## 調査目的

chrome-devtools-mcp の `--autoConnect` がGAS Web App E2Eテストで正常に接続できない問題の根本原因を特定し、動作する設定を確立する。

## 背景・現状

### 環境
- Windows 11
- Chrome 145.0.7632.118
- Node.js 22.17.1
- chrome-devtools-mcp v0.19.0（npx経由）
- Claude Code からMCP経由で使用

### 判明している事実

1. **DevToolsActivePort ファイルは存在する**
   - パス: `C:\Users\a-odajima\AppData\Local\Google\Chrome\User Data\DevToolsActivePort`
   - 中身: `9222\n/devtools/browser/991eafa3-5d07-4e0f-962f-01efa792c07b`
   - `chrome://inspect/#remote-debugging` 有効化で生成された

2. **autoConnectの実装（ソースコード確認済み）**
   - `server.js` → `ensureBrowserConnected()` → `puppeteer.connect({ channel: "chrome" })`
   - Puppeteerが `resolveDefaultUserDataDir()` → `%LOCALAPPDATA%\Google\Chrome\User Data`
   - DevToolsActivePort読む → WSURLを構築 → 接続

3. **発生するエラー**
   - Case A: `Could not find DevToolsActivePort` → ファイルが無い時
   - Case B: `Network.enable timed out` → ファイルあるがポートが応答しない時

4. **ポート9222の挙動**
   - `chrome://inspect` が開くポート9222は従来のCDP HTTP APIではない
   - `/json/version` → 404（CDPならJSONが返るはず）
   - `--browserUrl http://127.0.0.1:9222` → 接続不可

5. **根本的な疑問**
   - `chrome://inspect/#remote-debugging` で有効化されるデバッグ接続と、DevToolsActivePortに書かれたWSエンドポイントは同じものか？
   - Puppeteerの `connect({ channel: "chrome" })` は実際にどのプロトコルで接続するのか？

## 調査タスク

### Task 1: chrome-devtools-mcp の接続フローを実際にテスト
```bash
# 1. Chrome が起動中 + chrome://inspect 有効の状態で
npx -y chrome-devtools-mcp@latest --autoConnect --no-usage-statistics
# → 何が起こるか、エラー出力を全て記録
```

### Task 2: DevToolsActivePortのWSエンドポイントに直接接続テスト
```javascript
// DevToolsActivePortから読んだWSURLに直接接続
const puppeteer = require('puppeteer-core');
const browser = await puppeteer.connect({
  browserWSEndpoint: 'ws://127.0.0.1:9222/devtools/browser/xxx'
});
// → 接続できるか？
```

### Task 3: /json/version が404を返す理由の調査
```bash
curl -v http://127.0.0.1:9222/json/version
# CDPなら {"Browser":"Chrome/145..."} が返るはず
# 404が返る理由は？chrome://inspect が開くポートの正体は？
```

### Task 4: 正常に接続できる設定の確立
上記調査結果をもとに、GAS Web Appに対してchrome-devtools-mcpが正常に接続できる設定を確立する。

## 成果物

1. **調査報告**: 各Taskの結果と判明した事実
2. **動作する設定**: chrome-devtools-mcp の正しい接続コマンド
3. **スキル更新案**: `.claude/skills/gas-e2e/SKILL.md` に反映すべき正確な情報

## 参照ファイル

| ファイル | 内容 |
|---------|------|
| `.claude/skills/gas-e2e/SKILL.md` | 現在のE2Eテストスキル（更新対象） |
| `C:\Users\a-odajima\AppData\Local\npm-cache\_npx\15c61037b1978c83\node_modules\chrome-devtools-mcp\build\src\browser.js` | autoConnect実装 |
| `C:\Users\a-odajima\AppData\Local\npm-cache\_npx\15c61037b1978c83\node_modules\chrome-devtools-mcp\build\src\server.js` | MCP起動ロジック |

## 注意事項

- **Chromeを勝手に閉じないこと**（ユーザーの作業に影響）
- **clasp deploy は禁止**（push のみ許可）
- 調査結果は `.kiro/ai-coordination/workflow/review/20260310-001-gas-e2e-mcp/` に保存
