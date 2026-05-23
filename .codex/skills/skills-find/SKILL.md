---
name: skills-find
description: Codex equivalent of the SD003 custom command `/skills:find`. Use when the user invokes `/skills:find`, `skills-find`.
---

# スキル検索: /skills:find

この skill は Claude Code の `/skills:find` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

## Codex Runtime Rules
- `.claude/commands/**/*.md` はClaude Code側のauthoring sourceです。直接変更せず、CodexではこのSkillを実行仕様として扱います。
- Claude Codeのスラッシュコマンド、`Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Codexの通常手順に翻訳します。
- Codex内で `/codex:review`、`/codex:rescue` などのCodexプラグインコマンドを再帰的に呼ばないでください。必要な読取・差分確認・編集・検証・報告をCodex自身で実施します。
- 人間向け出力、レビュー報告、質問、完了報告は日本語で書きます。
- `.sd/ai-coordination/` に依頼書・報告書を書く場合は、既存の案件ID配下に限定し、プロジェクトルートへ散らさないでください。
- Windows環境ではPowerShellで実行できるコマンドを優先し、bash専用の例はWSLやGit Bashが使える場合だけ採用します。

## Codex Native Execution Contract
このセクションはCodex実行時に `Original Command Body` より優先します。

- Claude Codeのスラッシュコマンド、`/workflow:*`、`/codex:*`、`Agent(...)`、`AskUserQuestion` は文字通り実行しない。
- Codex自身がファイル読取、差分確認、編集、検証、報告を直接行う。
- `.claude/commands/**/*.md` はauthoring sourceとして読むだけにし、Codex改善のために直接編集しない。
- 案件IDがない相談・レビューでは `.sd/ai-coordination/` に報告書を作らず、会話内で完結する。
- `.sd/ai-coordination/` に書くのは、案件IDが明示された正式Workflowの場合だけにする。
- WindowsではPowerShellで実行できるコマンドを優先し、bash例はWSL/Git Bashが使える場合だけ採用する。
- `.sd/` が存在しない場合は、その事実を報告し、可能なら軽量レビューまたは直接実装へ縮退する。

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
