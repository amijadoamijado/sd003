---
name: sd-deploy
description: |
  SD003フレームワークを新規プロジェクトに展開。
  Use when: ユーザーが「SD003導入」「フレームワーク展開」「deploy」と言及した場合。
allowed-tools: Read, Write, Bash, Glob
---

# SD003フレームワーク展開スキル v3.1.0

## 概要

SD003フレームワーク（v2.13.0）を新規プロジェクトに展開する。
**ディレクトリ単位の動的コピー**により、ファイル追加時にスクリプト修正は不要。

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
| 5 | 生成ファイル作成（CLAUDE.md, gemini.md, session等） |
| 6 | 検証（ソースvsターゲットのファイル数比較） |
| 7 | レポート出力 |

## 動的コピー対象

| # | ソース | コピー方式 |
|---|--------|-----------|
| 1 | `.claude/commands/*.md` | フラットコピー |
| 2 | `.claude/commands/sd/*.md` | フラットコピー |
| 3 | `.claude/rules/` | ツリーコピー |
| 4 | `.claude/skills/` | ツリーコピー |
| 5 | `.claude/hooks/` | ツリーコピー |
| 6 | `.gemini/commands/*.toml` | フラットコピー |
| 7 | `.antigravity/` | ツリーコピー |
| 8 | `.sd/settings/` | ツリーコピー |
| 9 | `.sd/sessions/session-template.md` | 単体コピー |
| 10 | `.sd/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}` | 選択コピー |
| 11 | `docs/troubleshooting/` | ツリーコピー |
| 12 | `docs/quality-gates.md` | 単体コピー |
| 13 | `.handoff/` | ツリーコピー |
| 14 | `scripts/sync-codex-prompts.js` | 単体コピー |
| 15 | `scripts/sync-gemini-features.js` | 単体コピー |
| 16 | `AGENTS.md` | 単体コピー |
| 17 | `.sd/ralph/` | ツリーコピー |
| 18 | `.sd/steering/` | ツリーコピー |
| 19 | `.sd/refactor/config.json` | 単体コピー |
| 20 | `tests/gas-fakes/setup.ts` | 単体コピー |

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
| `gemini.md` | テンプレートから生成 |
| `.sd/sessions/session-current.md` | 新規生成 |
| `.sd/sessions/TIMELINE.md` | 新規生成 |
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
| `.gemini/commands/` | ファイルを置くだけ |

## 詳細手順

README.md を参照。
