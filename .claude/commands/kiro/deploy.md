---
description: "SD001フレームワークのプロジェクト展開"
---

# SD001フレームワーク展開システム

## 使用方法
`/kiro:deploy <target-project-path>`

## 1. 対象プロジェクト検証
{{#exec}}
TARGET_PROJECT="${1:-../rf002}"
echo "=== 対象プロジェクト: $TARGET_PROJECT ==="

if [ ! -d "$TARGET_PROJECT" ]; then
    echo "❌ エラー: 対象プロジェクト '$TARGET_PROJECT' が見つかりません"
    exit 1
fi

echo "✅ 対象プロジェクト確認: $TARGET_PROJECT"
{{/exec}}

## 2. 既存設定バックアップ
{{#exec}}
TARGET_PROJECT="${1:-../rf002}"
BACKUP_DIR="$TARGET_PROJECT/.sd001-backup-$(date +%Y%m%d_%H%M%S)"

echo "=== バックアップ作成: $BACKUP_DIR ==="
mkdir -p "$BACKUP_DIR"

# 既存設定ファイルのバックアップ
[ -f "$TARGET_PROJECT/agents.md" ] && cp "$TARGET_PROJECT/agents.md" "$BACKUP_DIR/"
[ -f "$TARGET_PROJECT/gemini.md" ] && cp "$TARGET_PROJECT/gemini.md" "$BACKUP_DIR/"
[ -f "$TARGET_PROJECT/CLAUDE.md" ] && cp "$TARGET_PROJECT/CLAUDE.md" "$BACKUP_DIR/"
[ -d "$TARGET_PROJECT/.agents" ] && cp -r "$TARGET_PROJECT/.agents" "$BACKUP_DIR/"
[ -d "$TARGET_PROJECT/.claude" ] && cp -r "$TARGET_PROJECT/.claude" "$BACKUP_DIR/"
[ -d "$TARGET_PROJECT/.gemini" ] && cp -r "$TARGET_PROJECT/.gemini" "$BACKUP_DIR/"
[ -d "$TARGET_PROJECT/.kiro" ] && cp -r "$TARGET_PROJECT/.kiro" "$BACKUP_DIR/"

echo "✅ バックアップ完了: $BACKUP_DIR"
{{/exec}}

## 3. フォルダ構造作成
{{#exec}}
TARGET_PROJECT="${1:-../rf002}"

echo "=== フォルダ構造作成 ==="
mkdir -p "$TARGET_PROJECT/.agents/reports"
mkdir -p "$TARGET_PROJECT/.claude/commands/kiro"
mkdir -p "$TARGET_PROJECT/.gemini/handoffs"
mkdir -p "$TARGET_PROJECT/.kiro/specs"
mkdir -p "$TARGET_PROJECT/.kiro/ids"
mkdir -p "$TARGET_PROJECT/.kiro/_frozen"
mkdir -p "$TARGET_PROJECT/.kiro/sync-reports"
mkdir -p "$TARGET_PROJECT/.kiro/traceability"

echo "✅ フォルダ構造作成完了"
{{/exec}}

## 4. 設定ファイルコピー
{{#exec}}
TARGET_PROJECT="${1:-../rf002}"
SOURCE_PROJECT="."

echo "=== 設定ファイルコピー ==="

# ルートレベル設定ファイル
cp "$SOURCE_PROJECT/agents.md" "$TARGET_PROJECT/"
cp "$SOURCE_PROJECT/gemini.md" "$TARGET_PROJECT/"

# Claudeコマンドファイル
cp "$SOURCE_PROJECT/.claude/commands/cc-vibe-detect.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE_PROJECT/.claude/commands/cc-vibe-sync.md" "$TARGET_PROJECT/.claude/commands/"
cp "$SOURCE_PROJECT/.claude/commands/cc-vibe-update.md" "$TARGET_PROJECT/.claude/commands/"
cp -r "$SOURCE_PROJECT/.claude/commands/kiro/" "$TARGET_PROJECT/.claude/commands/"

echo "✅ 設定ファイルコピー完了"
{{/exec}}

## 5. データストア初期化
{{#exec}}
TARGET_PROJECT="${1:-../rf002}"

echo "=== データストア初期化 ==="

# ID レジストリ初期化
cat > "$TARGET_PROJECT/.kiro/ids/registry.json" << EOF
{
  "version": "1.0.0",
  "created": "$(date -Iseconds)",
  "project": "$(basename "$TARGET_PROJECT")",
  "requirements": {},
  "specifications": {},
  "acceptance_criteria": {},
  "last_updated": "$(date -Iseconds)"
}
EOF

# Frozen要件初期テンプレート
cat > "$TARGET_PROJECT/.kiro/_frozen/requirements.lock.md" << EOF
# $(basename "$TARGET_PROJECT") 凍結要件定義書

**凍結日時**: $(date -Iseconds)
**プロジェクト**: $(basename "$TARGET_PROJECT")
**バージョン**: 1.0.0

## 凍結された要件

### 初期設定完了
- **優先度**: High
- **ステータス**: 初期化済み
- **承認者**: システム
- **承認日**: $(date +%Y-%m-%d)

**概要**: SD001フレームワークの初期導入が完了しました

## 変更承認プロセス
1. 凍結要件の変更は **プロダクトオーナー承認** が必要
2. 変更影響分析の実施が必要

## 監査ログ
- $(date +%Y-%m-%d): SD001フレームワーク初期導入
EOF

echo "✅ データストア初期化完了"
{{/exec}}

## 6. CLAUDE.md更新
{{#exec}}
TARGET_PROJECT="${1:-../rf002}"

echo "=== CLAUDE.md更新 ==="

if [ -f "$TARGET_PROJECT/CLAUDE.md" ]; then
    # 既存CLAUDE.mdに追記
    echo "" >> "$TARGET_PROJECT/CLAUDE.md"
    echo "## SD001フレームワーク統合" >> "$TARGET_PROJECT/CLAUDE.md"
    echo "- **導入日**: $(date +%Y-%m-%d)" >> "$TARGET_PROJECT/CLAUDE.md"
    echo "- **バージョン**: v2.0" >> "$TARGET_PROJECT/CLAUDE.md"
    echo "- **利用可能コマンド**: /cc-vibe-detect, /cc-vibe-sync, /cc-vibe-update" >> "$TARGET_PROJECT/CLAUDE.md"
    echo "" >> "$TARGET_PROJECT/CLAUDE.md"
else
    # 新規CLAUDE.md作成
    cat > "$TARGET_PROJECT/CLAUDE.md" << EOF
# $(basename "$TARGET_PROJECT") - SD001フレームワーク統合

## SD001フレームワーク統合
- **導入日**: $(date +%Y-%m-%d)
- **バージョン**: v2.0
- **利用可能コマンド**: /cc-vibe-detect, /cc-vibe-sync, /cc-vibe-update

## 使用開始手順
1. \`/cc-vibe-detect\` で変更検出テスト
2. \`/cc-vibe-sync\` で仕様書同期実行
3. \`.kiro/specs/\` に仕様書を追加
EOF
fi

echo "✅ CLAUDE.md更新完了"
{{/exec}}

## 7. セットアップ検証
{{#exec}}
TARGET_PROJECT="${1:-../rf002}"

echo "=== セットアップ検証 ==="

# 必須ディレクトリ確認
REQUIRED_DIRS=(
    "$TARGET_PROJECT/.agents/reports"
    "$TARGET_PROJECT/.claude/commands"
    "$TARGET_PROJECT/.gemini/handoffs"
    "$TARGET_PROJECT/.kiro/specs"
    "$TARGET_PROJECT/.kiro/ids"
    "$TARGET_PROJECT/.kiro/_frozen"
)

ERROR_COUNT=0
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ 欠落: $dir"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    else
        echo "✅ 確認: $dir"
    fi
done

# 必須ファイル確認
REQUIRED_FILES=(
    "$TARGET_PROJECT/agents.md"
    "$TARGET_PROJECT/gemini.md"
    "$TARGET_PROJECT/.claude/commands/cc-vibe-detect.md"
    "$TARGET_PROJECT/.kiro/ids/registry.json"
    "$TARGET_PROJECT/.kiro/_frozen/requirements.lock.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ 欠落: $file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    else
        echo "✅ 確認: $file"
    fi
done

if [ $ERROR_COUNT -eq 0 ]; then
    echo "✅ セットアップ検証成功"
else
    echo "❌ セットアップ検証失敗: $ERROR_COUNT 個のエラー"
fi
{{/exec}}

## 8. 展開レポート生成
{{#exec}}
TARGET_PROJECT="${1:-../rf002}"

echo "=== SD001フレームワーク展開完了レポート ==="
echo "展開先: $TARGET_PROJECT"
echo "実行時刻: $(date)"
echo ""
echo "【展開された機能】"
echo "- ✅ エージェント協調フレームワーク (agents.md)"
echo "- ✅ Gemini CLI統合 (gemini.md)"
echo "- ✅ Claude Codeスラッシュコマンド (/cc-vibe-*)"
echo "- ✅ Kiroスペック駆動開発システム"
echo "- ✅ 要件トレーサビリティシステム"
echo "- ✅ 凍結要件管理システム"
echo ""
echo "【次の手順】"
echo "1. cd $TARGET_PROJECT"
echo "2. /cc-vibe-detect でシステム動作確認"
echo "3. .kiro/specs/ に仕様書追加"
echo "4. /cc-vibe-sync で同期開始"
echo ""
echo "🎉 SD001フレームワーク展開完了！"
{{/exec}}