---
slug: skills-list
source: .claude/commands/sd/skills-list.md
description: スキル一覧: /skills:list
claude_command: /skills:list
codex_skill: skills-list
gemini_file: skills-list.toml
---

# スキル一覧: /skills:list

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Gemini CLI の TOML と Codex の skill はこのファイルから生成します。

## Original Body
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
