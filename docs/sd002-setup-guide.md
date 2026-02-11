# SD002フレームワーク導入ガイド v2.5.2

新規プロジェクトにSD002フレームワークを導入する際の手順。

---

## 推奨: 自動展開（/kiro:deploy）

```
/kiro:deploy <target-project-path>
```

これにより以下が自動展開されます：
- CLAUDE.md（スリム版・約100行）
- .claude/rules/（開発ルール集）
- .claude/commands/（スラッシュコマンド）
- .claude/skills/（スキル）
- .kiro/（仕様書・セッション・設定）
- .antigravity/（Antigravityルール）
- docs/（ドキュメント）

---

## 手動導入

### 前提条件

- [ ] Git リポジトリ初期化済み
- [ ] Node.js / npm インストール済み（任意）

### 1. コア設定コピー

```bash
# SD002リポジトリからコピー
cp -r {sd002}/.claude ./
cp -r {sd002}/.kiro ./
cp -r {sd002}/docs ./

# Gemini CLI使用時（オプション）
cp -r {sd002}/.gemini ./

# Antigravity使用時（オプション）
cp -r {sd002}/.antigravity ./
```

### 2. CLAUDE.md生成

テンプレートを参照してプロジェクト固有の設定を作成:
`.claude/skills/kiro-deploy/templates/CLAUDE.md.template`

### 3. プロジェクト固有の調整

- CLAUDE.md: プロジェクト概要・技術スタック更新
- rules/: プロジェクト固有ルールの追加・削除
- materials/: フォルダ作成（必要時）

### 4. 保護対象ファイルの確認（重要）

以下のファイルはプロジェクト直下に残し、cleanup対象外とする:

| ファイル | 説明 | 導入時の注意 |
|---------|------|-------------|
| `agents.md` | エージェント設定 | 既存ファイルがあれば上書きせずマージ |
| `CLAUDE.md` | AI開発司令塔 | 必ず新規作成またはマージ |
| `gemini.md` | Gemini CLI設定 | 既存ファイルがあれば上書きせずマージ |

**重要**: これらのファイルが導入先に既に存在する場合、内容を確認してマージすること。削除・移動は禁止。

---

## 展開されるコンポーネント一覧

### .claude/ 構造（v2.5.0）

```
.claude/
├── commands/                    # スラッシュコマンド
│   ├── cleanup.md               # ファイル整理（必須）
│   ├── cleanup-restore.md       # 復元（必須）
│   ├── cleanup-history.md       # 履歴（必須）
│   ├── sessionread.md           # セッション読込（必須）
│   ├── sessionwrite.md          # セッション保存（必須）
│   ├── dialogue-resolution.md   # 対話型解決法
│   ├── refactor-init.md         # リファクタリング
│   ├── refactor-plan.md
│   ├── refactor-batch.md
│   ├── refactor-rollback.md
│   ├── refactor-complete.md
│   ├── workflow-init.md         # AI協調
│   ├── workflow-order.md
│   ├── workflow-request.md
│   └── workflow-status.md
├── rules/                       # 開発ルール（自動読込）
│   ├── README.md                # ナビゲーション
│   ├── cleanup/                 # ファイル整理
│   │   └── file-organization.md
│   ├── gas/                     # GAS開発
│   │   ├── env-interface.md
│   │   └── gas-constraints.md
│   ├── global/                  # 品質基準
│   │   └── quality-standards.md
│   ├── refactoring/             # リファクタリング
│   │   └── refactoring-system.md
│   ├── session/                 # セッション
│   │   └── session-management.md
│   ├── specs/                   # 仕様書駆動
│   │   └── spec-driven.md
│   ├── testing/                 # テスト
│   │   └── testing-standards.md
│   ├── troubleshooting/         # 問題解決
│   │   └── dialogue-resolution.md
│   ├── workflow/                # AI協調
│   │   └── ai-coordination.md
│   └── ralph-loop.md            # Ralph Loop
└── skills/                      # スキル
    ├── dialogue-resolution/
    ├── kiro-deploy/
    ├── context-autonomy/
    ├── session-autosave/
    └── rollback-guard/
```

### .kiro/ 構造

```
.kiro/
├── specs/                # 仕様書
├── steering/             # ステアリング文書
├── sessions/             # セッション管理
├── cleanup/              # Cleanup Toolアーカイブ
├── refactor/             # リファクタリングセッション
├── settings/             # 設定・テンプレート
└── ai-coordination/      # AI協調ワークフロー
```

