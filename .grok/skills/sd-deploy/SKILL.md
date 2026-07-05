---
name: sd-deploy
description: |
  SD003フレームワークを新規プロジェクトに展開。
  Use when: ユーザーが「SD003導入」「フレームワーク展開」「deploy」と言及した場合。
---

# SD003フレームワーク展開スキル v3.4.0

## 概要

SD003フレームワーク（v2.15.0）を新規プロジェクトに展開する。
**ディレクトリ単位の動的コピー**により、ファイル追加時にスクリプト修正は不要。

## 上書きポリシー（必須）

| 種別 | ファイル | 動作 |
|------|---------|------|
| **ルール（上書き）** | CLAUDE.md, antigravity.md, settings.json, rules/, commands/, hooks/, skills/, .agents/skills/ | 常に最新版で上書き（**`.sd003-keep` 記載ファイルは除く**） |
| **データ（SKIP+テンプレート）** | session-current.md, TIMELINE.md, registry.json, handoff-log.json | 存在しなければテンプレートから生成 |
| **仕様書等** | .sd/specs/, .sessions/ 履歴 | 触らない |

> **重要**: 「ルール（上書き）」のファイルは FW 所有物として無条件で上書きされる。
> プロジェクトが**意図的に固有化**したフレームワークファイルは、そのままでは消える。
> 保護するには `.sd003-keep`（下記）に列挙する。

## .sd003-keep（オプトアウト：固有化ファイルの保護）

プロジェクトが意図的にカスタマイズしたフレームワークファイルを deploy/upgrade の上書きから守る仕組み。

- 配置: ターゲットプロジェクト直下 `<target>/.sd003-keep`
- 形式: 1行1パス（プロジェクトルート相対）。`#` 始まりはコメント、空行無視
- マッチ: 完全一致 / ディレクトリ接頭辞（配下すべて）/ `*` `?` グロブ
- `.sd003-keep` が無ければ全ガードは no-op（従来挙動と完全に同一）

例（会計事務所スキルを固有化した at002 のようなプロジェクト）:
```
# このプロジェクトが意図的に固有化した FW ファイル
CLAUDE.md
.claude/skills/registry.json
.claude/hooks/
.claude/rules/
package.json
```

### dry-run で必ず事前確認（正直化）

`/sd-deploy` 系を実行する前に dry-run で「何が上書きされ、何が保護されるか」を可視化する。

```powershell
powershell -ExecutionPolicy Bypass -File .claude/skills/sd-deploy/deploy.ps1 <target> -DryRun
```
```bash
bash .claude/skills/sd-deploy/deploy.sh <target> --dry-run
```

dry-run は以下を一覧表示する（無変更）:
- **WILL OVERWRITE - LOCAL CUSTOMIZATION WILL BE LOST**: ターゲットの内容がFWソースと異なる＝上書きで失われる固有化
- **WILL OVERWRITE - regenerated from template**: CLAUDE.md（テンプレ再生成）
- **KEPT via .sd003-keep**: 保護されるファイル

実行（real run）後の Phase 7 レポートでも、`.sd003-keep` で保護したファイルと、
上書きした divergence（バックアップ済み）を明示する。**もう "全部無傷" と誤報しない。**

## テンプレートフォルダ（必須確認）

新規ファイル生成時は必ずテンプレートフォルダを確認すること。インラインでheredoc生成は禁止。

| テンプレート | 場所 |
|-------------|------|
| セッション関連 | `.sessions/templates/` |
| deploy生成ファイル | `.claude/skills/sd-deploy/templates/` |

**テンプレートにないファイルを新規追加する場合**: まずテンプレートファイルを作成してからdeploy.ps1に追加。

## 使用方法

```
/sd:deploy <target-project-path>
```

## 実行手順

### Windows（推奨）
```powershell
powershell -ExecutionPolicy Bypass -File .claude/skills/sd-deploy/deploy.ps1 <target-project-path>
```

### Linux/Mac
```bash
bash .claude/skills/sd-deploy/deploy.sh <target-project-path>
```

## スクリプトの7フェーズ

