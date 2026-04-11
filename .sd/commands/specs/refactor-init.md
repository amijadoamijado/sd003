---
slug: refactor-init
source: .claude/commands/refactor-init.md
description: Initialize refactoring session with parallel impact analysis
claude_command: /refactor:init
codex_skill: refactor-init
gemini_file: refactor-init.toml
allowed_tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion, TodoWrite
---

# /refactor:init

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Gemini CLI の TOML と Codex の skill はこのファイルから生成します。

## Original Body
# /refactor:init

3並列サブエージェントによる包括的影響分析でリファクタリングセッションを初期化する。

## Usage

```
/refactor:init {scope_description}
```

**Arguments:**
- `scope_description`: リファクタリング対象（例: "getUserByIdをfetchUserにリネーム", "認証ロジックをサービスに抽出"）

## スコープ未指定時

引数なしで実行された場合、AskUserQuestionでスコープを確認:

```yaml
Question: "リファクタリングの対象を選択してください"
Header: "スコープ"
Options:
  - label: "シンボル/関数のリネーム"
    description: "関数、変数、クラス名をコードベース全体で変更"
  - label: "モジュール/サービスへの抽出"
    description: "ロジックを別モジュールまたはサービスに分離"
  - label: "重複コードの統合"
    description: "重複パターンを共通ユーティリティに統合"
  - label: "コードのクリーンアップ"
    description: "不要なコード、デバッグ用コード、未使用の関数・変数を削除"
```

選択後、具体的な対象を入力させる。

**注意**: 「ファイル構造の再編成」は「Other」から自由入力で指定可能。

## Execution Steps

### Step 1: Session Initialization

Generate session ID and create directory structure:

```
Session ID: refactor-{YYYYMMDD}-{HHMMSS}

Directories:
.sd/refactor/checkpoints/{session-id}/
.sd/refactor/plans/{session-id}/
```

Create initial checkpoint (checkpoint-000-init):

```bash
# Stash current state or create branch
git stash push -m "refactor-checkpoint-000-init"
# OR
git checkout -b refactor/{session-id}
```

Output marker: `REFACTOR_SESSION_INIT`

### Step 2: Parallel Impact Analysis

Launch 3 agents via Task tool **IN PARALLEL** (single message, multiple tool calls):

#### Agent 1: Scope Agent

```
Prompt: Analyze the scope of refactoring: "$ARGUMENTS"

Find:
1. All files that need modification
2. Dependency graph (what imports what)
3. Call sites for affected symbols
4. External API impacts

Output: File list with dependency order
```

#### Agent 2: Pattern Agent

```
Prompt: Detect patterns related to: "$ARGUMENTS"

Find:
1. Naming conventions in the codebase
2. Similar refactoring patterns already applied
3. Code patterns to preserve
4. Anti-patterns to fix

Output: Pattern guidelines for transformation
```

#### Agent 3: Risk Agent

```
Prompt: Assess risks for refactoring: "$ARGUMENTS"

Analyze:
1. Test coverage of affected code
2. Breaking change potential
3. External dependency risks
4. Rollback complexity

Output: Risk matrix with mitigation strategies
```

### Step 3: Synthesis Report

Combine all agent outputs into analysis report:

```markdown
# Refactoring Analysis Report

## Session Info
- ID: {session-id}
- Scope: $ARGUMENTS
- Timestamp: {datetime}

## Scope Analysis
{Scope Agent output}

## Pattern Guidelines
{Pattern Agent output}

## Risk Assessment
{Risk Agent output}

## Recommended Batch Order
1. Batch A: {files} - {reason}
2. Batch B: {files} - {reason}
...

## Estimated Effort
- Files: {count}
- Batches: {count}
- Risk Level: {low/medium/high}
```

Save to: `.sd/refactor/plans/{session-id}/analysis-report.md`

### Step 4: User Confirmation

AskUserQuestionで確認:

```yaml
Question: "分析完了。{N}ファイルが{M}バッチに影響。続行しますか？"
Header: "続行"
Options:
  - label: "はい、実行計画を生成"
    description: "/refactor:planでバッチマニフェストを作成"
  - label: "影響ファイルを表示"
    description: "決定前に全ファイルリストを表示"
  - label: "スコープを変更"
    description: "リファクタリング範囲を調整して再分析"
  - label: "中止"
    description: "リファクタリングセッションをキャンセル"
```

### Step 5: Next Steps

ユーザー選択に応じて:

- **はい**: `REFACTOR_INIT_COMPLETE`を出力し、`/refactor:plan`を提案
- **影響ファイル表示**: ファイルリストを表示後、再度確認
- **スコープ変更**: 新しいスコープを入力させ、Step 2から再開
- **中止**: セッションディレクトリをクリーンアップし、`REFACTOR_ABORTED`を出力

## Output Markers

| Marker | Meaning |
|--------|---------|
| `REFACTOR_SESSION_INIT` | Session initialized |
| `REFACTOR_INIT_COMPLETE` | Analysis complete, ready for plan |
| `REFACTOR_ABORTED` | Session cancelled |

## Session Files Created

```
.sd/refactor/
├── checkpoints/{session-id}/
│   └── checkpoint-000-init.json
└── plans/{session-id}/
    └── analysis-report.md
```

## Integration

- Triggers `session-autosave` skill on `REFACTOR_SESSION_INIT`
- Preserves session for `context-autonomy` skill
- Creates checkpoint for `rollback-guard` skill

## Error Handling

| Error | Action |
|-------|--------|
| Git dirty state | Warn user, offer to stash first |
| Agent timeout | Retry with single agent |
| Analysis too large | Suggest scope reduction |

## Example

```
User: /refactor:init rename getUserById to fetchUser across the codebase

Claude:
1. Creates session refactor-20260101-160000
2. Launches 3 parallel agents
3. Synthesizes analysis report
4. Proposes: "15 files affected across 3 batches. Proceed?"
```
