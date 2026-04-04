# SD003 Multi-CLI Command Canonical Source

このディレクトリは、SD003 のカスタムコマンドを Claude Code / Codex / Gemini CLI で等価に運用するための共通正本です。

## 方針

1. Authoring source は `D:\claudecode\sd003\.claude\commands\` の Markdown。
2. `python scripts/sync-cli-commands.py` で正規化し、`.sd/commands/specs/` に保存する。
3. 同じスクリプトで以下を生成する。
   - `D:\claudecode\sd003\.gemini\commands\*.toml`
   - `D:\claudecode\sd003\.agents\skills\*/SKILL.md`
4. Claude 以外は直接手編集せず、Claude 側を修正して再同期する。

## 生成物

- `manifest.json`: コマンド一覧と出力先のマッピング
- `specs/*.md`: CLI 非依存の正規化済みコマンド本文

## 実行

```powershell
python D:\claudecode\sd003\scripts\sync-cli-commands.py
python D:\claudecode\sd003\scripts\sync-cli-commands.py --check
```

## 命名

- Claude: 元の slash command 名を維持
- Gemini: `slug.toml`
- Codex: `slug` skill
- 互換 alias が必要な場合は別 skill として生成
