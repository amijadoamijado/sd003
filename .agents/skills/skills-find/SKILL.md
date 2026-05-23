---
name: skills-find
description: "スキル検索: /skills:find"
disable-model-invocation: true
---

# スキル検索: /skills:find

SD003 custom command `/skills:find` を Antigravity (agy) skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Antigravity Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、agy(Gemini)の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はagy自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

## Original Command Body
# スキル検索: /skills:find

## 概要
skills.shエコシステムからスキルを検索します。

## 使用方法
```
/skills:find {検索クエリ}
```

## 引数
- `検索クエリ`: 検索キーワード（英語推奨）

## 実行手順

### 1. 検索実行
```bash
npx skills find $ARGUMENTS
```

### 2. 結果表示
検索結果をユーザーに提示する:
- スキル名と説明
- インストールコマンド (`npx skills add <owner/repo@skill> -y`)
- skills.sh のリンク

### 3. 信頼レベル確認
検索結果のスキルについて信頼レベルを表示:

| 信頼レベル | ソース | 扱い |
|-----------|--------|------|
| **Trusted** | `anthropics/skills`, `vercel-labs/skills`, `vercel-labs/agent-skills` | 自由にインストール可 |
| **Caution** | その他のリポジトリ | SKILL.md確認後にインストール |

### 4. インストール提案
ユーザーが興味を示したスキルについて:
```
インストールしますか？
npx skills add <owner/repo@skill> -y
```

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従ってスキルを検索してください。
