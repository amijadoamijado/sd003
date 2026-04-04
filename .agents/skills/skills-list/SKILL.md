---
name: skills-list
description: Codex equivalent of the SD003 custom command `/skills:list`. Use when the user invokes `/skills:list`, `skills-list`.
---

# スキル一覧: /skills:list

この skill は Claude Code の `/skills:list` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

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
