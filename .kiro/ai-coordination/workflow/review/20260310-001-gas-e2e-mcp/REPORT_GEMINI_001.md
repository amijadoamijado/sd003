# Gemini CLI 調査報告 - 20260310-001-gas-e2e-mcp

## 調査日時
2026-03-10

## 調査結果

### Task 1: autoConnect接続フロー
- `autoConnect`はDevToolsActivePortを正常に読み取りWSURL構築する
- Chrome 144+の新仕様で初回デバッグ接続時に**許可ダイアログ**が表示される
- ダイアログ未承認→CDPコマンド(Network.enable等)がレスポンスを返さない→タイムアウト

### Task 3: /json/version 404の理由
- **仕様**。Chrome 144+ではHTTPベースのディスカバリを無効化、WebSocket一本化
- curl等による接続確認は不可能
- `--browserUrl` 方式は使用不可（HTTPエンドポイントがないため）

### Task 4: 動作する設定
```bash
npx -y chrome-devtools-mcp@latest --autoConnect --no-usage-statistics
```

### エラーパターンと対処
| エラー | 原因 | 対処 |
|--------|------|------|
| DevToolsActivePort not found | プロファイルパス不一致 | --userDataDir明示 or チャンネル確認 |
| Network.enable timed out | Chrome許可ダイアログ未承認 | Chromeで許可ダイアログを承認 |
| /json/version 404 | 新仕様HTTP無効化 | 仕様。--autoConnectのみ使用 |

## 実行環境
- Gemini CLI (Restricted Mode - 読み取り専用)
- shell実行は不可だったため、コード解析・ドキュメント調査のみ
