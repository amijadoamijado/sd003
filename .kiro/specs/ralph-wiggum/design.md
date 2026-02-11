# Ralph Wiggum 技術設計書

## 基本情報
- **機能名**: Ralph Wiggum - Night Mode Autonomous Execution System
- **バージョン**: 1.1.0
- **ステータス**: 設計中（レビュー反映済）
- **レビュー**: Architecture/Risk/Integration Agent (3並列レビュー完了)

## 1. アーキテクチャ概要

### 1.1 システム構成

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Ralph Wiggum System v1.0                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        Two-Layer Architecture                         │   │
│  │                                                                       │   │
│  │   ┌─────────────────────────┐    ┌─────────────────────────┐         │   │
│  │   │    Daytime Layer        │    │    Nighttime Layer      │         │   │
│  │   │    (sd002-loop-*)       │    │    (Ralph Wiggum)       │         │   │
│  │   ├─────────────────────────┤    ├─────────────────────────┤         │   │
│  │   │ max-iterations: 15-20  │    │ max-iterations: 60      │         │   │
│  │   │ Single task focus      │    │ Multi-task queue        │         │   │
│  │   │ Human available        │    │ Autonomous              │         │   │
│  │   │ dialogue-resolution    │    │ Auto-recovery           │         │   │
│  │   └─────────────────────────┘    └─────────────────────────┘         │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    Nighttime Execution Flow                           │   │
│  │                                                                       │   │
│  │  ┌─────────────┐                                                      │   │
│  │  │ Queue Loader│ ← nightly-queue.md                                   │   │
│  │  └──────┬──────┘                                                      │   │
│  │         │                                                             │   │
│  │         ▼                                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────┐      │   │
│  │  │              Task Execution Loop                             │      │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │      │   │
│  │  │  │  Task 1  │→│  Task 2  │→│  Task 3  │→│  Task N  │        │      │   │
│  │  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘        │      │   │
│  │  │       │            │            │            │               │      │   │
│  │  │       └────────────┴────────────┴────────────┘               │      │   │
│  │  │                    │                                         │      │   │
│  │  │                    ▼                                         │      │   │
│  │  │           ┌──────────────┐                                   │      │   │
│  │  │           │ Quality Gate │                                   │      │   │
│  │  │           └──────┬───────┘                                   │      │   │
│  │  │                  │                                           │      │   │
│  │  │        ┌─────────┴─────────┐                                 │      │   │
│  │  │        ▼                   ▼                                 │      │   │
│  │  │   ┌─────────┐        ┌─────────────┐                         │      │   │
│  │  │   │  PASS   │        │    FAIL     │                         │      │   │
│  │  │   └────┬────┘        └──────┬──────┘                         │      │   │
│  │  │        │                    │                                │      │   │
│  │  │        │                    ▼                                │      │   │
│  │  │        │          ┌─────────────────┐                        │      │   │
│  │  │        │          │ Recovery Engine │                        │      │   │
│  │  │        │          └────────┬────────┘                        │      │   │
│  │  │        │                   │                                 │      │   │
│  │  │        │         ┌─────────┴─────────┐                       │      │   │
│  │  │        │         ▼                   ▼                       │      │   │
│  │  │        │    ┌─────────┐        ┌──────────┐                  │      │   │
│  │  │        │    │Recovered│        │  SKIP    │                  │      │   │
│  │  │        │    └────┬────┘        └────┬─────┘                  │      │   │
│  │  │        │         │                  │                        │      │   │
│  │  │        └─────────┴──────────────────┘                        │      │   │
│  │  │                    │                                         │      │   │
│  │  │                    ▼                                         │      │   │
│  │  │           ┌──────────────┐                                   │      │   │
│  │  │           │  Checkpoint  │                                   │      │   │
│  │  │           └──────────────┘                                   │      │   │
│  │  └──────────────────────────────────────────────────────────────┘      │   │
│  │                    │                                                   │   │
│  │         ┌──────────┴──────────┐                                        │   │
│  │         ▼                     ▼                                        │   │
│  │  ┌─────────────────┐   ┌─────────────────┐                             │   │
│  │  │NIGHTLY_COMPLETE │   │NIGHTLY_BLOCKED  │                             │   │
│  │  └─────────────────┘   └─────────────────┘                             │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 コンポーネント設計（Adapter-Core分離）

