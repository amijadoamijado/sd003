# 完了報告 - 2026-04-02 15:40

## 完了
- Codex CLI v0.117.0で`.codex/prompts/`が廃止されたことを特定
- 全10PJの`.codex/prompts/`削除 + グローバル`~/.codex/prompts/`削除
- 17PJから`scripts/sync-codex-prompts.js`を削除
- sd-deployから`.codex/prompts/`関連処理を全削除
- AGENTS.md, README.md, テンプレートから廃止記述を削除
- nm002の@req除去 + frontmatter追加

## 未完了
- nm002に不足skills追加（blueprint-gate等4件）
- sd-deploy再配布

## 次のステップ
- nm002でClaude Code再起動して/sessionread表示確認
- Codex用セッション管理はAGENTS.mdまたは`~/.codex/skills/`で対応

## 関連ファイル
- `D:\claudecode\sd003\AGENTS.md` — Codex prompts同期セクション削除済み
- `D:\claudecode\sd003\.claude\skills\sd-deploy\` — deploy.ps1/sh/SKILL.md修正済み
- `D:\claudecode\sd003\.sd\cleanup\archive\codex-prompts-deprecated-20260402\` — アーカイブ
