# .sd/ Safe Commit Rule

## 絶対ルール（2026-05-31 実測で更新）

> 1. `.sd/` への書き込みは **Bash tool のみ**。Write/Edit/MultiEdit は物理ブロックされる（L3）。
> 2. `.sd/` は通常 tracked（`.gitignore` 対象外、L1）。
> 3. **`.sd/` の変更は早めに commit する。** runtime は今も commit 時に `.sd/` を消すことがあり、
>    自動復元（L4）は **HEAD からの復元** なので、**未commitの `.sd/` 変更は wipe で失われる**。

旧ルール「`.sd/` 変更は同一bash内で `git add` + `git commit` を完了する」は **緩和**された。
別bash commit でも post-commit auto-restore（L4）が tracked ファイルを救うため、ディレクトリ全消失は
復旧する。ただし **同一bash儀式が守っていた「wipe前にcommitを終わらせる」効果は残す価値がある**
（未commitの `.sd/` 作業は L4 で戻らないため）。

## 重要な訂正（2026-05-31）

2026-05-27 セッションは「L1+L2+L3 で `.sd/` 消失は構造的に解消、別bash commitでwipeなし」と結論した。
**これは誤りであることが実測で判明した。**

- コミット `9ae3274`（`.sd/` を一切変更しない `.claude/rules/` のみの commit）で `.sd/` が **フル消失**。
- post-commit hook が検知し HEAD から **42ファイルを自動復元** → データ損失ゼロ。
- 結論: **L1+L2+L3 は wipe の発火要因を減らすが、wipe を根絶しない。** 実際の最終防衛線は L4（auto-restore）。

## 4層防御の実態

| Layer | 真因 / 役割 | 対策 | 効果 | コミット |
|-------|------------|------|------|----------|
| L1 | `.sd/` が gitignored だが tracked の矛盾 → working tree refresh が「捨てて良い」と誤判定 | `.gitignore` から `.sd/` 削除、通常 tracked 化 | 発火要因を減らす | `7106525` |
| L2 | `.claude/settings.local.json` 慢性 modified が wipe 確率を上げる | `.gitignore` + `git rm --cached` で untrack | 発火確率を下げる | `7106525` |
| L3 | Edit/Write tool on `.sd/` + 次の Bash が wipe trigger | PreToolUse hook `block-edit-write-on-sd.sh` で物理ブロック | trigger 1種を遮断 | `dcf0498` |
| **L4** | **L1-L3 を経ても commit 時に `.sd/` 全消失が発生する**（`9ae3274` で実証） | **post-commit hook がファイル単位で欠損を検知し `.git/sd-snapshot` から自動復元** | **最終防衛線（full/partial両対応）** | `.git/hooks/post-commit` |

> **L4 強化（2026-06-10）**: pre-commit が commit 時点の `.sd/` 全体を `.git/sd-snapshot/` へ複製
> （`.git/` 内はランタイムの working tree refresh の対象外）。post-commit はスナップショットを正として
> **ファイル単位**で欠損を検知・復元する。これにより旧L4の2つの限界を解消:
> ① partial wipe（一部ファイルのみ消失）も検知・復元する。
> ② commit 時点でディスクにあったファイルは HEAD 非依存で復元される（スナップショット不在時のみ HEAD フォールバック）。
> 残る限界: **commit と commit の間（mid-session）の wipe は L4 の射程外**（sd-watchdog が警告のみ）。
> 実機テスト 17 ケース全 PASS（full/partial 復元・残存ファイル不可侵・意図的削除の非復活・HEAD フォールバック・未commit分保護）。

Refs: anthropics/claude-code#34330, #10011

## 現行運用ルール

| 操作 | 方法 |
|------|------|
| `.sd/` ファイル作成 | Bash heredoc/redirect（`cat > file << 'EOF'`） |
| `.sd/` ファイル編集 | Bash（`sed -i`, `echo >>`） |
| `.sd/` ファイル読み | Read tool ✅ |
| `.sd/` への Write/Edit/MultiEdit | 物理ブロック ⛔（`block-edit-write-on-sd.sh`） |
| `.sd/` 削除・mv・git clean | 物理ブロック ⛔（`block-sd-destructive.sh`） |
| `.sd/` の commit | 別bash可。**ただし作成・編集したら早めに commit する**（未commitは wipe で消える） |

### 安全パターン（推奨）
```bash
# 作成 → すぐ commit（同一bashが最も安全。別bashでも L4 が tracked を救うが未commitは救えない）
cat > .sessions/file.txt << 'EOF'
content
EOF
git add .sessions/file.txt && git commit -m "message"
```

## settings.json / settings.local.json

- `.claude/settings.local.json` は `.gitignore` 追加 + `git rm --cached` で untrack 済み（L2）。
- `.claude/settings.json` は tracked（FW所有物）。

## 消失時の手動復元手順（L4 が機能しない場合）

```bash
git ls-tree -r <commit-hash> --name-only | grep "^\.sd/" | while read f; do
  mkdir -p "$(dirname "$f")"
  git show "<commit-hash>:$f" > "$f"
done && git add .sd/ && git commit -m "fix: restore .sd from <commit-hash>"
```
HEADに.sd/がない場合は `git log --all -- .sessions/TIMELINE.md` で最後に存在したcommitを特定。

## 改善候補

- ~~**L4 の partial wipe 検知**~~ → **実装済み（2026-06-10）**: post-commit がスナップショット基準の
  ファイル単位検知に改良され、partial wipe も検知・復元する。
- ~~**未commit `.sd/` の保護（commit時点）**~~ → **実装済み（2026-06-10）**: pre-commit の
  `.git/sd-snapshot/` 採取により、commit 時点でディスクにあったファイルは HEAD 非依存で復元される。
- **mid-session wipe の自動復元（未対応）**: commit を挟まないタイミングの wipe は sd-watchdog が
  警告のみ。watchdog をスナップショット復元型に拡張する案はあるが、「警告のみ」は意図的設計のため
  変更はユーザー判断待ち。現行の緩和策は「`.sd/` 変更後の早めの commit」。

## 旧ルール（緩和・歴史的経緯）

2026-03-28〜05-26 は「`.sd/` 変更は必ず同一bash内で add+commit」を絶対ルールとしていた。
これは L4（auto-restore）が安定動作する現在は「絶対」ではないが、**未commitの `.sd/` 作業を
wipe から守る効果は今も有効**。よって「同一bash必須」→「早めに commit（同一bashが最も安全）」へ緩和。

## 全AIモデル共通

このルールはClaude Code、Codex、Gemini CLI、Antigravity全てに適用される。
