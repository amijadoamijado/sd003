# SD003 Codex Skill Specification

SD003をCodexで動かすためのSkill生成・配置仕様を定義する。実行モードは`.codex/CODEX_NATIVE.md`を正本とする。

## 正本と生成先

| 役割 | パス |
|---|---|
| コマンドauthoring source | `.claude/commands/**/*.md` |
| 実Skill authoring source | `.claude/skills/*/SKILL.md` |
| CLI非依存コマンド仕様 | `.sd/commands/specs/*.md` |
| Codex・agy共通repo Skill | `.agents/skills/*/SKILL.md` |
| Grok Skill | `.grok/skills/*/SKILL.md` |
| 生成manifest | `.sd/commands/manifest.json` |

Codex公式のrepo Skill探索先とagyの実運用探索先がともに`.agents/skills`であるため、ここを共通runtime targetとする。

## 生成ルール

1. `.claude/commands/**/*.md`と`.claude/skills/**`を直接の正本とする。
2. `python scripts/sync-cli-commands.py`で共通Agent Skill、Grok Skill、正規化spec、manifestを生成する。
3. `.agents/skills`と`.grok/skills`の生成物を直接編集しない。
4. `.sd003-managed`付きディレクトリだけを同期処理が更新・pruneする。
5. 生成対象と同名の未管理Skillがある場合は、書込み前に同期を中止する。
6. Claude固有記法は共通SkillのRuntime Adaptation Rulesと`CODEX_NATIVE.md`に従って各CLI操作へ変換する。

## 廃止した重複経路

- `.codex/skills`はrepo内で`.agents/skills`と重複するため廃止。
- `~/.codex/skills`へのSD003自動配布はrepo Skillと重複するため廃止。
- `--deploy-codex-home`は安全に失敗して移行案内を返す。
- `--codex-only`は移行期間中だけ`--agents-only`の警告付きaliasとする。

既存のCodex home Skillは自動削除しない。SD003由来と確認できたものだけ、skills探索範囲外のtimestamp付きバックアップへ移動する。

## Codex実行変換

- Claude CodeのスラッシュコマンドをCodex内で再帰実行しない。
- `/codex:*`、`/workflow:*`、`Agent(...)`、`AskUserQuestion`は意図を読み、Codex自身の読取・編集・検証・報告へ変換する。
- 未コミット変更を他AIまたはユーザーの作業として保護する。
- WindowsではPowerShellを優先する。
- 案件IDなしの相談・レビューは会話内で完結する。

## 検証

```powershell
python scripts/sync-cli-commands.py
python scripts/sync-cli-commands.py --check
```

`--check`は、正規化spec、共通Agent Skill、管理マーカー、生成内容、Grok Skill、各Native仕様の存在と、旧`.codex/skills`が残っていないことを検証する。
