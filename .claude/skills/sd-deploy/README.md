# SD003フレームワーク展開スキル v2.4.0

## 使用方法

```
/sd:deploy <target-project-path>
```

## 展開手順

### Step 1: 対象プロジェクト検証

```bash
TARGET_PROJECT="$1"
if [ ! -d "$TARGET_PROJECT" ]; then
    echo "エラー: 対象プロジェクト '$TARGET_PROJECT' が見つかりません"
    exit 1
fi
echo "対象プロジェクト確認: $TARGET_PROJECT"
```

### Step 2: 既存設定バックアップ

```bash
BACKUP_DIR="$TARGET_PROJECT/.sd003-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 既存ファイルをバックアップ
[ -f "$TARGET_PROJECT/CLAUDE.md" ] && cp "$TARGET_PROJECT/CLAUDE.md" "$BACKUP_DIR/"
[ -d "$TARGET_PROJECT/.claude" ] && cp -r "$TARGET_PROJECT/.claude" "$BACKUP_DIR/"
[ -d "$TARGET_PROJECT/.gemini" ] && cp -r "$TARGET_PROJECT/.gemini" "$BACKUP_DIR/"
[ -d "$TARGET_PROJECT/.sd" ] && cp -r "$TARGET_PROJECT/.sd" "$BACKUP_DIR/"
```

### Step 3: フォルダ構造作成

```bash
# Claude Code
mkdir -p "$TARGET_PROJECT/.claude/commands"
mkdir -p "$TARGET_PROJECT/.claude/commands/sd"  # v2.7.0追加
mkdir -p "$TARGET_PROJECT/.claude/rules/global"
mkdir -p "$TARGET_PROJECT/.claude/rules/troubleshooting"
mkdir -p "$TARGET_PROJECT/.claude/skills/dialogue-resolution"

# Gemini CLI
mkdir -p "$TARGET_PROJECT/.gemini/commands"

# SD
mkdir -p "$TARGET_PROJECT/.sd/specs"
mkdir -p "$TARGET_PROJECT/.sd/steering"
mkdir -p "$TARGET_PROJECT/.sd/sessions"
mkdir -p "$TARGET_PROJECT/.sd/settings/templates"
mkdir -p "$TARGET_PROJECT/.sd/settings/rules"
mkdir -p "$TARGET_PROJECT/.sd/ai-coordination/workflow/templates"
mkdir -p "$TARGET_PROJECT/.sd/ai-coordination/workflow/spec"
mkdir -p "$TARGET_PROJECT/.sd/ai-coordination/workflow/review"
mkdir -p "$TARGET_PROJECT/.sd/ai-coordination/workflow/log"
mkdir -p "$TARGET_PROJECT/.sd/ai-coordination/handoff"
mkdir -p "$TARGET_PROJECT/.sd/ids"
mkdir -p "$TARGET_PROJECT/.sd/traceability"

# Docs
mkdir -p "$TARGET_PROJECT/docs/troubleshooting"
```

### Step 4: コンポーネントコピー

SD003フレームワークから以下をコピー:

#### 4-1. Claude Commands（セッション管理 - 必須）
```bash
SOURCE="path/to/sd003"

# ⚠️ セッション管理（省略禁止）
cp "$SOURCE/.claude/commands/sessionread.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE/.claude/commands/sessionwrite.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE/.claude/commands/sessionhistory.md" "$TARGET_PROJECT/.claude/commands/"

# ワークフロー
cp "$SOURCE/.claude/commands/workflow-init.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE/.claude/commands/workflow-order.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE/.claude/commands/workflow-request.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE/.claude/commands/workflow-status.md" "$TARGET_PROJECT/.claude/commands/"

# デバッグツール（3階層）
cp "$SOURCE/.claude/commands/bug-quick.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE/.claude/commands/bug-trace.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE/.claude/commands/dialogue-resolution.md" "$TARGET_PROJECT/.claude/commands/"
```

#### 4-1b. SDコマンド（仕様書駆動 - 必須）
```bash
# ⚠️ SDコマンド（省略禁止 - v2.7.0追加）
mkdir -p "$TARGET_PROJECT/.claude/commands/sd"
cp -r "$SOURCE/.claude/commands/sd/"* "$TARGET_PROJECT/.claude/commands/sd/"

# 個別コピーする場合:
# cp "$SOURCE/.claude/commands/sd/spec-init.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/spec-requirements.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/spec-design.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/spec-tasks.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/spec-impl.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/spec-status.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/steering.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/steering-custom.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/validate-design.md" "$TARGET_PROJECT/.claude/commands/sd/"
# cp "$SOURCE/.claude/commands/sd/validate-gap.md" "$TARGET_PROJECT/.claude/commands/sd/"
```

