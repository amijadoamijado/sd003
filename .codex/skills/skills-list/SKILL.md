---
name: skills-list
description: Codex equivalent of the SD003 custom command `/skills:list`. Use when the user invokes `/skills:list`, `skills-list`.
---

# スキル一覧: /skills:list

この skill は Claude Code の `/skills:list` を Codex で再現するためのものです。
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
# スキル一覧: /skills:list

## 概要
インストール済みスキルの一覧を表示します。

## 使用方法
```
/skills:list
```

## 実行手順

### 1. 一覧取得
```bash
npx skills list
```

### 2. 整形表示
結果を以下の形式で表示:

| スキル名 | ソース | 信頼レベル | 説明 |
|---------|--------|-----------|------|
| {name} | {source} | Trusted/Caution/Local | {description} |

信頼レベルの判定:
- `anthropics/skills` → **Trusted**
- `vercel-labs/skills`, `vercel-labs/agent-skills` → **Trusted**
- `.claude/skills/` 直下（SD003独自） → **Local**
- その他 → **Caution**

### 3. サマリー
```
合計: {N}個のスキル
- Trusted: {n}個
- Local: {n}個
- Caution: {n}個
```

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従ってスキル一覧を表示してください。
