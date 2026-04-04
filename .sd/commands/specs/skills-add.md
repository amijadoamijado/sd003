---
slug: skills-add
source: .claude/commands/sd/skills-add.md
description: スキルインストール: /skills:add
claude_command: /skills:add
codex_skill: skills-add
gemini_file: skills-add.toml
---

# スキルインストール: /skills:add

## Canonical Intent
Claude Code のカスタムコマンド仕様を CLI 非依存で保持する正本です。
Gemini CLI の TOML と Codex の skill はこのファイルから生成します。

## Original Body
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