#### 4-2. Claude Skills
```bash
cp "$SOURCE/.claude/skills/dialogue-resolution/SKILL.md" "$TARGET_PROJECT/.claude/skills/dialogue-resolution/"
cp "$SOURCE/.claude/skills/dialogue-resolution/README.md" "$TARGET_PROJECT/.claude/skills/dialogue-resolution/"
```

#### 4-3. Claude Rules
```bash
cp -r "$SOURCE/.claude/rules/global/" "$TARGET_PROJECT/.claude/rules/"
cp -r "$SOURCE/.claude/rules/troubleshooting/" "$TARGET_PROJECT/.claude/rules/"
cp -r "$SOURCE/.claude/rules/session/" "$TARGET_PROJECT/.claude/rules/"
```

#### 4-3b. デバッグドキュメント
```bash
cp "$SOURCE/docs/troubleshooting/bug-quick-patterns.md" "$TARGET_PROJECT/docs/troubleshooting/"
```

#### 4-4. Gemini Commands
```bash
cp "$SOURCE/.gemini/commands/sd-spec-init.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-spec-requirements.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-spec-design.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-spec-tasks.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-spec-impl.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-spec-status.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-validate-design.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-validate-gap.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-validate-impl.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-steering.toml" "$TARGET_PROJECT/.gemini/commands/"
cp "$SOURCE/.gemini/commands/sd-steering-custom.toml" "$TARGET_PROJECT/.gemini/commands/"
```

#### 4-5. SD Settings & Templates
```bash
cp "$SOURCE/.sd/settings/quality-gates.yaml" "$TARGET_PROJECT/.sd/settings/"
cp -r "$SOURCE/.sd/settings/templates/" "$TARGET_PROJECT/.sd/settings/"
cp -r "$SOURCE/.sd/settings/rules/" "$TARGET_PROJECT/.sd/settings/"
cp "$SOURCE/.sd/sessions/session-template.md" "$TARGET_PROJECT/.sd/sessions/"

# ⚠️ セッション初期化（必須 - コピーではなく新規作成）
cat > "$TARGET_PROJECT/.sd/sessions/session-current.md" << EOF
# Session Record

## Session Info
- **Date**: $(date +%Y-%m-%d) (Initial Setup)
- **Project**: $(basename "$TARGET_PROJECT")
- **Branch**: (not yet checked)
- **Latest Commit**: (not yet checked)

## Progress Summary

### Completed
1. SD003 Framework installed

### In Progress
- None

### Next Session Tasks

#### P0 (Urgent)
- None

#### P1 (Important)
- Configure project-specific settings

### Notes
Initial session setup from SD003 framework.
EOF

cat > "$TARGET_PROJECT/.sd/sessions/TIMELINE.md" << EOF
# $(basename "$TARGET_PROJECT") Project Timeline

> Auto-generated - Updated on /sessionwrite execution

---

## $(date +%Y)

### $(date +%B)

| Date | Main Work | Commit | Details |
|------|-----------|--------|---------|
| $(date +%m-%d) | SD003 Framework Setup | - | [Details](session-current.md) |

---

## Statistics

- Total Sessions: 1
- First Session: $(date +%Y-%m-%d)
- Latest Session: $(date +%Y-%m-%d)
EOF
```

#### 4-6. AI Coordination Workflow
```bash
cp "$SOURCE/.sd/ai-coordination/workflow/README.md" "$TARGET_PROJECT/.sd/ai-coordination/workflow/"
cp "$SOURCE/.sd/ai-coordination/workflow/CODEX_GUIDE.md" "$TARGET_PROJECT/.sd/ai-coordination/workflow/"
cp -r "$SOURCE/.sd/ai-coordination/workflow/templates/" "$TARGET_PROJECT/.sd/ai-coordination/workflow/"
```

