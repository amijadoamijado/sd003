# AI協調体制

## 対応AI（4種類）
| AI | 役割 | コマンド |
|----|------|---------|
| Claude Code | 計画・工程管理 | `/workflow:init`, `/workflow:order`, `/workflow:request`, `/workflow:status` |
| Codex | レビュー・チェック | `/workflow:review`（自動連鎖） |
| Gemini CLI | 実装 | `/workflow:impl`（自動連鎖） |
| Antigravity | E2Eテスト・探索的調査・本番確認 | `/workflow:test`（自動連鎖） |

**廃止**: Cursor, Windsurf

## ワークフローコマンド
| コマンド | 説明 |
|----------|------|
| `/workflow:init {slug}` | 案件初期化 |
| `/workflow:order {案件ID}` | 発注書作成 |
| `/workflow:request {案件ID} {番号}` | 実装指示作成（Gemini CLI向け） |
| `/workflow:test {案件ID} {番号}` | テスト依頼作成（Antigravity向け） |
| `/workflow:status {案件ID}` | 工程状況確認 |
| `/workflow:impl {案件ID} {番号}` | 実装実行（Gemini CLI）→ review自動連鎖 |
| `/workflow:review {案件ID} {番号}` | レビュー依頼・実行（Codex）|

---

## 依頼・報告の保存ルール（必須）

### 絶対ルール
**全AIへの依頼・報告は `.kiro/ai-coordination/` 配下に統一する**

| ファイル種別 | 保存先 | 例 |
|-------------|--------|-----|
| 発注書 | `workflow/spec/{案件ID}/WORK_ORDER.md` | `workflow/spec/20260102-001-test/WORK_ORDER.md` |
| 実装指示 | `workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{NNN}.md` | `IMPLEMENT_REQUEST_001.md` |
| テスト依頼 | `workflow/spec/{案件ID}/TEST_REQUEST_{NNN}.md` | `TEST_REQUEST_001.md` |
| レビュー結果 | `workflow/review/{案件ID}/REVIEW_{種別}_{NNN}.md` | `REVIEW_IMPL_001.md` |
| テスト報告 | `workflow/review/{案件ID}/TEST_REPORT_{NNN}.md` | `TEST_REPORT_001.md` |

### 禁止事項
| 禁止 | 理由 |
|------|------|
| `.antigravity/` に依頼書を作成 | 案件と紐付かない |
| プロジェクトルートに依頼書を作成 | 散らかる |
| テンプレートなしで依頼書を作成 | 形式がバラバラになる |

### AI別設定フォルダの用途
| フォルダ | 用途 | 依頼書を置く？ |
|---------|------|--------------|
| `.antigravity/` | Antigravityの動作ルール設定 | **NO** |
| `.claude/` | Claude Codeの動作ルール設定 | **NO** |
| `.kiro/ai-coordination/` | 依頼・報告・ログの集約 | **YES** |

---

## 運用フロー（7段階 + テストフェーズ）

```
Phase 1: 発注書作成 (Claude Code)
    ↓
Phase 2: 発注書レビュー (Codex)
    ↓ Approve
Phase 3: 実装指示作成 (Claude Code)
    ↓ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ↓ ★ 自動連鎖チェーン（/workflow:request で一括実行）
    ↓ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 4: 実装 (Gemini CLI)          ← /workflow:impl が自動実行
    ↓
Phase 5: 実装レビュー (Codex)       ← /workflow:review が自動実行
    ↓ Approve / Request Changes → Phase 6
Phase 6: 修正対応 (Gemini CLI)
    ↓ Approve
Phase 7: E2Eテスト (Antigravity) ★
    ↓ Pass
Phase 8: 工程完了 (Claude Code)
```

## 自動連鎖ルール（省略禁止）

**コマンド間の自動連鎖は仕組みとして強制される。AIの「気分」で省略することは不可。**

| トリガー | 自動実行 | 説明 |
|---------|---------|------|
| `/workflow:request` 完了 | → `/workflow:impl` | 指示書作成後、Gemini CLI実行は必須 |
| `/workflow:impl` 完了 | → `/workflow:review` | Gemini実装後、Codexレビュー依頼は必須 |
| `/workflow:review` Approve | → `/workflow:test` | レビュー承認後、TEST_REQUEST自動作成＋Antigravityディスパッチ |

