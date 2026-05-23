# 引き継ぎ（DONE）— 2026-05-23

## 完了したこと

1. **agy スラッシュコマンド不具合の根本解決**
   - agy（Antigravity CLI）は `.gemini/commands/*.toml` を読まない。**コマンド = Agent Skills（`.agents/skills/{name}/SKILL.md`）**。実機で `/skills` 0→60 確認
   - `sync-cli-commands.py` を SKILL.md/`.agents` 生成に改修。誤った `.antigravity/commands` `.antigravity/skills` 撤去
   - description のコロンで YAML が壊れる件をクォートで修正

2. **総合監査による不備一掃**（deploy/hook/doctrine/docs/cosmetics）
   - deploy.ps1/sh を agy 化（`.agents/skills` 伝播、gemini/.antigravity 撤去）
   - impl完了hook を `gemini→agy` 修正、coverage80% → VTD+実データ
   - README/AGENTS/antigravity/sd-deploy docs を agy 化（Gemini/Cursor/Windsurf 撤去）
   - `.antigravity/rules.md` 削除、`/CLAUDE` ジャンク撲滅

3. **新規 `/sd-upgrade` スキル**: 古いSD003を安全に最新へ置換（detect→dry-run→backup→deploy→verify）。throwawayテスト合格

4. **claude-mem 完全アンインストール**（非公式third-party）: npm + plugin + marketplace + cache 除去

## 未完了 / 次のステップ

- Claude Code 再起動 → claude-mem 無効化反映（スタブ再生成停止）
- agy 再起動 → `/skills` に `/sd-upgrade` 表示・警告0件 を確認
- 下流PJ展開: `/sd-upgrade <path>`（1PJずつ dry-run→確認→execute）

## 関連ファイル

- `scripts/sync-cli-commands.py`（agy/codex skill 生成器・正本）
- `.claude/skills/sd-upgrade/`（新規スキル: SKILL.md + upgrade.ps1/sh）
- `.claude/skills/sd-deploy/`（deploy 一式・agy化済み）
- `.sessions/session-20260523-102712.md`（詳細セッション記録）

## 全AIモデル共通の重要知見

- **agy のコマンドは `.agents/skills/{name}/SKILL.md`（SKILL.md形式のみ。`.toml`不可）**。生成は `python scripts/sync-cli-commands.py`、`.claude/commands` を直して再sync
- agy の自己完了報告は信用せず、ディスク副作用で実検証すること
