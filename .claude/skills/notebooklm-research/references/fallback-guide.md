# NotebookLM フォールバックガイド（chrome-devtools MCP経由）

notebooklm-pyが故障した場合（GoogleのRPC変更、認証不能等）、chrome-devtools MCPでブラウザ操作する。

## 前提

- chrome-devtools MCPが接続済みであること
- Chromeで https://notebooklm.google.com/ にログイン済みであること

## 操作手順

### 1. NotebookLMを開く

```
mcp__chrome-devtools__navigate_page: https://notebooklm.google.com/
mcp__chrome-devtools__wait_for: networkIdle
```

### 2. ノートブック作成

```
mcp__chrome-devtools__click: [新しいノートブック作成ボタン]
mcp__chrome-devtools__wait_for: selector=".notebook-title-input"
mcp__chrome-devtools__fill: selector=".notebook-title-input", value="リサーチ名"
```

### 3. ソース追加

```
mcp__chrome-devtools__click: [ソース追加ボタン]
mcp__chrome-devtools__upload_file: [PDFファイルパス]
mcp__chrome-devtools__wait_for: selector=".source-item"  # アップロード完了待ち
```

### 4. チャット（RAGクエリ）

```
mcp__chrome-devtools__fill: selector="[チャット入力欄]", value="クエリ内容"
mcp__chrome-devtools__press_key: Enter
mcp__chrome-devtools__wait_for: selector=".chat-response"  # 回答待ち
mcp__chrome-devtools__evaluate_script: document.querySelector('.chat-response').textContent
```

## 注意事項

- NotebookLMのUI構造は頻繁に変わるため、セレクタは都度 `take_snapshot` で確認する
- 大量操作には不向き（1件ずつ手動操作のため）
- notebooklm-pyが復旧したら即座にAPI経由に戻すこと
- このガイドは最終手段。通常はnotebooklm-pyのGitHub Issuesで修正版を待つのが正解
