# SD003 セットアップガイド

## 導入

`/sd-deploy`（`.claude/skills/sd-deploy/deploy.ps1`）が唯一の導入経路。手動deployは禁止。

導入後は生成された `CLAUDE.md`、`AGENTS.md`、`grok.md` と `.claude/`、`.codex/`、`.agents/`、`.grok/`、`.handoff/`、`.sd/` を確認する。

## 更新と保護

更新は `sd-upgrade` のdry-runで差分を確認してから実行する。プロジェクト固有ファイルは `.sd003-keep` に列挙する。

## 確認

`npm install` 後に `npm run build && npm test && npm run lint` を実行する。配布内容は `node scripts/verify-deployment.mjs <target> <source>` で検証する。