### .antigravity/ 構造（Antigravity用）

```
.antigravity/
└── rules.md              # プロジェクト固有ルール
```

### プロジェクトルート

```
project/
├── CLAUDE.md             # AI開発司令塔（約100行）
├── .antigravity/         # Antigravityルール
│   └── rules.md
├── materials/            # 参考資料・成果物
│   ├── csv/
│   ├── excel/
│   ├── pdf/
│   ├── images/
│   └── text/
├── src/                  # ビジネスロジック
├── tests/                # テスト
└── docs/                 # ドキュメント
```

---

## CLAUDE.md設計原則

### スリム化ルール（100〜300行）

| 記載する | 記載しない |
|---------|-----------|
| プロジェクト概要 | 詳細な手順 |
| 設計原則（箇条書き） | フロー図・ワークフロー詳細 |
| コマンド一覧 | コマンドの使い方 |
| クリティカルルール | 網羅的なルール |
| ルール参照テーブル | ルール本文 |

### 詳細の配置先

| 内容 | 配置先 |
|-----|--------|
| 開発ルール詳細 | `.claude/rules/` |
| セッション履歴 | `.kiro/sessions/` |
| 仕様書 | `.kiro/specs/` |
| トラブル解決ログ | `docs/troubleshooting/` |
| 進捗・作業ログ | `docs/` または `.kiro/` |

---

## 3フェーズ開発戦略

```
┌─────────────────────────────────────────────┐
│  序盤: 計画フェーズ                          │
│  - 仕様書ファースト                          │
│  - /kiro:spec-init → requirements → design  │
├─────────────────────────────────────────────┤
│  中盤: 実装フェーズ                          │
│  - AI協調ワークフロー                        │
│  - Ralph Loop（テスト完了まで自動修正）      │
├─────────────────────────────────────────────┤
│  終盤: 完成フェーズ                          │
│  - /dialogue-resolution（エラー収束しない時）│
│  - 本番モード（品質ゲート全通過）            │
└─────────────────────────────────────────────┘
```

---

## 導入後の確認

### 必須コマンド確認（最重要）

以下のコマンドが存在することを必ず確認:

```bash
ls -la .claude/commands/cleanup*.md
ls -la .claude/commands/session*.md
```

**必須コマンド一覧:**

| コマンド | ファイル | 説明 |
|---------|---------|------|
| `/cleanup` | `cleanup.md` | ファイル整理 |
| `/cleanup:restore` | `cleanup-restore.md` | 復元 |
| `/cleanup:history` | `cleanup-history.md` | 履歴 |
| `/sessionread` | `sessionread.md` | セッション読込 |
| `/sessionwrite` | `sessionwrite.md` | セッション保存 |

**不足している場合**: sd002の`.claude/commands/`からコピーすること。

### ルール確認
```bash
ls -la .claude/rules/
```

期待される出力:
```
README.md
cleanup/
gas/
global/
refactoring/
session/
specs/
testing/
troubleshooting/
workflow/
ralph-loop.md
```

### 全コマンド確認
```bash
ls -la .claude/commands/
```

### CLAUDE.md行数確認
```bash
wc -l CLAUDE.md
```
→ 100〜300行であること

---

## トラブルシューティング

### ルールが認識されない
1. `.claude/rules/` 配下に `.md` ファイルが存在するか確認
2. Claude Code を再起動

### コマンドが認識されない
1. `/help` でコマンド一覧を確認
2. `.claude/commands/` 配下にファイルが存在するか確認

### CLAUDE.mdが肥大化した場合
1. 詳細を `.claude/rules/` に移動
2. CLAUDE.mdには「詳細は rules/ 参照」と記載
3. 進捗・ログは `docs/` または `.kiro/` に移動

---

## 更新履歴

| バージョン | 日付 | 内容 |
|-----------|------|------|
| v2.5.2 | 2026-01-02 | Antigravity対応（.antigravity/rules.md）追加 |
| v2.5.1 | 2026-01-02 | 必須コマンド確認セクション追加、cleanup/session必須明記 |
| v2.5.0 | 2026-01-02 | CLAUDE.mdスリム化、rules構造刷新、Cleanup Tool追加、materials/導入 |
| v2.4.0 | 2026-01-02 | Materials Folder、Cleanup Tool追加 |
| v2.3.0 | 2025-12-31 | kiro-deploy スキル追加、3フェーズ開発戦略 |
| v2.2.0 | 2025-12-30 | AI協調ワークフロー追加 |
