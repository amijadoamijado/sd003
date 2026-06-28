---
name: skills-list
description: "スキル一覧: /skills:list (Use when the user runs /skills-list.)"
---

# スキル一覧: /skills:list

SD003 custom command `/skills:list` を Grok skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Grok Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、Grok の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*`、`/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はGrok自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

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