#### 4-7. Docs
```bash
cp "$SOURCE/docs/troubleshooting/RESOLUTION_LOG.md" "$TARGET_PROJECT/docs/troubleshooting/"
cp "$SOURCE/docs/quality-gates.md" "$TARGET_PROJECT/docs/" 2>/dev/null || true
```

### Step 5: AGENTS.md生成

Codex CLI用の設定ファイルを生成:

```bash
# AGENTS.md.templateからAGENTS.mdを生成
sed "s/{{PROJECT_NAME}}/$(basename "$TARGET_PROJECT")/g; s/{{DATE}}/$(date +%Y-%m-%d)/g" \
    "$SOURCE/.claude/skills/sd-deploy/templates/AGENTS.md.template" \
    > "$TARGET_PROJECT/AGENTS.md"
```

### Step 6: CLAUDE.md生成

3フェーズ開発戦略を反映したCLAUDE.mdを生成:

```markdown
# {PROJECT_NAME} - SD003フレームワーク

## 開発フェーズ戦略

### 序盤: 計画フェーズ
**仕様書ファースト** + **フロントエンド駆動**

- 要件定義 → 設計 → タスク分解 の順序厳守
- UIモック/ワイヤーフレームを先に固める
- ユーザー体験を起点にバックエンドを設計

**コマンド:**
- `/sd:spec-init {feature}` - 仕様書初期化
- `/sd:spec-requirements {feature}` - 要件定義
- `/sd:spec-design {feature}` - 技術設計

### 中盤: 実装フェーズ
**AI協調ワークフロー** + **高速イテレーション**

- Claude Code: 計画・工程管理
- Codex: レビュー・品質チェック
- Gemini CLI: 高速実装
- 90%速度優先、細かい修正は後で

**コマンド:**
- `/workflow:init {slug}` - 案件初期化
- `/workflow:order {案件ID}` - 発注書作成
- `/workflow:request {案件ID} {番号}` - 実装指示

### 終盤: 完成フェーズ
**対話型解決法** + **本番モード**

- エラー収束しない → `/dialogue-resolution`
- 「本番」キーワードで品質ゲート全通過必須
- 唯一の成功基準:「必ず動く」

**コマンド:**
- `/dialogue-resolution {エラー内容}` - 対話型問題解決
- `/sd:validate-impl {feature}` - 実装検証

## セッション管理
- `/sessionread` - 前回セッション読込
- `/sessionwrite` - セッション保存

## 詳細ドキュメント
必要時のみ参照: `docs/` 配下

---
SD003 v2.3.0 | 導入日: {DATE}
```

### Step 7: gemini.md生成

```markdown
# {PROJECT_NAME} - Gemini CLI設定

## 利用可能コマンド

### 仕様書駆動開発
- `/sd:spec-init` - 仕様書初期化
- `/sd:spec-requirements` - 要件定義
- `/sd:spec-design` - 技術設計
- `/sd:spec-tasks` - タスク分解
- `/sd:spec-impl` - TDD実装
- `/sd:spec-status` - 進捗確認

### 検証
- `/sd:validate-design` - 設計検証
- `/sd:validate-gap` - ギャップ分析
- `/sd:validate-impl` - 実装検証

### ステアリング
- `/sd:steering` - ステアリング文書作成
- `/sd:steering-custom` - カスタムステアリング

---
SD003 v2.3.0
```

### Step 8: データストア初期化

```bash
# ID Registry
cat > "$TARGET_PROJECT/.sd/ids/registry.json" << EOF
{
  "version": "1.0.0",
  "created": "$(date -Iseconds)",
  "project": "$(basename "$TARGET_PROJECT")",
  "requirements": {},
  "specifications": {},
  "last_updated": "$(date -Iseconds)"
}
EOF

# Handoff Log
cat > "$TARGET_PROJECT/.sd/ai-coordination/handoff/handoff-log.json" << EOF
{
  "version": "2.0.0",
  "entries": []
}
EOF
```

### Step 9: 検証

