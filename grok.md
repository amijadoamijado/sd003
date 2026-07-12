# SD003 Framework - Grok CLI Configuration

このファイルは Grok CLI（xAI 公式）が SD003 リポジトリで動くための入口です。
**共通ルールの正本は `.handoff/RULES.md`**、Grok 固有仕様は `.grok/GROK_SPEC.md` を参照してください。

## Custom Commands & Skills

SD003 のカスタムコマンドは `.claude/commands/**/*.md` を authoring source とし、
`.sd/commands/specs/*.md` に正規化後、Grok skill として `.grok/skills/{name}/SKILL.md` に生成されます。

Sync コマンド:
```powershell
python scripts/sync-cli-commands.py
python scripts/sync-cli-commands.py --check
```

Grok CLI は `.grok/skills/*/SKILL.md` を起動時に自動検出します（ファイル変更で自動リロード、`/skills` で確認）。
Lead mode の実行要約は `.grok/rules/lead-mode.md` として自動読込されます（`grok inspect` で確認）。
生成物は手編集せず、Claude 側の正本か同期スクリプトを変更してください（`.grok/rules/` は Lead 用の例外・手動管理）。

- プロジェクト Skill: `<repo>/.grok/skills/{name}/SKILL.md`
- ユーザー Skill: `~/.grok/skills/{name}/SKILL.md`
- dispatch 系スキル（grok-dispatch 等）は再帰回避のため `.grok/skills/` には生成されません。

## Role（4AI協調）

Grok は **Session Lead 候補**（入口=司令塔）であり、探索実装・独立検証・調査主導の第一候補。

| モード | いつ | 正本 |
|--------|------|------|
| **Lead mode** | ユーザーが Grok を直接起動 / 「Grok主導で」等 | `.grok/GROK_NATIVE.md` |
| **Assist mode** | 他AIから `grok-dispatch` で呼ばれたとき | `.claude/skills/grok-dispatch/` |

- 公式レビュー印 = Codex、本番 E2E = agy（衝突時はドメイン表に従う）
- 詳細: `.claude/rules/workflow/ai-coordination.md`、`.sd/ai-coordination/workflow/GROK_GUIDE.md`

## Setup（認証・環境）

```powershell
$env:GROK_HOME = 'D:\grok'                 # 既定データホーム
& (Join-Path $env:GROK_HOME 'bin\grok.exe') --version
# 未認証なら: & (Join-Path $env:GROK_HOME 'bin\grok.exe') login
```

## Core Rules（要点・詳細は RULES.md）

- 開発順序は Work First（まず動かす → 実環境確認 → テスト → 抽象化 → 文書）。
- Lead mode では工程判断・完了報告まで Grok が担う（Claude 経由は不要）。
- `.claude/commands/**` は authoring source。直接編集せず、生成 Skill を実行仕様として扱う。
- 他 CLI のスラッシュコマンド（`/workflow:*`, `/codex:*`）を呼ばない。Grok 自身で作業する。
- GAS は `clasp push` のみ。`clasp deploy` / `undeploy` はユーザー明示指示のみ。
- `.sd/ai-coordination/` への書き込みは案件 ID 明示時のみ（セッションメモは `sessions/grok/` 可）。
- 同一 repo への複数 AI 同時書き込みは排他（git 競合回避）。Lead が repo lock。
- 人間向け出力は日本語。Windows では PowerShell を優先。

---
詳細: `.handoff/RULES.md` / `.grok/GROK_SPEC.md` / `.grok/GROK_NATIVE.md` / `.claude/rules/`