```
┌─────────────────────────────────────────────────────────────────┐
│                    Adapter-Core Architecture                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐                                             │
│  │ External Data   │ nightly-queue.md, checkpoints/*.json       │
│  └────────┬────────┘                                             │
│           │                                                      │
│  ┌────────▼────────┐                                             │
│  │  Input Adapters │                                             │
│  │  ├ QueueAdapter │ → Markdown → IQueue                        │
│  │  └ CheckpointAdapter → JSON → ICheckpoint                    │
│  └────────┬────────┘                                             │
│           │                                                      │
│     Standard Interfaces (IQueue, ITask, ICheckpoint)            │
│           │                                                      │
│  ┌────────▼────────┐                                             │
│  │      Core       │                                             │
│  │  ├ TaskExecutor │ IQueue → 実行制御                           │
│  │  ├ RecoveryCore │ エラー → リカバリー戦略                     │
│  │  ├ PromiseCore  │ 出力 → IPromise                             │
│  │  └ CheckpointCore → 状態管理                                  │
│  └────────┬────────┘                                             │
│           │                                                      │
│  ┌────────▼────────┐                                             │
│  │ Output Adapters │                                             │
│  │  ├ LogAdapter   │ → logs/*.md                                 │
│  │  ├ ReportAdapter│ → TEST_REPORT                               │
│  │  └ StatsAdapter │ → weekly-stats.md                           │
│  └─────────────────┘                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

| コンポーネント | 層 | 責務 | 実装ファイル |
|---------------|-----|------|-------------|
| QueueAdapter | Adapter | nightly-queue.md → IQueue変換 | adapters/queue.ts |
| CheckpointAdapter | Adapter | JSON ←→ ICheckpoint変換 | adapters/checkpoint.ts |
| TaskExecutor | Core | タスク実行制御 | core/executor.ts |
| RecoveryCore | Core | 7パターン自動復旧 | core/recovery.ts |
| PromiseCore | Core | 完了マーカー検出・検証 | core/promise.ts |
| CheckpointCore | Core | 状態管理・マイグレーション | core/checkpoint.ts |
| LogAdapter | Adapter | ログ出力 | adapters/log.ts |
| ReportAdapter | Adapter | TEST_REPORT生成 | adapters/report.ts |
| Quality Gate | External | build/test/lint実行 | 既存npm scripts |

## 2. 詳細設計

### 2.1 ディレクトリ構造

```
.kiro/ralph/
├── nightly-queue.md              # 当日の実行キュー
├── README.md                     # システム説明
├── prompts/
│   └── impl-all.md               # 実装プロンプトテンプレート
├── logs/
│   ├── {date}-result.md          # 成功ログ
│   ├── {date}-blocked.md         # ブロックログ
│   └── {date}-errors.md          # エラーログ
├── recovery/
│   ├── strategies.md             # リカバリー戦略定義
│   ├── checkpoints/
│   │   ├── latest.json           # 最新チェックポイント
│   │   └── {timestamp}.json      # 履歴
│   └── fallback-prompts/
│       ├── retry-single.md       # 単一タスクリトライ
│       ├── skip-and-continue.md  # スキップ＆継続
│       └── graceful-exit.md      # 安全終了
├── weekly/
│   ├── TEMPLATE/
│   │   ├── plan.md               # 週次計画テンプレート
│   │   └── daily/
│   │       └── {day}.md          # 日別キューテンプレート
│   └── {YYYY-Www}/               # 実際の週次データ
│       ├── plan.md
│       ├── daily/
│       └── review.md
├── backlog.md                    # 未着手タスクプール
└── metrics/
    └── weekly-stats.md           # 週次統計
```

### 2.2 nightly-queue.md フォーマット

```markdown
# Nightly Queue

## メタ情報
| 項目 | 値 |
|------|-----|
| 実行予定 | 2026-01-04 23:00 |
| 最大反復 | 60 |
| 最終完了マーカー | NIGHTLY_COMPLETE |

## 実行設定
```yaml
ralph_config:
  max_iterations: 60
  completion_promise: "NIGHTLY_COMPLETE"
  blocked_promise: "NIGHTLY_BLOCKED"
  git_commit_frequency: "per_task"
  quality_gates:
    - "npm run build"
    - "npm test"
    - "npm run lint"
```

## 実行キュー