| Phase | 内容 |
|-------|------|
| 1 | ターゲット存在確認 |
| 2 | 既存設定のバックアップ |
| 3 | ディレクトリ構造作成 |
| 4 | **動的コピー**（ディレクトリ単位、ハードコードなし） |
| 5 | 生成ファイル作成（CLAUDE.md, antigravity.md, session等） |
| 6 | 検証（ソースvsターゲットのファイル数比較） |
| 6b | **内容検証ゲート**（`node scripts/verify-deployment.mjs`。hard-fail） |
| 7 | レポート出力 |

### Phase 6b: 内容検証ゲート（hard-fail）

> Phase 6 はファイル「数」と「存在」しか見ない。`settings.json` の**中身**が壊れていても
> （例: commit `9f14984` はガードレールが Stop にしか配線されず PreToolUse 空 = 防御不活性で出荷）
> 「ファイルは存在する」だけで素通りした。Phase 6b はその穴を塞ぐ。

- 実装は単一の Node スクリプト `scripts/verify-deployment.mjs`（PS1/sh のロジック二重化を回避）。
  Node 標準モジュールのみ使用 → `npm install` 前でも動く。
- **失敗するとデプロイが exit 1 で止まる**（旧来は検証失敗でも exit 0 で「成功」だった）。
- `--dry-run` 時はスキップ（生成物がないため）。`node` が PATH にない場合は FAIL（黙ってスキップしない）。

| 検査 | 内容 | 捕捉する欠陥 |
|------|------|------------|
| C1 | `settings.json.template` から期待hook集合を導出し、配信先の `settings.json` が同じhookを配線し PreToolUse/PostToolUse/Stop/SessionStart が非空か | mis-wiring（9f14984級）、置換でJSON破損 |
| C2 | 配信先 `settings.json` が参照する各hookファイルが `.claude/hooks/` に実在するか | dangling wiring |
| C3 | 生成ファイルに未置換テンプレ変数 `{{...}}` が残っていないか | 半端な生成 |
| C4 | `.claude/commands/*.md` / `settings.json` / `CLAUDE.md` に廃止語が無いか | `.kiro` 残存・stale ref |
| C5 | hookスクリプトと `settings.json` に文字化け（U+FFFD）が無いか | デプロイ時文字化け |
| C6 | 生成JSON（registry / handoff-log）がparse可能か（BOM許容） | JSON破損 |

**手動実行**: `node scripts/verify-deployment.mjs <targetDir> [sourceDir]`（全PASSでexit 0、1件でもFAILでexit 1）。
**deny-list の調整（C4）**: 環境変数 `SD003_DEPRECATED_TOKENS="tok1,tok2"`（既定 `.kiro`）。誤検知でゲート信頼を損なわないよう最小限に保つ。
**既存デプロイ先の落とし穴**: deploy は既存 `settings.json` を上書きしない（SKIP）。古い配信先は壊れた配線のまま固着するため、Phase 6b が FAIL したら `settings.json` を削除して再deployするか手動で再配線する。

## 動的コピー対象

| # | ソース | コピー方式 |
|---|--------|-----------|
| 1 | `.claude/commands/*.md` | フラットコピー |
| 2 | `.claude/commands/sd/*.md` | フラットコピー |
| 3 | `.claude/rules/` | ツリーコピー |
| 4 | `.claude/skills/` | ツリーコピー |
| 5 | `.claude/hooks/` | ツリーコピー |
| 6 | `.agents/skills/`（agy。SKILL.md形式のコマンド+実スキル） | ツリーコピー |
| 8 | `.sd/settings/` | ツリーコピー |
| 9 | `.sessions/session-template.md` | 単体コピー |
| 10 | `.sd/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}` | 選択コピー |
| 11 | `docs/troubleshooting/` | ツリーコピー |
| 12 | `docs/quality-gates.md` | 単体コピー |
| 13 | `.handoff/` | ツリーコピー |
| 14 | `scripts/sync-cli-commands.py`（agy/codex skill生成器） | 単体コピー |
| 15 | `scripts/verify-deployment.mjs`（Phase 6b 内容検証ゲート） | 単体コピー |
| 16 | `AGENTS.md` | 単体コピー |
| 17 | `.sd/ralph/` | ツリーコピー |
| 18 | `.sd/steering/` | ツリーコピー |
| 19 | `.sd/refactor/config.json` | 単体コピー |
| 20 | `tests/gas-fakes/setup.ts` | 単体コピー |
| 21 | `.git/hooks/` | templates/git-hooks/ からコピー（自動push + .sd/自動ステージ） |