```bash
# 必須ディレクトリ確認
REQUIRED_DIRS=(
    ".claude/commands"
    ".claude/skills/dialogue-resolution"
    ".claude/rules"
    ".gemini/commands"
    ".sd/specs"
    ".sd/steering"
    ".sd/sessions"
    ".sd/settings"
    ".sd/ai-coordination/workflow"
    "docs/troubleshooting"
)

# 必須ファイル確認
REQUIRED_FILES=(
    # 基本設定
    "CLAUDE.md"
    "AGENTS.md"
    "gemini.md"

    # ⚠️ セッション管理（省略禁止）
    ".claude/commands/sessionread.md"
    ".claude/commands/sessionwrite.md"
    ".claude/commands/sessionhistory.md"
    ".sd/sessions/session-current.md"
    ".sd/sessions/session-template.md"
    ".sd/sessions/TIMELINE.md"
    ".claude/rules/session/session-management.md"

    # ⚠️ SDコマンド（省略禁止 - v2.7.0追加）
    ".claude/commands/sd/spec-init.md"
    ".claude/commands/sd/spec-requirements.md"
    ".claude/commands/sd/spec-design.md"
    ".claude/commands/sd/spec-tasks.md"
    ".claude/commands/sd/spec-impl.md"
    ".claude/commands/sd/spec-status.md"
    ".claude/commands/sd/spec-quick.md"
    ".claude/commands/sd/steering.md"
    ".claude/commands/sd/steering-custom.md"
    ".claude/commands/sd/validate-design.md"
    ".claude/commands/sd/validate-gap.md"
    ".claude/commands/sd/validate-impl.md"
    ".claude/commands/sd/ai-report.md"
    ".claude/commands/sd/ai-request.md"
    ".claude/commands/sd/deploy.md"

    # デバッグツール（3階層）
    ".claude/commands/bug-quick.md"
    ".claude/commands/bug-trace.md"
    ".claude/commands/dialogue-resolution.md"
    ".claude/rules/troubleshooting/bug-quick.md"
    "docs/troubleshooting/bug-quick-patterns.md"

    # スキル・その他
    ".claude/skills/dialogue-resolution/SKILL.md"
    ".sd/settings/quality-gates.yaml"
    "docs/troubleshooting/RESOLUTION_LOG.md"
)
```

## 展開レポート

```
=== SD003フレームワーク展開完了 (v2.13.0) ===

【展開されたコンポーネント】

■ Claude Commands: 10個 + SDコマンド17個
  ├─ セッション管理（必須）
  │   ├─ sessionread
  │   ├─ sessionwrite
  │   └─ sessionhistory
  ├─ ワークフロー
  │   ├─ workflow-init
  │   ├─ workflow-order
  │   ├─ workflow-request
  │   └─ workflow-status
  ├─ デバッグツール（3階層）
  │   ├─ bug-quick       (5-15分)
  │   ├─ bug-trace       (30-60分)
  │   └─ dialogue-resolution
  └─ SDコマンド（v2.7.0追加 - 必須）
      ├─ spec-init, spec-requirements, spec-design
      ├─ spec-tasks, spec-impl, spec-status, spec-quick
      ├─ steering, steering-custom
      ├─ validate-design, validate-gap, validate-impl
      └─ ai-report, ai-request, deploy

■ Claude Rules: 3カテゴリ
  ├─ global/
  ├─ troubleshooting/
  └─ session/  ← セッション管理ルール

■ Claude Skills: 1個
  └─ dialogue-resolution

■ セッションファイル（必須・初期化済み）
  ├─ .sd/sessions/session-current.md  ← 新規作成
  ├─ .sd/sessions/TIMELINE.md         ← 新規作成
  └─ .sd/sessions/session-template.md

■ Gemini Commands: 11個
  └─ sd-spec-*, sd-validate-*, sd-steering*

■ SD Settings:
  ├─ quality-gates.yaml
  ├─ templates/, rules/
  └─ sessions/

■ AI Coordination:
  └─ workflow/, handoff/

■ Docs:
  ├─ troubleshooting/RESOLUTION_LOG.md
  └─ troubleshooting/bug-quick-patterns.md

【3フェーズ開発戦略】
序盤: 仕様書ファースト + フロントエンド駆動
中盤: AI協調ワークフロー + 高速イテレーション
終盤: 対話型解決法 + 本番モード
```

## トラブルシューティング

### コマンドが認識されない
1. Claude Codeを再起動
2. `.claude/commands/` 配下にファイルが存在するか確認

### スキルが認識されない
1. `.claude/skills/` 配下に `SKILL.md` が存在するか確認
2. YAML frontmatterの形式を確認

### Geminiコマンドが動作しない
1. `.gemini/commands/` 配下に `.toml` ファイルが存在するか確認
2. Gemini CLIを再起動