### 連鎖フロー図
```
/workflow:request {ID} {N}
  ├── Step 1-7: 実装指示書作成 + handoff記録
  └── Step 8: /workflow:impl {ID} {N} を自動実行
        ├── Step 1-8: Gemini CLI実行 → 検証 → コミット → handoff記録
        └── Step 9: /workflow:review {ID} {N} を自動実行
              ├── Step 1-8: レビュー依頼作成 → Codex実行 → 結果保存 → 完了報告
              └── Step 9 (Approve時): /workflow:test {ID} {N} を自動実行
                    ├── Step 1-3: TEST_REQUEST作成 → handoff記録
                    └── Step 4-6: Antigravityディスパッチ → 結果確認 → 完了報告
```

**違反パターン（禁止）**:
- 指示書を作っただけで止まる
- Gemini実装が終わっただけで止まる
- レビューApprove後にテスト依頼を出さずに止まる
- 「次のステップ」を案内して終わる（案内ではなく実行せよ）

---

## Antigravityワークフロー

### 役割の詳細
| 役割 | 説明 |
|------|------|
| E2Eテスト | 本番/ステージング環境でのUI確認 |
| 探索的テスト | 仕様外の動作確認、UX検証 |
| スクリーンショット取得 | 証跡収集（テスト報告に添付） |
| 本番確認 | デプロイ後の動作確認 |

### テスト依頼フロー

```
1. Claude Code: TEST_REQUEST_{NNN}.md を作成
   → 保存先: .kiro/ai-coordination/workflow/spec/{案件ID}/
   → handoff-log.json に記録

2. Antigravity: テスト実行
   → TEST_REQUEST を参照
   → スクリーンショット取得

3. Antigravity: TEST_REPORT_{NNN}.md を作成
   → 保存先: .kiro/ai-coordination/workflow/review/{案件ID}/
   → handoff-log.json に記録

4. Claude Code: 報告を確認し次のアクションを決定
```

### テンプレート
| テンプレート | 用途 |
|-------------|------|
| `templates/TEST_REQUEST.md` | Antigravityへのテスト依頼 |
| `templates/TEST_REPORT.md` | Antigravityからのテスト報告 |

---

## handoff-log.json の記録（必須）

**依頼・報告を発行したら必ず handoff-log.json に記録する**

### 記録すべきhandoff_type
| type | 説明 | from | to |
|------|------|------|-----|
| `work_order_review` | 発注書レビュー依頼 | Claude Code | Codex |
| `implement_request` | 実装指示発行 | Claude Code | Gemini CLI |
| `implement_complete` | 実装完了・レビュー依頼 | Gemini CLI | Codex |
| `review_complete` | レビュー完了 | Codex | Claude Code |
| `test_request` | テスト依頼発行 | Claude Code | Antigravity |
| `test_report` | テスト完了報告 | Antigravity | Claude Code |
| `exploration_request` | 探索的調査依頼 | Claude Code | Antigravity |
| `exploration_report` | 探索的調査報告 | Antigravity | Claude Code |

### 記録フォーマット
```json
{
  "timestamp": "2026-01-02T10:00:00+09:00",
  "type": "test_request",
  "project_id": "20260102-001-test",
  "from": "Claude Code",
  "to": "Antigravity",
  "file": "workflow/spec/20260102-001-test/TEST_REQUEST_001.md",
  "note": "formatMonth修正の本番確認"
}
```

---

## ディレクトリ構造

```
.kiro/ai-coordination/
├── handoff/handoff-log.json    # 引き継ぎログ（v2.0.0）
├── sessions/                   # AI別セッション記録
│   ├── antigravity/            # Antigravityのセッション
│   ├── claude-code/            # Claude Codeのセッション
│   ├── codex/                  # Codexのセッション
│   └── gemini/                 # Gemini CLIのセッション
├── workflow/
│   ├── README.md               # ワークフロー説明
│   ├── CODEX_GUIDE.md          # Codexレビュー運用ガイド
│   ├── templates/              # テンプレート
│   │   ├── WORK_ORDER.md
│   │   ├── IMPLEMENT_REQUEST.md
│   │   ├── REVIEW_REPORT.md
│   │   ├── PROJECT_STATUS.md
│   │   ├── TEST_REQUEST.md
│   │   └── TEST_REPORT.md
│   ├── spec/{案件ID}/          # 案件別発注書・実装指示・テスト依頼
│   ├── review/{案件ID}/        # 案件別レビュー結果・テスト報告
│   └── log/{案件ID}/           # 案件別工程ログ
```