### [P1] タスク名
優先度: 最高
推定反復: 20-25

#### 対象タスク
- [ ] タスク詳細1
- [ ] タスク詳細2

#### 完了条件
- npm test 通過

#### 完了マーカー
<promise>TASK1_DONE</promise>
```

### 2.3 リカバリーエンジン（v1.1: 7パターン対応）

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         Recovery Engine v1.1                                │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  入力: エラー情報（exit code, message, stack trace, 履歴）                  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Pattern Matcher                                   │   │
│  │                                                                      │   │
│  │  Pattern 1: Build Error                                              │   │
│  │  ├── 検知: npm run build exit != 0                                   │   │
│  │  ├── 対応: 型エラー自動修正                                          │   │
│  │  └── 最大試行: 3回                                                   │   │
│  │                                                                      │   │
│  │  Pattern 2: Test Failure                                             │   │
│  │  ├── 検知: npm test exit != 0                                        │   │
│  │  ├── 対応: 実装修正 > テスト修正 > スキップ                          │   │
│  │  └── 最大試行: 3回                                                   │   │
│  │                                                                      │   │
│  │  Pattern 3: Lint Error                                               │   │
│  │  ├── 検知: npm run lint exit != 0                                    │   │
│  │  ├── 対応: --fix + 手動修正                                          │   │
│  │  └── 最大試行: 3回                                                   │   │
│  │                                                                      │   │
│  │  Pattern 4: Infinite Loop (Adaptive)                                 │   │
│  │  ├── 検知: 編集距離 + ファイル重複の適応的検知                       │   │
│  │  ├── 対応: チェックポイント保存 + スキップ                           │   │
│  │  └── 閾値: calculateThreshold(editPattern)                           │   │
│  │                                                                      │   │
│  │  Pattern 5: External Dependency (Circuit Breaker)                    │   │
│  │  ├── 検知: ネットワーク/API/認証エラー                               │   │
│  │  ├── 対応: 指数バックオフ + サーキットブレーカー                     │   │
│  │  └── 状態: CLOSED → OPEN → HALF_OPEN                                 │   │
│  │                                                                      │   │
│  │  Pattern 6: Unexpected (Resumable)                                   │   │
│  │  ├── 検知: 上記に該当しない                                          │   │
│  │  ├── 対応: graceful-exit実行（再開可能）                             │   │
│  │  └── 状態: GracefulExit { canResume: true }                          │   │
│  │                                                                      │   │
│  │  Pattern 7: Recovery Exhaustion (v1.1 NEW)                           │   │
│  │  ├── 検知: 同一タスクで3回以上リカバリー失敗                         │   │
│  │  ├── 対応: タスクスキップ + エスカレーションフラグ                   │   │
│  │  └── 出力: { escalate: true, suggestedAction: string }               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  出力: 復旧成功 / スキップ / 終了 / エスカレーション                        │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

### 2.3.1 インターフェース定義（v1.1追加）

```typescript
// interfaces/IQueue.ts
interface ITask {
  id: string;
  priority: "P0" | "P1" | "P2";
  estimatedIterations: number;
  completionPromise: string;
  qualityGates: string[];
  specReference?: string;  // REQ-RW-xxx へのリンク
}

interface IQueue {
  tasks: ITask[];
  maxIterations: number;
  completionPromise: string;
  blockedPromise: string;
}

// interfaces/IPromise.ts
interface IPromise {
  marker: string;
  detectedAt: Date;
  context: "stdout" | "stderr" | "file";
  confidence: number;  // 0-1
}

// interfaces/ICheckpoint.ts
interface ICheckpoint {
  version: "1.0" | "1.1";
  schemaRevision: number;
  timestamp: string;
  iteration: number;
  queueFile: string;
  completedTasks: string[];
  currentTask: ICurrentTask | null;
  skippedTasks: ISkippedTask[];
  gitState: IGitState;
  qualityGateStatus: IQualityGateStatus;
  errors: IError[];
  warnings: string[];
  checksum?: string;  // v1.1: 破損検知用
}

// interfaces/IRecoveryResult.ts
interface IRecoveryResult {
  success: boolean;
  action: "recovered" | "skip" | "exit" | "escalate";
  pattern: number;  // 1-7
  details: string;
  escalate?: {
    reason: string;
    suggestedAction: string;
  };
}

