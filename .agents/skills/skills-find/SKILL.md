---
name: skills-find
description: Codex equivalent of the SD003 custom command `/skills:find`. Use when the user invokes `/skills:find`, `skills-find`.
---

# スキル検索: /skills:find

この skill は Claude Code の `/skills:find` を Codex で再現するためのものです。
本文に Claude 固有の記法やツール名が含まれる場合も、Codex では同等の手順に置き換えて実行してください。

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
