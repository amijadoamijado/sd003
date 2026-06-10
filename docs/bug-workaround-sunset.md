# バグ回避策サンセット表

作成: 2026-06-10

SD003にはClaude Code本体のバグ・環境制約への回避策が積層している。
バグが解消された後も回避策の摩擦だけが残ることを防ぐため、
**何を監視し、何が確認できたら、どの順で撤去するか**を1箇所に定義する。

## 監視対象issue（anthropics/claude-code）

| Issue | 内容 | 依存する回避策 |
|-------|------|---------------|
| #34330 | commit時のworking tree refreshで.sd/等が消失 | L1/L3/L4, sd-watchdog, Bash Policy(.sd/) |
| #15599 | Bash heredoc破壊 | Bash Policy(heredoc回避) |
| #24956 | パイプstdin消失 | Bash Policy |
| #11225 | 長文コマンド誤動作 | Bash Policy(短い1行commit) |

## 回避策一覧と撤去手順

### A. .sd/ 消失系（#34330）

**現状（2026-06-10実測）: バグは現役。**本日の4コミット中3回で.sd/全消失→L4自動復元が発生。

| 層 | 実装 | 解消確認方法 | 撤去手順 |
|----|------|-------------|---------|
| L1 | .sd/をgitignoreから除外しtracked化 | — | 撤去しない（tracked化は正常な構成。回避策ではなく恒久設計に昇格済み） |
| L3 | `.claude/hooks/block-edit-write-on-sd.sh`（.sd/へのWrite/Edit物理ブロック） | #34330クローズ後、検証: ①Writeで.sd/にファイル作成 ②git commit ③post-commitのwipe警告が**10コミット連続で出ない** | settings.jsonからPreToolUse配線を外す→hookをarchiveへ移動→sd-safe-commit.md改訂→deployテンプレ同期→全配信先に/sd-upgrade |
| L4 | `.git/hooks/post-commit`（ファイル単位wipe検知→`.git/sd-snapshot`復元、フォールバック=HEAD）+ pre-commit強制ステージ+スナップショット採取（2026-06-10 partial wipe対応・未commit保護に強化） | 同上（L3より後に撤去） | 復元ロジックを警告のみに格下げ→1ヶ月無発火を確認→削除。**L4は最後に撤去する（最終防衛線）** |
| 監視 | `.claude/hooks/sd-watchdog.sh`（PostToolUse消失警告） | 同上 | L4撤去と同時 |
| 運用 | sd-safe-commit.md「.sd/はBash経由・早期commit」 | 同上 | L3撤去時に「通常ファイルと同様」へ改訂 |

**撤去順序: L3 → sd-watchdog → 運用ルール → L4（最後）。** 逆順禁止（防衛線を先に外さない）。

### B. Bash Tool Policy（#15599/#24956/#11225）

| 回避策 | 実装 | 解消確認方法 | 撤去手順 |
|--------|------|-------------|---------|
| heredoc回避・Write/Edit優先 | CLAUDE.md「Bash Tool Policy」 | 各issueクローズ後、throwawayブランチで複数heredoc連結・長文コマンドを10回実行し失敗0 | CLAUDE.mdの当該節を削除→deployテンプレ同期 |
| 短い1行commit | 同上 | #11225クローズ | 同上 |

**実測メモ（2026-06-10）**: heredoc 4連結+touch+git連結コマンドがexit 66で無出力失敗（ファイル未作成）。
2-3連結は成功。**安定パターン: Writeでtemp staging（例: `$TEMP/sd003-staging/`）に作成→Bash `cp` で.sd/へ配置**
（L3はWrite/Editのみブロックするためcpは通る）。

### C. AI行動ガードレール（バグ回避ではない・撤去対象外）

以下はClaude Codeのバグではなく**AIの誤行動への恒久ガードレール**。issueクローズで撤去しない:

- `block-sd-destructive.sh`（.sd/へのgit checkout/rm等の破壊操作禁止）
- `block-clasp-deploy.sh` / `block-commit-on-test-fail.sh` / `enforce-skill-read.sh` / `enforce-spec-location.sh` / `workflow-gate.sh`

### D. 環境制約（マシン側・Claude Code無関係）

| 回避策 | 実装 | 解消条件 | 撤去手順 |
|--------|------|---------|---------|
| jest `maxWorkers: 2` | package.json | RAM増設（16GB→32GB+）またはSQL Server等の常駐削減で空き8GB+が常態化 | maxWorkers撤廃→npm test 5回連続でOOMなしを確認 |

実測（2026-06-10）: 空き3.34GB/15.73GBでjestデフォルト並列がOOM（"Zone Allocation failed"）。
ワーカークラッシュはhookのcommitブロック誤発動（テスト自体は通過しているのに失敗扱い）も誘発する。

## 運用

- 四半期に1回（または該当issueのクローズ通知時）この表を見直す
- 撤去は必ず「解消確認方法」の実測を経てから（「直ったはず」での撤去はWork First違反）
- 撤去もコミット・deployテンプレ同期・全配信先への展開まで一気に行う（root-cause-firstの対策完遂原則）
