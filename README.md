# SD003 Framework

> Spec-Driven Development with GAS Local Testing Integration

[![TypeScript](https://img.shields.io/badge/TypeScript-5.9-blue)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18%2B-green)](https://nodejs.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Overview

SD002 integrates **SD001 (Spec-Driven Development Framework)** with **GA001 (GAS Local Testing Environment)** for next-generation development.

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
| Codex CLI | AGENTS.md, `~/.codex/prompts/` | `/prompts:*`（`.claude/commands`から自動同期） |
| Gemini CLI | GEMINI.md, .gemini/commands/ | TOML |
| Cursor | .cursor/rules/ | - |
| Windsurf | AGENTS.md, .windsurf/workflows/ | - |
| Antigravity | GEMINI.md, .antigravity/rules.md | `/workflow:test` (ANTIGRAVITY_GUIDE.md) |

### Codex Slash Commands

Codex CLI はカスタムコマンドを `/prompts:*` 形式で実行します。

```bash
# Claudeのコマンド定義をCodex用に同期
npm run sync:codex-prompts

# 実行例
/prompts:sessionwrite
```

主な互換マッピング:
- Claude `/bug-quick` -> Codex `/prompts:bug-quick`
- Claude `/kiro:spec-init` -> Codex `/prompts:kiro-spec-init` または `/prompts:kiro/spec-init`

補足:
- `/prompts` 単体は一覧コマンドではありません。
- 候補は `/` を入力して `prompts:` で絞り込みます。

---

## Deployment to Other Projects

### スクリプトでデプロイ（推奨）

v3.0.0からディレクトリ単位の動的コピーに移行。**ファイル追加時にスクリプト修正は不要。**

#### Windows（PowerShell）
```powershell
powershell -ExecutionPolicy Bypass -File .claude/skills/kiro-deploy/deploy.ps1 /path/to/your-project
```

#### Linux/Mac（Bash）
```bash
bash .claude/skills/kiro-deploy/deploy.sh /path/to/your-project
```

#### Claude Codeから実行
```
/kiro:deploy /path/to/your-project
```

### スクリプトの処理内容

| Phase | 内容 |
|-------|------|
| 1 | ターゲット存在確認 |
| 2 | 既存設定のバックアップ（`.sd003-backup-YYYYMMDD_HHMMSS/`） |
| 3 | ディレクトリ構造作成 |
| 4 | 動的コピー（12カテゴリ、ディレクトリ単位） |
| 5 | 生成ファイル作成（CLAUDE.md, gemini.md, session等 7ファイル） |
| 6 | 検証（ソースvsターゲットのファイル数比較） |
| 7 | レポート出力 |

### 動的コピー対象

| # | ソース | コピー方式 |
|---|--------|-----------|
| 1 | `.claude/commands/*.md` | フラットコピー |
| 2 | `.claude/commands/kiro/*.md` | フラットコピー |
| 3 | `.claude/rules/` | ツリーコピー |
| 4 | `.claude/skills/` | ツリーコピー |
| 5 | `.claude/hooks/` | ツリーコピー |
| 6 | `.gemini/commands/*.toml` | フラットコピー |
| 7 | `.antigravity/` | ツリーコピー |
| 8 | `.kiro/settings/` | ツリーコピー |
| 9 | `.kiro/sessions/session-template.md` | 単体コピー |
| 10 | `.kiro/ai-coordination/workflow/{README,CODEX_GUIDE,templates/}` | 選択コピー |
| 11 | `docs/troubleshooting/` | ツリーコピー |
| 12 | `docs/quality-gates.md` | 単体コピー |

### デプロイ後の検証

スクリプトがPhase 6で自動検証を実行する。手動確認する場合：

```powershell
# Windows
(Get-ChildItem .claude/commands/*.md).Count        # Commands直下
(Get-ChildItem .claude/commands/kiro/*.md).Count    # Commands/kiro
(Get-ChildItem .claude/rules -Recurse -Filter *.md).Count  # Rules
(Get-ChildItem .claude/skills -Recurse -File).Count # Skills
(Get-ChildItem .claude/hooks -Recurse -File).Count  # Hooks
```

### コマンド動作確認

| Check | Command | Expected |
|-------|---------|----------|
| Session read | `/sessionread` | 4ファイル読み込み完了 |
| Session write | `/sessionwrite` | session-current.md 更新 |
| Bug quick | `/bug-quick` | フロー比較診断開始 |
| Bug trace | `/bug-trace` | 3-Agent調査開始 |
| Dialogue resolution | `/dialogue-resolution` | AI推論チェック開始 |
| Kiro commands | `/kiro:spec-status` | 仕様一覧表示 |
| Settings | Check `.claude/settings.local.json` | ENABLE_TOOL_SEARCH=true |

**コマンドが認識されない場合**:
1. `.claude/commands/` フォルダがプロジェクトルートに存在するか確認
2. 必須ファイルが全て存在するか確認
3. Claude Codeを再起動

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
3. `.kiro/sessions/session-current.md` (Current state)
4. `.kiro/sessions/TIMELINE.md` (History)

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
- [Requirements](.kiro/specs/sd003-framework/requirements.md)
- [Technical Design](.kiro/specs/sd003-framework/design.md)
- [Implementation Tasks](.kiro/specs/sd003-framework/tasks.md)
- [Ralph Wiggum Specs](.kiro/specs/ralph-wiggum/)
- [Bug Trace Specs](.kiro/specs/bug-trace/)
- [Dialogue Resolution Specs](.kiro/specs/dialogue-resolution/)
- [gas-fakes Testing Specs](.kiro/specs/gas-fakes-testing/)
- [Antigravity Pipeline Specs](.kiro/specs/antigravity-pipeline/)

## License

MIT License

---

**SD003 Framework v2.12.0** - Spec-Driven + GAS Local + gas-fakes + 4-Agent Pipeline + 24-Hour Development + 3-Tier Bug Resolution