### AI別記録場所

| AI | セッション | 依頼書受信 | 報告書作成 |
|----|-----------|-----------|-----------|
| Claude Code | `sessions/claude-code/` | - | `workflow/spec/` |
| Codex | `sessions/codex/` | `workflow/spec/` | `workflow/review/` |
| Gemini CLI | `sessions/gemini/` | `workflow/spec/` | `workflow/review/` |
| Antigravity | `sessions/antigravity/` | `workflow/spec/` | `workflow/review/` |

## 命名規則
| 要素 | 規則 | 例 |
|------|------|-----|
| 案件ID | `YYYYMMDD-NNN-slug` | `20251230-001-auth` |
| 発注書 | `WORK_ORDER.md` | 固定 |
| 実装指示 | `IMPLEMENT_REQUEST_NNN.md` | `IMPLEMENT_REQUEST_001.md` |
| テスト依頼 | `TEST_REQUEST_NNN.md` | `TEST_REQUEST_001.md` |
| レビュー結果 | `REVIEW_{種別}_NNN.md` | `REVIEW_IMPL_001.md` |
| テスト報告 | `TEST_REPORT_NNN.md` | `TEST_REPORT_001.md` |

---

## Trigger Words (AUTO-EXECUTE)

**IMPORTANT: BEFORE creating any request/report document, FIRST initialize the project with `/workflow:init`**

### Workflow Initialization

When user mentions a task or feature, FIRST ask or determine:
1. Is this a new project? → `/workflow:init {slug}`
2. Existing project? → Get the project ID (e.g., `20260102-001-test`)

### Trigger Keywords by AI

| AI | Trigger Keywords | Auto Action |
|----|-----------------|-------------|
| Claude Code | "create work order", "create request", "assign to" | Create document using template, save to spec folder |
| Claude Code | "check on Antigravity", "test request to Antigravity" | Create TEST_REQUEST, record handoff |
| Gemini CLI | "implementation complete", "done implementing" | Report to Codex for review |
| Antigravity | "test request", "execute test" | Read TEST_REQUEST, execute, create TEST_REPORT |
| Codex | "review complete", "approved", "request changes" | Create REVIEW_REPORT |

### Japanese Trigger Keywords

| Keyword | AI | Action |
|---------|-----|--------|
| "...に依頼", "...を依頼" | Claude Code | Create request document for target AI |
| "指示書を作成", "作業指示" | Claude Code | Create IMPLEMENT_REQUEST or TEST_REQUEST |
| "テストを依頼" | Claude Code | Create TEST_REQUEST for Antigravity |
| "アンチグラビティに依頼", "アンチグラビティに" | Claude Code | Create TEST_REQUEST for Antigravity |
| "実装完了", "作業完了" | Gemini CLI | Report completion, request review |
| "テスト結果", "報告" | Antigravity | Create TEST_REPORT |
| "レビュー完了" | Codex | Create REVIEW_REPORT |

### Antigravity Aliases (ALL trigger same action)

The following keywords ALL refer to Antigravity and trigger TEST_REQUEST creation:
- `Antigravity` (正式名)
- `antigravity` (小文字)
- `アンチグラビティ` (日本語)

### Auto-Execution Flow

```
User: "Antigravityにテストを依頼して"
         ↓
Claude Code (auto-detect):
  1. Check: Is project initialized?
     → NO: Ask user or auto-init with /workflow:init
     → YES: Get project ID
  2. Create TEST_REQUEST using template
  3. Save to: .kiro/ai-coordination/workflow/spec/{projectID}/
  4. Record in handoff-log.json
  5. Notify user with file path
```

### Enforcement Rules

| Rule | Enforcement |
|------|-------------|
| All requests/reports in `.kiro/ai-coordination/` | MANDATORY |
| Use template for document creation | MANDATORY |
| Record in handoff-log.json | MANDATORY |
| Initialize project before first document | MANDATORY |

---

## 詳細ドキュメント
- `.kiro/ai-coordination/workflow/README.md`
- `.kiro/ai-coordination/workflow/CODEX_GUIDE.md`
