# DONE.md - 完了報告

**日時**: 2026-09-15 08:43
**セッション記録**: `.sessions/session-20260915-084329.md`

---

## やったこと

**変更したファイル**

| ファイル | 変更内容 |
|---------|----------|
| `docs/rules-reference/session/memory-layers.md` | 新規・正本。記憶8層の境界表・判断フロー・昇格・衝突時の優先 |
| `docs/rules-reference/session/memory-nudge.md` | 保存先表を境界表へ委譲（「全PJで使える→auto-memory」の逆転を修正） |
| `CLAUDE.md` | 116行目に判断フロー1行（135行維持） |
| `.claude/rules/session/session-management.md`, `.claude/rules/README.md` | 境界表へのポインタ |
| `.claude/skills/sd-upgrade/upgrade.ps1` / `upgrade.sh` | DELETE list に `notebooklm-memory` 3ミラーを追加 |
| `.claude/commands/sessionwrite.md` ＋ 生成ミラー | Step 8 NotebookLM 撤去 |
| 削除: `.claude/.agents/.grok/skills/notebooklm-memory/`, `.sessions/bash-test.txt` | `.sd/cleanup/archive/20260915-memory-layers/` に保管 |
| `D:\claudecode\CLAUDE.md`（親・`512e7b7`） | 「記憶の置き場（2026-09-15裁定）」1節。beads 生成ブロック外に追記 |
| auto-memory（36件） | claude-mem 現状化・`.kiro` 残存修正・重複2件＋スタブ撤去・索引同期 |

**変更内容の要約**

内部知識4層（規範 / `bd remember` / auto-memory / `.sessions`）の境界が未定義で、親 CLAUDE.md の
「MEMORY.md を使うな」と実態（auto-memory 39件が主力）が割れていた。境界表を1枚作って正とし、
親 CLAUDE.md に裁定を明記、休眠の notebooklm-memory を退役、会話ログ150件を退避した。

---

## 確認結果

**実行したコマンド**

```bash
bash ~/.claude/scripts/archive-sessions.sh 7 execute   # 150件 32MB → G:
python scripts/sync-cli-commands.py --check            # SYNC CHECK OK (20 commands)
cd /d/claudecode/sd003 && claude -p "保存先はどこか×3問"   # 白紙セッション検証
```

**結果**

```
白紙セッション: 3/3 正答（bd remember / kb001 / bd issue）・根拠 memory-layers.md
auto-memory: 索引とファイルの不一致 0件（36件）
sd003 5d3c3bb / 親 512e7b7: origin 同期済み
```

**動作確認**

- [x] 白紙セッションが指示なしで境界表に到達し、昇格規則まで自発適用
- [x] sd003 CLAUDE.md 135行・BOM/EOL 無変更（diff 1行）
- [x] 退避先 G: に実ファイル着地を抜き取り確認、ローカル 7日超 0件
- [x] 退役スキルの archive 保管と git rm、DELETE list 登録

---

## 残っていること

**未完了タスク**

- [ ] `~/.claude-mem/` 28MB の削除（ユーザー判断。`pwsh -Command "Remove-Item -Recurse -Force ~/.claude-mem"`）
- [ ] 配信先46PJ の notebooklm-memory は次回 `/sd-upgrade` で消える（bd issue P3）
- [ ] 関与先 entity を1件作る（kb001・題材待ち）／ hook パス正規化を上流へ連絡（前回持ち越し）

**注意**

- 記憶の保存先は `memory-layers.md` の判断フローで上から1か所だけ。横断的な環境事実は `bd remember`
- 親 CLAUDE.md の beads ブロック内は bd が hash 管理。編集せず外に足す

**関連ファイル**

- 正本: `D:\claudecode\sd003\docs\rules-reference\session\memory-layers.md`
- セッション記録: `D:\claudecode\sd003\.sessions\session-20260915-084329.md`
