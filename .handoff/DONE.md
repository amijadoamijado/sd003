# 引き継ぎ（DONE）— 2026-05-23

## 完了したこと

1. **at002 への SD003 アップグレード**（`/sd-upgrade` スキル）
   - UPGRADE OK。412ファイルコピー + 7生成（v2.14.0 / deploy v3.1.0）、.agents/skills 60件
   - 廃止物削除（.gemini/GEMINI.md/claude-memスタブ約60件）→ 全てバックアップ退避
   - 検証「Skills 114/115」FAIL は optional-skills デフォルト除外の誤報（実害なし）
   - バックアップ: at002 の `.sd003-upgrade-backup-20260523_131557` / `.sd003-backup-20260523_131558`

2. **agy `/` ドロップダウン問題の根本解決**（前段）
   - workspace `.agents/skills` は `/skills` のみ。**global `~/.gemini/skills/{name}/SKILL.md` で接頭語なし `/name` 表示**が正解
   - `scripts/deploy-agy-skills.py` 新規（コミット a46c7ab）、sd003の60スキルを global 配備済み
   - メモリ `reference_agy_command_mechanism` を訂正（旧版は誤記）

## 未完了

- at002 の `npm install` 未実行（@mcpher/gas-fakes 等の依存導入）
- at002 で agy 再起動 → `/skills` 動作確認 未
- sd003: sync後の `deploy-agy-skills.py` 2ステップを CLAUDE.md/ルールに明文化（恒久化）

## 次のステップ

1. `cd D:\claudecode\at002 && npm install`
2. at002 で agy 再起動・`/skills` 確認
3. 他PJ（oc001/at001等）への同様アップグレード展開

## 関連ファイル

- `scripts/deploy-agy-skills.py`、`scripts/sync-cli-commands.py`
- `.claude/skills/sd-upgrade/`（upgrade.ps1/sh）
- メモリ: `~/.claude/projects/D--claudecode-sd003/memory/reference_agy_command_mechanism.md`
