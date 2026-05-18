---
name: workflow-init
description: Codex equivalent of the SD003 custom command `/workflow:init`. Use when the user invokes `/workflow:init`, `workflow-init`.
---

# ワークフロー初期化: /workflow:init

この skill は Claude Code の `/workflow:init` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Codex Runtime Rules
- `.claude/commands/**/*.md` はClaude Code側のauthoring sourceです。直接変更せず、CodexではこのSkillを実行仕様として扱います。
- Claude Codeのスラッシュコマンド、`Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Codexの通常手順に翻訳します。
- Codex内で `/codex:review`、`/codex:rescue` などのCodexプラグインコマンドを再帰的に呼ばないでください。必要な読取・差分確認・編集・検証・報告をCodex自身で実施します。
- 人間向け出力、レビュー報告、質問、完了報告は日本語で書きます。
- `.sd/ai-coordination/` に依頼書・報告書を書く場合は、既存の案件ID配下に限定し、プロジェクトルートへ散らさないでください。
- Windows環境ではPowerShellで実行できるコマンドを優先し、bash専用の例はWSLやGit Bashが使える場合だけ採用します。

## Original Command Body
# ワークフロー初期化: /workflow:init

## 概要
新規案件のワークフロー環境を初期化します。

## 使用方法
```
/workflow:init {案件略称}
```

## 引数
- `案件略称`: 案件を識別する短い名前（英数字、ハイフン可）

## 実行手順

### 1. 案件ID生成
現在日時と連番から案件IDを生成:
- 形式: `{YYYYMMDD}-{連番3桁}-{案件略称}`
- 例: `20251230-001-auth-feature`

連番の決定:
1. `.sd/ai-coordination/workflow/spec/` 配下の既存案件IDを確認
2. 同日の最大連番 + 1 を使用
3. 同日の案件がなければ 001 から開始

### 2. ディレクトリ作成
```bash
mkdir -p .sd/ai-coordination/workflow/spec/{案件ID}
mkdir -p .sd/ai-coordination/workflow/review/{案件ID}
mkdir -p .sd/ai-coordination/workflow/log/{案件ID}
```

### 3. PROJECT_STATUS.md 初期化
`.sd/ai-coordination/workflow/log/{案件ID}/PROJECT_STATUS.md` を作成:
- テンプレート: `.sd/ai-coordination/workflow/templates/PROJECT_STATUS.md`
- メタデータを現在日時で初期化
- フェーズ1（発注書作成）を設定

### 4. handoff-log.json 更新
`.sd/ai-coordination/handoff/handoff-log.json` に新規案件を登録:
```json
{
  "active_projects": [
    {
      "project_id": "{案件ID}",
      "title": "{案件略称}",
      "current_phase": 1,
      "current_owner": "Claude Code",
      "status": "initialized",
      "created_at": "{現在日時ISO形式}",
      "updated_at": "{現在日時ISO形式}"
    }
  ]
}
```

### 5. 完了報告
```
## 案件初期化完了

- **案件ID**: {案件ID}
- **作成ディレクトリ**:
  - spec/{案件ID}/
  - review/{案件ID}/
  - log/{案件ID}/
- **初期化ファイル**:
  - log/{案件ID}/PROJECT_STATUS.md

## 次のステップ
```
/workflow:order {案件ID}
```
で発注書を作成してください。
```

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従って案件を初期化してください。