// interfaces/IGracefulExit.ts
interface IGracefulExit {
  reason: string;
  recoveryPoint: ICheckpoint;
  canResume: boolean;
  suggestedAction: string;
  timestamp: Date;
}
```

### 2.3.2 サーキットブレーカー設計（Pattern 5強化）

```
┌────────────────────────────────────────────────────────────────┐
│                    Circuit Breaker States                       │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌──────────┐  failure > threshold   ┌──────────┐             │
│   │  CLOSED  │ ────────────────────→  │   OPEN   │             │
│   │ (正常)   │                        │ (遮断)   │             │
│   └────┬─────┘                        └────┬─────┘             │
│        │                                   │                    │
│        │ success                           │ timeout (30s)      │
│        │                                   │                    │
│        │          ┌─────────────┐          │                    │
│        └────────  │  HALF_OPEN  │ ←────────┘                    │
│                   │  (試行中)   │                               │
│                   └──────┬──────┘                               │
│                          │                                      │
│              success → CLOSED                                   │
│              failure → OPEN                                     │
│                                                                 │
│   Config:                                                       │
│   - failureThreshold: 3                                         │
│   - timeout: 30000ms                                            │
│   - halfOpenRequests: 1                                         │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### 2.4 チェックポイント仕様（v1.1: マイグレーション対応）

```json
{
  "version": "1.1",
  "schemaRevision": 2,
  "timestamp": "2026-01-04T02:30:00+09:00",
  "iteration": 25,
  "queue_file": "nightly-queue.md",
  "completed_tasks": ["RALPH_TASK1_DONE", "RALPH_TASK2_DONE"],
  "current_task": {
    "id": "TASK3",
    "started_at": "2026-01-04T02:15:00+09:00",
    "attempts": 2,
    "recoveryPatterns": [1, 2]
  },
  "skipped_tasks": [
    {
      "id": "TASK_X",
      "reason": "Pattern 7: Recovery exhaustion",
      "escalate": true
    }
  ],
  "git_state": {
    "commit_hash": "abc123def456",
    "uncommitted_changes": false
  },
  "quality_gate_status": {
    "build": "pass",
    "test": "pass",
    "lint": "pass"
  },
  "errors": [],
  "warnings": ["Coverage at 78%, target 80%"],
  "checksum": "sha256:abc123..."
}
```

### 2.4.1 チェックポイントマイグレーション設計（v1.1追加）

```typescript
// core/CheckpointMigrator.ts
class CheckpointMigrator {
  private migrations: Map<string, MigrationFn> = new Map([
    ["1.0->1.1", this.migrate_1_0_to_1_1],
  ]);

  migrate(checkpoint: ICheckpoint, targetVersion: string): ICheckpoint {
    let current = checkpoint;
    while (current.version !== targetVersion) {
      const key = `${current.version}->${this.nextVersion(current.version)}`;
      const migrateFn = this.migrations.get(key);
      if (!migrateFn) throw new Error(`No migration path: ${key}`);
      current = migrateFn(current);
    }
    return current;
  }

  private migrate_1_0_to_1_1(cp: ICheckpoint): ICheckpoint {
    return {
      ...cp,
      version: "1.1",
      schemaRevision: 2,
      checksum: this.calculateChecksum(cp),
      // RALPH_ プレフィックス追加
      completedTasks: cp.completedTasks.map(t =>
        t.startsWith("RALPH_") ? t : `RALPH_${t}`
      ),
    };
  }

  validateIntegrity(checkpoint: ICheckpoint): boolean {
    if (!checkpoint.checksum) return true;  // v1.0は検証なし
    return checkpoint.checksum === this.calculateChecksum(checkpoint);
  }
}
```

### 2.4.2 同時実行保護（v1.1追加）

