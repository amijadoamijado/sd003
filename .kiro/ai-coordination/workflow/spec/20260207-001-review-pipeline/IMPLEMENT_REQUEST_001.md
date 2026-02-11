# 実装指示: auto-review pipeline Codex指摘修正

## メタデータ
| 項目 | 値 |
|------|-----|
| 案件ID | 20260207-001-review-pipeline |
| タスク番号 | 001 |
| 発行日時 | 2026-02-07 16:15 |
| 発行者 | Claude Code |
| 宛先 | Gemini CLI |
| ステータス | Pending |

## 1. 対象ブランチ

| 項目 | 値 |
|------|-----|
| 作業ブランチ | `master` |
| ベースブランチ | `master` |

## 2. 実装タスク概要

**タスク名**: Codexレビュー指摘（W-1, W-2, W-3, I-1, I-2, I-3）の修正

### 2.1 目的
Codexによるコードレビューで指摘されたWarning 3件、Info 3件を修正する。

## 3. 実装範囲

### 3.1 変更可能ファイル
| ファイルパス | アクション | 説明 |
|------------|----------|------|
| `.claude/hooks/agent-review.sh` | Modify | W-1, I-1 修正 |
| `scripts/agent-review.sh` | Modify | W-2, I-2 修正 |

### 3.2 禁止領域（変更不可）
| ファイル/ディレクトリ | 理由 |
|---------------------|------|
| `CLAUDE.md` | フレームワーク設定 |
| `.claude/settings.json` | W-3は修正不要（運用で対応） |
| `scripts/agent-pipeline.sh` | 今回のスコープ外 |

## 4. 修正仕様（6件）

### W-1: grep/sedによるJSON解析の脆弱性修正
**ファイル**: `.claude/hooks/agent-review.sh` L26
**問題**: エスケープされたクォートやバックスラッシュで `command` フィールドの抽出が壊れる
**修正方針**: Pythonのjson.loadsを使ったフォールバックを追加。Python不在時はgrep/sedを維持。

```bash
# 修正後のL26付近:
# Try python first (safe JSON parsing), fallback to grep/sed
if command -v python3 &>/dev/null; then
  TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")
else
  TOOL_INPUT=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "")
fi
```

### W-2: Windowsパスセパレータ対応
**ファイル**: `scripts/agent-review.sh` L84付近
**問題**: `grep -oE 'workflow/spec/([^/]+)/'` が `\` パスで失敗
**修正方針**: パスを正規化してから抽出

```bash
# 修正後:
NORMALIZED_PATH=$(echo "$REQUEST_FILE" | sed 's|\\|/|g')
if echo "$NORMALIZED_PATH" | grep -qE 'workflow/spec/([^/]+)/'; then
    PROJECT_ID=$(echo "$NORMALIZED_PATH" | grep -oE 'workflow/spec/([^/]+)/' | sed 's|workflow/spec/||;s|/$||')
fi
```

### W-3: settings.json timeout
**対応不要** — 運用で対応。修正スコープ外。

### I-1: echo → printf '%s' に変更
**ファイル**: `.claude/hooks/agent-review.sh` L95
**問題**: `echo` はバックスラッシュを解釈する可能性がある
**修正方針**: `printf '%s' "$REVIEW_PROMPT"` に変更

```bash
# Before:
REVIEW_RESULT=$(echo "$REVIEW_PROMPT" | codex exec --full-auto 2>/dev/null) || REVIEW_EXIT=$?

# After:
REVIEW_RESULT=$(printf '%s' "$REVIEW_PROMPT" | codex exec --full-auto 2>/dev/null) || REVIEW_EXIT=$?
```

### I-2: 未使用変数 RELATIVE_OUTPUT の削除
**ファイル**: `scripts/agent-review.sh` L186付近
**問題**: `RELATIVE_OUTPUT` を計算しているが使っていない
**修正方針**: 該当ブロックを削除

```bash
# 削除対象（L183-188付近）:
HANDOFF_LOG="${PROJECT_ROOT}/.kiro/ai-coordination/handoff/handoff-log.json"
if [ -n "$PROJECT_ID" ] && [ -f "$HANDOFF_LOG" ]; then
    RELATIVE_OUTPUT=$(echo "$REVIEW_OUTPUT" | sed "s|${PROJECT_ROOT}/||")
    echo -e "${BLUE}handoff-log.json に記録中...${NC}"
    echo -e "${YELLOW}[INFO] handoff-log.json への記録はClaude Codeが実行してください${NC}"
fi
```

を以下に簡略化:

```bash
# 簡略化後:
if [ -n "$PROJECT_ID" ]; then
    echo -e "${YELLOW}[INFO] handoff-log.json への記録はClaude Codeが実行してください${NC}"
fi
```

### I-3: ファイルパーミッション修正
**対応**: スクリプト外でgitコマンドで対応（Geminiスコープ外）

## 5. 受け入れテスト

### 5.1 構文チェック
```bash
bash -n .claude/hooks/agent-review.sh
bash -n scripts/agent-review.sh
```

### 5.2 手動確認項目
| 確認ID | 確認内容 | 期待結果 |
|--------|---------|---------|
| MC-001 | agent-review.sh のJSON解析がpython3で動作 | python3利用時にcommandフィールドを正しく抽出 |
| MC-002 | Windowsパス `workflow\spec\xxx\` でPROJECT_ID抽出 | 正しくxxx部分を抽出 |
| MC-003 | printf版でCodexにプロンプトが渡る | 結果がstdoutに出力される |

## 6. 注意事項

### 6.1 技術的制約
- [ ] bashスクリプトのみ（TypeScriptではない）
- [ ] python3はオプション依存（不在時はgrep/sedフォールバック）
- [ ] Windows Git Bash環境で動作すること

---
**発行日時**: 2026-02-07 16:15
**発行者**: Claude Code
