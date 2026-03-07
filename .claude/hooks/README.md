# SD003 Hooks

Claude Code公式hooks形式でRalph Loopを実装。

## ファイル構成

| ファイル | 用途 | 環境 |
|---------|------|------|
| `sd003-stop-hook.ps1` | Midpoint用: テスト成功までループ | Windows |
| `sd003-stop-hook-endgame.ps1` | Endgame用: 同一エラー2回でエスカレート | Windows |
| `sd003-stop-hook.sh` | Midpoint用 | Linux/Mac |
| `sd003-stop-hook-endgame.sh` | Endgame用 | Linux/Mac |

## 使い方

### 手動切り替え

`.claude/settings.json` の `hooks.Stop[0].hooks[0].command` を変更:

```json
// Midpoint (Windows)
"command": "powershell -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR\\.claude\\hooks\\sd003-stop-hook.ps1\""

// Endgame (Windows)
"command": "powershell -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR\\.claude\\hooks\\sd003-stop-hook-endgame.ps1\""

// Midpoint (Linux/Mac)
"command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/sd003-stop-hook.sh\""

// Endgame (Linux/Mac)
"command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/sd003-stop-hook-endgame.sh\""
```

## 動作仕様

### Midpoint Hook
- テスト成功マーカー検出 → 停止許可
- テスト失敗検出 → ループ継続
- 最大20回まで自動リトライ

### Endgame Hook
- テスト成功 → 停止許可、エラーログクリア
- エラー1回目 → ログ記録、1回だけ再試行許可
- エラー2回目（同一パターン） → /dialogue-resolutionへエスカレート

## エラーログ

`.error-patterns.log` にエラーパターンを記録（.gitignore済み）。
テスト成功時に自動クリア。

## 注意事項

- Windows: PowerShell 5.1以上が必要（標準搭載）
- Linux/Mac: bash + jq が必要