```
┌────────────────────────────────────────────────────────────────┐
│                    Execution Lock Mechanism                     │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Lock File: .kiro/ralph/.lock                                   │
│                                                                 │
│  Content:                                                       │
│  {                                                              │
│    "pid": 12345,                                                │
│    "started_at": "2026-01-04T23:00:00+09:00",                  │
│    "queue_file": "nightly-queue.md",                            │
│    "timeout": 21600000  // 6時間                                │
│  }                                                              │
│                                                                 │
│  Lock Acquisition:                                              │
│  1. Check if .lock exists                                       │
│  2. If exists, check timeout                                    │
│     - Expired → Delete and acquire                              │
│     - Active → Abort with warning                               │
│  3. Create .lock with current info                              │
│                                                                 │
│  Lock Release:                                                  │
│  - On normal completion: Delete .lock                           │
│  - On graceful-exit: Keep .lock (resume possible)               │
│  - On crash: Timeout handles cleanup                            │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### 2.4.3 朝のレビュー自動生成（v1.1追加）

```
┌────────────────────────────────────────────────────────────────┐
│                    Morning Handoff Flow                         │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  夜間完了時 (RALPH_NIGHTLY_COMPLETE or RALPH_NIGHTLY_BLOCKED)   │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ReportAdapter.generateMorningReport()                    │   │
│  │                                                          │   │
│  │ 出力:                                                    │   │
│  │ .kiro/ai-coordination/workflow/review/ralph/             │   │
│  │ └── NIGHTLY_REPORT_{YYYYMMDD}.md                         │   │
│  │                                                          │   │
│  │ 内容:                                                    │   │
│  │ - 完了タスク一覧                                         │   │
│  │ - スキップタスク（エスカレーション理由付き）             │   │
│  │ - 品質ゲート結果                                         │   │
│  │ - 推奨アクション                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│       │                                                         │
│       ▼                                                         │
│  handoff-log.json に記録                                        │
│  {                                                              │
│    "type": "nightly_report",                                    │
│    "from": "Ralph Wiggum",                                      │
│    "to": "Morning Review",                                      │
│    "file": "workflow/review/ralph/NIGHTLY_REPORT_20260104.md"  │
│  }                                                              │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### 2.5 週次計画フォーマット

```markdown
# 週次計画 - {YYYY}年第{W}週

## 期間
{start_date} (Mon) 〜 {end_date} (Fri)

## 週次目標
### 必達目標
1. ...

### 努力目標
1. ...

## リソース配分
| 曜日 | 日中（協調WF） | 夜間（ralph） |
|------|--------------|--------------|
| Mon | ... | ... |
| ... | ... | ... |

## 日別キュー割り当て
### Monday
nightly-queue: ...
推定反復: ...
想定成果: ...

## 依存関係マップ
```

## 3. インターフェース設計

### 3.1 コマンドインターフェース

| コマンド | 入力 | 出力 |
|---------|------|------|
| `/ralph-wiggum:run` | nightly-queue.md | 実行結果ログ |
| `/ralph-wiggum:status` | - | 現在の実行状況 |
| `/ralph-wiggum:plan` | 週番号 | 週次計画テンプレート |

### 3.2 完了マーカーインターフェース

| マーカー | 意味 | トリガー |
|---------|------|---------|
| `<promise>XXX_DONE</promise>` | タスク完了 | タスク終了時 |
| `<promise>NIGHTLY_COMPLETE</promise>` | 全完了 | 全タスク終了 |
| `<promise>NIGHTLY_BLOCKED</promise>` | ブロック | リカバリー不可 |

### 3.3 既存システム連携

| 連携先 | 連携方法 |
|--------|---------|
| sd002-loop-* | 日中/夜間の役割分担（直接連携なし） |
| TodoWrite | タスク進捗管理 |
| AI協調WF | 夜間成果の朝レビュー |

## 4. 実装場所

| ファイル | 役割 |
|---------|------|
| `.claude/commands/ralph-wiggum-run.md` | メイン実行コマンド |
| `.claude/commands/ralph-wiggum-status.md` | 状況確認コマンド |
| `.claude/commands/ralph-wiggum-plan.md` | 週次計画作成コマンド |
| `.kiro/ralph/` | ランタイムディレクトリ |
| `.claude/rules/ralph-loop.md` | ルール追記（Night Mode参照） |

## 5. 依存関係

| 依存 | 用途 |
|------|------|
| TodoWrite | タスク進捗管理 |
| Bash | npm scripts実行 |
| Read/Write/Edit | ファイル操作 |
| Git | コミット自動化 |

## 6. セキュリティ考慮

| リスク | 対策 |
|--------|------|
| 破壊的git操作 | force push, hard reset禁止 |
| 設定ファイル変更 | CLAUDE.md, package.json変更禁止 |
| 無限ループ | max-iterations制限、無限ループ検知 |
| API消費 | 統計でコスト監視 |

---
最終更新: 2026-01-04