## gas-fakes 自動注入（Phase 5b）

ターゲットプロジェクトの `package.json` に以下を自動注入。`package.json` が存在しない場合は自動作成してから注入する：

| 追加内容 | 値 |
|---------|-----|
| devDependencies | `"@mcpher/gas-fakes": "^1.2.0"` |
| scripts | `"test:gas-fakes": "jest --testPathPatterns=tests/gas-fakes/ --setupFiles=./tests/gas-fakes/setup.ts --passWithNoTests"` |

注意: `@mcpher/gas-fakes` が既に存在する場合はスキップ。

## 生成ファイル

| ファイル | 生成方法 |
|---------|---------|
| `CLAUDE.md` | テンプレートから生成 |
| `antigravity.md` | ソースから最新版で上書き |
| `.sessions/session-current.md` | 新規生成 |
| `.sessions/TIMELINE.md` | 新規生成 |
| `.claude/settings.json` | OS検出して生成 |
| `.sd/ids/registry.json` | 新規生成 |
| `.sd/ai-coordination/handoff/handoff-log.json` | 新規生成 |
| `~/.claude/CLAUDE.md` | テンプレートから初期配置（既存時スキップ） |

## 必須設定

### Tool Search（MCP最適化）

デプロイ先で以下の設定を追加する（スクリプトが自動生成）：

**`.claude/settings.local.json`**
```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  }
}
```

## デプロイ完了後の必須ステップ（台帳登録）

展開先が `D:\claudecode` 直下の新規プロジェクトの場合、デプロイ完了後に必ず
`D:\claudecode\PROJECT_REGISTRY.md` のコード対応表へ1行追記する（コード・用途・status=active・作成日）。
**台帳に登録するまでデプロイ完了としない。**

> 背景: 2026-07-05の D:\claudecode 全体整理で、新規プロジェクトが台帳に登録されず無秩序に増えていたことが判明した。
> `deploy.ps1` は Phase 7 のレポートに `[REMINDER]` として台帳登録を促すメッセージを出力するが、
> 台帳ファイル自体への追記はスクリプトが自動で行わない。AI（Claude Code等）が本手順に従って手動で追記すること。

## デプロイ後の検証

スクリプトがPhase 6で自動検証を実行する。手動確認する場合：

### Windows
```powershell
# ファイル数確認
(Get-ChildItem .claude/commands/*.md).Count        # Commands直下
(Get-ChildItem .claude/commands/sd/*.md).Count    # Commands/sd
(Get-ChildItem .claude/rules -Recurse -Filter *.md).Count  # Rules
(Get-ChildItem .claude/skills -Recurse -File).Count # Skills
(Get-ChildItem .claude/hooks -Recurse -File).Count  # Hooks
```

### Linux/Mac
```bash
ls -1 .claude/commands/*.md | wc -l           # Commands直下
ls -1 .claude/commands/sd/*.md | wc -l      # Commands/sd
find .claude/rules -name '*.md' | wc -l       # Rules
find .claude/skills -type f | wc -l           # Skills
find .claude/hooks -type f | wc -l            # Hooks
```

## 新規ファイル追加時

**v3.0.0の最大の改善点**: ファイルを追加しても deploy スクリプトの修正は不要。

| 追加先 | 必要な操作 |
|--------|-----------|
| `.claude/commands/` | ファイルを置くだけ |
| `.claude/commands/sd/` | ファイルを置くだけ |
| `.claude/rules/` | ファイルを置くだけ |
| `.claude/skills/` | ディレクトリ+ファイルを作成するだけ |
| `.claude/hooks/` | ファイルを置くだけ |
| `.agents/skills/` | `.claude/commands` を直して `python scripts/sync-cli-commands.py`（agyがSKILL.mdを起動時ロード） |

## 詳細手順

README.md を参照。
