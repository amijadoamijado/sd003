# .sd/ Safe Commit Rule

## 絶対ルール

> .sd/ ファイルの変更は、必ず同じbashコマンド内で `git add` + `git commit` まで完了すること。
> 別のbashコマンドに分けると .sd/ ディレクトリ全体が消失する。

## 背景（2026-03-28 Bug Trace確定）

Claude Codeランタイムが Bash ツール実行後に git status をチェックし、
`.sd/` に modified（未commit）ファイルがあるとワーキングツリーをリフレッシュして消す。

| 条件 | 結果 |
|------|------|
| .sd/ modified=0 + どんなcommit | 安全 |
| .sd/ modified>=1 + 同じbash内でadd+commit | 安全 |
| .sd/ modified>=1 + 別のbashでadd+commit | **消失** |

Refs: anthropics/claude-code#34330, #10011

## 安全パターン（必ずこの形で実行）

### .sd/ファイル作成+commit
```bash
# 1コマンドで全て完了
echo "content" > .sd/sessions/file.txt && git add .sd/sessions/file.txt && git commit -m "message"
```

### 復元+commit
```bash
# 復元→add→commitを1コマンドで
git ls-tree -r HEAD --name-only | grep "^.sd/" | while read f; do
  mkdir -p "$(dirname "$f")"
  git show "HEAD:$f" > "$f"
done && git add .sd/ && git commit -m "fix: restore .sd"
```

### sessionwrite
```bash
# セッションファイル作成→TIMELINE更新→add→commitを1コマンドで
cat > .sd/sessions/session-YYYYMMDD.md << 'EOF'
...
EOF
cp .sd/sessions/session-YYYYMMDD.md .sd/sessions/session-current.md
sed -i '...' .sd/sessions/TIMELINE.md
git add .sd/sessions/ .handoff/DONE.md && git commit -m "session: ..."
```

## 禁止パターン

```bash
# NG: bash呼び出し1でファイル作成
echo "content" > .sd/sessions/file.txt

# NG: bash呼び出し2でcommit（この間に.sd/が消える）
git add .sd/sessions/file.txt && git commit -m "message"
```

## settings.json

`.claude/settings.json` は `.gitignore` に追加してgit管理外にすること。
settings.jsonのcommitはランタイムのリフレッシュを誘発し、.sd/消失の確率を上げる。

## 消失時の復元手順

```bash
# 過去のcommitから復元（1コマンドで全て実行）
git ls-tree -r <commit-hash> --name-only | grep "^.sd/" | while read f; do
  mkdir -p "$(dirname "$f")"
  git show "<commit-hash>:$f" > "$f"
done && git add .sd/ && git commit -m "fix: restore .sd from <commit-hash>"
```

HEADに.sd/がない場合は `git log --all -- .sd/sessions/TIMELINE.md` で最後に存在したcommitを特定。

## 全AIモデル共通

このルールはClaude Code、Codex、Gemini CLI、Antigravity全てに適用される。
