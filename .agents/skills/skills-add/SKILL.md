---
name: skills-add
description: "スキルインストール: /skills:add"
disable-model-invocation: true
---

# スキルインストール: /skills:add

SD003 custom command `/skills:add` を Antigravity (agy) skill として再現します。

User-provided arguments (if any): $ARGUMENTS

## Antigravity Runtime Rules
- `.claude/commands/**/*.md` はauthoring source。直接編集せず、本Skillを実行仕様として扱う。
- Claude Code固有の `Agent(...)`、`AskUserQuestion`、hook前提の記述は文字通り実行せず、agy の通常手順（ファイル読取・編集・コマンド実行・必要時のユーザー確認）に翻訳する。
- `/workflow:*` や `/codex:*` など他CLIのスラッシュコマンドは呼ばない。必要な作業はagy自身が直接行う。
- 人間向け出力・報告・質問は日本語で書く。
- `.sd/ai-coordination/` に書くのは案件IDが明示された正式Workflowの場合のみ。
- WindowsではPowerShellで実行できるコマンドを優先する。

## Original Command Body
# スキルインストール: /skills:add

## 概要
skills.shエコシステムからスキルをインストールします。

## 使用方法
```
/skills:add {owner/repo} [--skill name]
```

## 引数
- `owner/repo`: GitHubリポジトリ（例: `vercel-labs/agent-skills`）
- `--skill name`: 特定スキル名（省略時は対話的選択）

## 実行手順

### 1. 信頼レベル確認
インストール前に信頼レベルを確認:

| 信頼レベル | ソース |
|-----------|--------|
| **Trusted** | `anthropics/skills`, `vercel-labs/skills`, `vercel-labs/agent-skills` |
| **Caution** | その他のリポジトリ |

**Cautionレベル**の場合:
- ユーザーにリポジトリURLを提示
- 「SKILL.mdの内容を確認してからインストールしますか？」と確認

### 2. インストール実行
```bash
npx skills add $ARGUMENTS -y
```

### 3. 結果確認
```bash
npx skills list
```

### 4. 完了報告
```
## スキルインストール完了

- **スキル名**: {name}
- **ソース**: {owner/repo}
- **信頼レベル**: Trusted / Caution
- **インストール先**: .claude/skills/{name}/SKILL.md
```

## ユーザー入力
$ARGUMENTS

---

**実行開始**: 上記手順に従ってスキルをインストールしてください。
