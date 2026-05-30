# .sd/ Safe Commit Rule

## 絶対ルール（2026-05-27 Layer 1+2+3 後の現行運用）

> `.sd/` への書き込みは **Bash tool のみ**。Write/Edit/MultiEdit は物理ブロックされる。
> `.sd/` は通常 tracked（`.gitignore` 対象外）。**commit は別bashに分けてよい。**

旧ルール「`.sd/` 変更は同一bash内で `git add` + `git commit` を完了」は **撤廃**された。
根本原因が L1+L2+L3 で構造的に解消されたため、同一bash強制という儀式（症状抑制）は不要。
歴史的経緯は末尾「旧ルール（撤廃）」を参照。

## 根本対策（2026-05-27 確定・3層構造）

`.sd/` 消失の真因は2つあった。Layer 1+2+3 で構造的に解消した。

| Layer | 真因 | 対策 | コミット |
|-------|------|------|----------|
| L1 | `.sd/` が gitignored だが tracked の矛盾 → runtime の working tree refresh が「捨てて良いファイル」と誤判定 | `.gitignore` から `.sd/` 削除、通常 tracked 化 | `7106525` |
| L2 | `.claude/settings.local.json` 慢性 modified が wipe 発火確率を上げる | `.gitignore` 追加 + `git rm --cached` で untrack | `7106525` |
| L3 | Edit/Write tool on `.sd/` + 次の Bash が wipe trigger | PreToolUse hook `block-edit-write-on-sd.sh` で物理ブロック | `dcf0498` |

検証（コミット `6b3884f`）: Bash-only edit + **別bash** commit で wipe なしを実証。
5回連続 `find .sd -type f` で 41 ファイル安定確認。Edit tool での `.sd/` 編集試行はガードレール発火でブロック確認。

Refs: anthropics/claude-code#34330, #10011

## 現行運用ルール

| 操作 | 方法 |
|------|------|
| `.sd/` ファイル作成 | Bash heredoc/redirect（`cat > file << 'EOF'`） |
| `.sd/` ファイル編集 | Bash（`sed -i`, `echo >>`） |
| `.sd/` ファイル読み | Read tool ✅ |
| `.sd/` への Write/Edit/MultiEdit | 物理ブロック ⛔（`block-edit-write-on-sd.sh`） |
| `.sd/` 削除 | `block-sd-destructive.sh` で既ブロック |
| `.sd/` の commit | **別bashに分けてよい**（同一bash強制は撤廃） |

### .sd/ファイル作成・編集の例（Bash tool）
```bash
# 作成
cat > .sessions/file.txt << 'EOF'
content
EOF

# 編集
echo "追記行" >> .sessions/file.txt
sed -i 's/old/new/' .sessions/file.txt
```

commit は別の Bash 呼び出しでよい:
```bash
git add .sessions/file.txt && git commit -m "message"
```

## settings.json / settings.local.json

- `.claude/settings.local.json` は `.gitignore` に追加し、`git rm --cached` で untrack 済み（L2）。
  settings.local.json の慢性 modified は wipe 発火確率を上げるため git 管理外にする。
- `.claude/settings.json` は tracked（FW所有物）。

## 消失時の復元手順（最終防衛線）

L3 ガードレールが何らかの理由で破られた場合の最終手段。
```bash
# 過去のcommitから復元（1コマンドで全て実行）
git ls-tree -r <commit-hash> --name-only | grep "^\.sd/" | while read f; do
  mkdir -p "$(dirname "$f")"
  git show "<commit-hash>:$f" > "$f"
done && git add .sd/ && git commit -m "fix: restore .sd from <commit-hash>"
```

HEADに.sd/がない場合は `git log --all -- .sessions/TIMELINE.md` で最後に存在したcommitを特定。

## 旧ルール（撤廃・歴史的経緯）

2026-03-28〜05-26 は「`.sd/` 変更は必ず同一bash内で `git add` + `git commit` まで完了する」を
絶対ルールとしていた。これは L1+L2+L3 以前の応急策（症状抑制）であり、根本原因
（gitignored-but-tracked の矛盾 + Edit/Write trigger）が解消された現在は不要。
別bash commit が wipe を起こさないことは `6b3884f` で実証済み。

at002 の実機証拠: Layer 1+2 だけでも実用上は十分（`.sd/` 123ファイル安定運用）。L3 は予防的物理強制。

## 全AIモデル共通

このルールはClaude Code、Codex、Gemini CLI、Antigravity全てに適用される。
