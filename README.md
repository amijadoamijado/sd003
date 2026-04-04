# SD003 Framework

> Spec-Driven Development with GAS Local Testing Integration

[![TypeScript](https://img.shields.io/badge/TypeScript-5.9-blue)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green)](https://nodejs.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Overview

SD003 integrates **SD001 (Spec-Driven Development Framework)** with **GA001 (GAS Local Testing Environment)** for next-generation development.

### Key Features

- **Spec-Driven Development**: Full traceability from requirements to implementation
- **GAS Local Development**: Test Google Apps Script locally
- **Env Interface Pattern**: Complete separation of business logic and infrastructure
- **8-Stage Quality Gates**: Automated quality assurance
- **Multi-IDE Support**: Claude Code, Codex CLI, Gemini CLI, Cursor, Windsurf, Antigravity
- **Ralph Wiggum**: Night-mode autonomous execution (24-hour development cycle)
- **3-Tier Bug Resolution**: Systematic debugging framework

## Ralph Wiggum - Night Mode Autonomous Execution

24-hour development cycle: daytime collaboration + nighttime automation.

| Aspect | Daytime (sd003-loop-*) | Nighttime (Ralph Wiggum) |
|--------|------------------------|--------------------------|
| max-iterations | 15-20 | 60 |
| Recovery | dialogue-resolution | 7 auto patterns |
| Human | Available anytime | Only when blocked |

### Commands

```bash
/ralph-wiggum:plan     # Create weekly plan
/ralph-wiggum:run      # Execute nightly queue
/ralph-wiggum:status   # Check execution status
```

### Deploy to Other Projects

```bash
./scripts/deploy-ralph-wiggum.sh /path/to/your-project --with-specs
```

See: [Ralph Wiggum Deployment Guide](docs/ralph-wiggum-deployment.md)

## Multi-IDE Support

| IDE/CLI | Config Files | Commands |
|---------|-------------|----------|
| Claude Code | CLAUDE.md, .claude/rules/ | .claude/commands/ |
| Codex CLI | AGENTS.md, `.agents/skills/`, `~/.codex/skills/` | `$skill-name` |
| Gemini CLI | GEMINI.md, `.gemini/commands/` | TOML |
| Cursor | .cursor/rules/ | - |
| Windsurf | AGENTS.md, .windsurf/workflows/ | - |
| Antigravity | GEMINI.md, .antigravity/rules.md | `/workflow:test` (ANTIGRAVITY_GUIDE.md) |

### Multi-CLI コマンド同期

SD003 のカスタムコマンドは、以下の流れで Claude / Codex / Gemini に同期します。

- authoring source: `.claude/commands/**/*.md`
- canonical spec: `.sd/commands/specs/*.md`
- generated targets:
  - `.gemini/commands/*.toml`
  - `.agents/skills/*/SKILL.md`

同期コマンド:

```powershell
python scripts/sync-cli-commands.py
python scripts/sync-cli-commands.py --check
python scripts/sync-cli-commands.py --deploy-codex-home
```

Claude 以外の生成物は直接手編集せず、`.claude/commands/` を修正して再同期します。

### Codex CLI カスタマイズ

Codex CLI v0.117以降、Claude Code の `.claude/commands/*.md` 型 slash command は直接読みません。カスタマイズ方法:
- **プロジェクト指示**: `AGENTS.md`（従来通り）
- **スキル**: `~/.codex/skills/` または `.agents/skills/`（共通正本から自動生成）
- SD003 のコマンド群は `.agents/skills/` に生成されます。
- セッション系の canonical 名は `sessionread` / `sessionwrite` / `sessionhistory` です。
- 互換 alias として `session-read` / `session-write` も残します。
- `python scripts/sync-cli-commands.py --deploy-codex-home` で生成済み skill を `~/.codex/skills/` に配布できます。

---

## Deployment to Other Projects

### スクリプトでデプロイ（推奨）

v3.0.0からディレクトリ単位の動的コピーに移行。**ファイル追加時にスクリプト修正は不要。**

#### Windows（PowerShell）
```powershell
powershell -ExecutionPolicy Bypass -File .claude/skills/sd-deploy/deploy.ps1 /path/to/your-project
```

#### Linux/Mac（Bash）
```bash
bash .claude/skills/sd-deploy/deploy.sh /path/to/your-project
```

#### Claude Codeから実行
```
/sd:deploy /path/to/your-project
```

### スクリプトの処理内容

| Phase | 内容 |
|-------|------|
| 1 | ターゲット存在確認 |
| 2 | 既存設定のバックアップ（`.sd003-backup-YYYYMMDD_HHMMSS/`） |
| 3 | ディレクトリ構造作成 |
| 4 | 動的コピー（12カテゴリ、ディレクトリ単位） |
| 5 | 生成ファイル作成（CLAUDE.md, gemini.md, session等 7ファイル + ユーザーCLAUDE.md初期配置） |
| 6 | 検証（ソースvsターゲットのファイル数比較） |
| 7 | レポート出力 |

### 動的コピー対象

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
| 9 | `.sessions/session-template.md` | 単体コピー |
| 10 | `.sd/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}` | 選択コピー |
| 11 | `docs/troubleshooting/` | ツリーコピー |
| 12 | `docs/quality-gates.md` | 単体コピー |

### デプロイ後の検証

スクリプトがPhase 6で自動検証を実行する。手動確認する場合：

```powershell
# Windows
(Get-ChildItem .claude/commands/*.md).Count        # Commands直下
(Get-ChildItem .claude/commands/sd/*.md).Count    # Commands/sd
(Get-ChildItem .claude/rules -Recurse -Filter *.md).Count  # Rules
(Get-ChildItem .claude/skills -Recurse -File).Count # Skills
(Get-ChildItem .claude/hooks -Recurse -File).Count  # Hooks
```

### ユーザーレベル CLAUDE.md の初期配置

デプロイ時、`~/.claude/CLAUDE.md` が存在しない場合に自動配置されます。

| 項目 | 内容 |
|------|------|
| テンプレート | `.claude/skills/sd-deploy/templates/user-claude.md.template` |
| 配置先 | `~/.claude/CLAUDE.md`（ユーザーホーム） |
| 既存時 | **スキップ**（上書きしない） |
| 内容 | plan mode、サブエージェント活用、コンテキスト管理等の基本方針 |

> **重要**: このファイルはプロジェクト横断で全セッションに適用されます。
> デプロイ後、必要に応じてユーザーの好みに合わせてカスタマイズしてください。

### コマンド動作確認

| Check | Command | Expected |
|-------|---------|----------|
| Session read | `/sessionread` | 4ファイル読み込み完了 |
| Session write | `/sessionwrite` | session-current.md 更新 |
| Bug quick | `/bug-quick` | フロー比較診断開始 |
| Bug trace | `/bug-trace` | 3-Agent調査開始 |
| Dialogue resolution | `/dialogue-resolution` | AI推論チェック開始 |
| SD commands | `/sd:spec-status` | 仕様一覧表示 |
| Settings | Check `.claude/settings.local.json` | ENABLE_TOOL_SEARCH=true |

**コマンドが認識されない場合**:
1. `.claude/commands/` フォルダがプロジェクトルートに存在するか確認
2. 必須ファイルが全て存在するか確認
3. Claude Codeを再起動

### Codex での同等操作

| Purpose | Claude Code | Codex CLI | Gemini CLI |
|---------|-------------|-----------|------------|
| Session read | `/sessionread` | `$sessionread` または `$session-read` | `sessionread.toml` |
| Session write | `/sessionwrite` | `$sessionwrite` または `$session-write` | `sessionwrite.toml` |
| Session history | `/sessionhistory` | `$sessionhistory` | `sessionhistory.toml` |
| Workflow init | `/workflow:init` | `$workflow-init` | `workflow-init.toml` |
| Skills find | `/skills:find` | `$skills-find` | `skills-find.toml` |
| SD deploy | `/sd:deploy` | `$sd-deploy` | `sd-deploy.toml` |

> Codex では `.claude/commands` を直接読まず、同期生成された `.agents/skills/` または `~/.codex/skills/` を使います。Gemini では同期生成された `.gemini/commands/*.toml` を使います。

---

## Skills Ecosystem

SD003 integrates with the [skills.sh](https://skills.sh/) open agent skills ecosystem (58,000+ skills).

### Commands

```bash
/skills:find {query}                    # Search skills
/skills:add {owner/repo} [--skill name] # Install a skill
/skills:list                            # List installed skills
```

### CLI Usage

```bash
npx skills find "testing"      # Search for testing skills
npx skills add vercel-labs/agent-skills --skill vercel-react-best-practices -y
npx skills list                # List installed skills
```

### Trust Policy

| Level | Source | Policy |
|-------|--------|--------|
| **Trusted** | `anthropics/skills`, `vercel-labs/skills`, `vercel-labs/agent-skills` | Install freely |
| **Caution** | Other repositories | Review SKILL.md before installing |

---

## 3-Tier GAS Testing Strategy

| Tier | Tool | Directory | Speed | Fidelity | GCP Auth |
|------|------|-----------|-------|----------|----------|
| Tier-1 | GA001 Mock + LocalEnv | `tests/unit/`, `tests/integration/` | < 1s | Low | No |
| Tier-2 | @mcpher/gas-fakes | `tests/gas-fakes/` | < 30s | Medium-High | Partial |
| Tier-3 | Antigravity E2E | Production | Minutes | Highest | Yes |

```bash
npm test                    # All tests (Tier-1 + Tier-2)
npm run test:gas-fakes      # Tier-2 only
/workflow:test {ID} {num}   # Tier-3 (Antigravity E2E)
```

## 4-Agent Pipeline

```
/workflow:request → /workflow:impl(Gemini) → /workflow:review(Codex) → /workflow:test(Antigravity)
```

| Script | Purpose | Agents |
|--------|---------|--------|
| `scripts/agent-implement.sh` | Gemini implementation only | 1 |
| `scripts/agent-test.sh` | Antigravity test only | 1 |
| `scripts/agent-pipeline.sh` | Full 4-Agent pipeline | 4 |

```bash
# Full pipeline
./scripts/agent-pipeline.sh 20260101-001-auth 001

# Skip Antigravity test
./scripts/agent-pipeline.sh 20260101-001-auth 001 --skip-test

# Preview only
./scripts/agent-pipeline.sh 20260101-001-auth 001 --dry-run
```

---

## 3-Tier Bug Resolution Framework

**3段階バグ解決フレームワーク - これなしでは効率的なデバッグ不可能**

```
Bug発生
    |
    v
/bug-quick (5-15分)     <-- 第1段階: フロー比較
    |
    +-- 解決 --> 完了
    |
    +-- 複雑 --> /bug-trace (30-60分)  <-- 第2段階: 深層3-Agent調査
                    |
                    +-- 未解決 --> /dialogue-resolution  <-- 第3段階: AI推論チェック
```

| Command | File | Purpose | Time |
|---------|------|---------|------|
| `/bug-quick` | `.claude/commands/bug-quick.md` | 第1段階: フロー比較による迅速診断 | 5-15分 |
| `/bug-trace` | `.claude/commands/bug-trace.md` | 第2段階: 3-Agent深層調査 | 30-60分 |
| `/dialogue-resolution` | `.claude/commands/dialogue-resolution.md` | 第3段階: AI推論チェック | 可変 |

**エスカレーション基準:**
- bug-quick → bug-trace: 複数箇所の差異、根本原因不明
- bug-trace → dialogue-resolution: 同じエラー2回、AI推論に問題

---

## Session Workflow

### Session Start
```
/sessionread
```
Reads 4 files in order:
1. `D:\claudecode\CLAUDE.md` (Global settings)
2. `./CLAUDE.md` (Project settings)
3. `.sessions/session-current.md` (Current state)
4. `.sessions/TIMELINE.md` (History)

### Session End
```
/sessionwrite
```
Updates session-current.md with progress.

### Crash Recovery
```bash
claude --continue
/sessionread
```

---

## Documentation

### Guides
- [GAS Development Guide](docs/gas-development-guide.md)
- [Quality Gates](docs/quality-gates.md)
- [Coding Standards](docs/coding-standards.md)
- [Session Management](docs/session-management.md)
- [Deployment Strategy](docs/deployment-strategy.md)
- [Ralph Wiggum Deployment](docs/ralph-wiggum-deployment.md)

### Specifications
- [Requirements](.sd/specs/sd003-framework/requirements.md)
- [Technical Design](.sd/specs/sd003-framework/design.md)
- [Implementation Tasks](.sd/specs/sd003-framework/tasks.md)
- [Ralph Wiggum Specs](.sd/specs/ralph-wiggum/)
- [Bug Trace Specs](.sd/specs/bug-trace/)
- [Dialogue Resolution Specs](.sd/specs/dialogue-resolution/)
- [gas-fakes Testing Specs](.sd/specs/gas-fakes-testing/)
- [Antigravity Pipeline Specs](.sd/specs/antigravity-pipeline/)

## License

MIT License

---

**SD003 Framework v2.13.0** - Spec-Driven + GAS Local + gas-fakes + 4-Agent Pipeline + 24-Hour Development + 3-Tier Bug Resolution + Skills Ecosystem
# clean state test
# verify
