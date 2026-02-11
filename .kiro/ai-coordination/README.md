# AI協調体制管理

## 概要
sd002プロジェクトにおける複数AI間の協調作業を管理するディレクトリ。

## 対応AI（4種類）
| AI | 役割 | 状態 |
|----|------|------|
| Claude Code | 計画・工程管理 | 有効 |
| Codex | レビュー・チェック | 有効 |
| Gemini CLI | 実装 | 有効 |
| Antigravity | 補助・探索 | 有効 |

**廃止**: Cursor, Windsurf（2025-12-30）

## ディレクトリ構造
```
.kiro/ai-coordination/
├── README.md                     # このファイル
├── handoff/
│   └── handoff-log.json          # AI間引き継ぎログ（v2.0.0）
├── workflow/                     # 新ワークフロー管理
│   ├── README.md                 # ワークフロー説明
│   ├── CODEX_GUIDE.md            # Codexレビュー運用ガイド
│   ├── templates/                # テンプレート
│   │   ├── WORK_ORDER.md         # 発注書テンプレート
│   │   ├── IMPLEMENT_REQUEST.md  # 実装指示テンプレート
│   │   ├── REVIEW_REPORT.md      # レビュー結果テンプレート
│   │   └── PROJECT_STATUS.md     # 工程ログテンプレート
│   ├── spec/{案件ID}/            # 案件別発注書・実装指示
│   ├── review/{案件ID}/          # 案件別レビュー結果
│   └── log/{案件ID}/             # 案件別工程ログ
└── docs/                         # 旧体制（並行維持）
    ├── instructions/             # 指示書格納
    │   ├── claude-code/
    │   ├── gemini/
    │   ├── codex/
    │   └── antigravity/
    └── reports/                  # 報告書格納
        ├── claude-code/
        ├── gemini/
        ├── codex/
        └── antigravity/
```

## ワークフロー体制（推奨）

### コマンド一覧
| コマンド | AI | 説明 |
|---------|-----|------|
| `/workflow:init {slug}` | Claude Code | 案件初期化 |
| `/workflow:order {案件ID}` | Claude Code | 発注書作成 |
| `/workflow:request {案件ID} {番号}` | Claude Code | 実装指示作成 |
| `/workflow:status {案件ID}` | Claude Code | 工程状況確認 |
| `/workflow:impl {案件ID} {番号}` | Gemini CLI | 実装実行 |

### 運用フロー（7段階）
```
Phase 1: 発注書作成 (Claude Code)
    ↓
Phase 2: 発注書レビュー (Codex) → 手動運用
    ↓ Approve
Phase 3: 実装指示作成 (Claude Code)
    ↓
Phase 4: 実装 (Gemini CLI)
    ↓
Phase 5: 実装レビュー (Codex) → 手動運用
    ↓ Approve / Request Changes → Phase 6
Phase 6: 修正対応 (Gemini CLI)
    ↓ Approve
Phase 7: 工程完了 (Claude Code)
```

詳細: `workflow/README.md`

## 旧体制（並行維持）

### 指示書の発行
1. 作成場所: `docs/instructions/{自分のAI}/`
2. ファイル名: `YYYY-MM-DD-HH-MM-to-{宛先AI}.md`
3. handoff-log.json を更新

### 報告書の提出
1. 作成場所: `docs/reports/{自分のAI}/`
2. ファイル名: `YYYY-MM-DD-HH-MM-report.md`
3. handoff-log.json を更新（status: completed）

---
最終更新: 2025-12-30
