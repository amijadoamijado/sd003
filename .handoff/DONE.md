# DONE.md - 完了報告（2026-06-14 セッション）

## やったこと

**変更したファイル（sd003: commit b810931 → 90d0df6）**
| ファイル | 変更内容 |
|---------|----------|
| `.claude/commands/ai-suspect.md` | 新規・主成果物（AI挙動不審の5Why→決定論ガードレール→bd issue） |
| `CLAUDE.md` | Quick Command Reference Debug行に `/ai-suspect` 追記 |
| `.sd/commands/specs/ai-suspect.md` ＋ `manifest.json` | sync生成 |
| `.agents/skills/ai-suspect/` ＋ `.codex/skills/ai-suspect/` | sync生成（agy/codexミラー） |
| `.agents/skills/sd-deploy/*` | v3.1→3.2 mirror drift解消（sync副産物） |
| `.sd/` 全58ファイル | wipe事故から復元（90d0df6） |

**変更内容の要約**
`/ai-suspect` コマンドを新規作成（AIの捏造・過信・ルール不遵守を証拠ベース5Whyで真因特定し、決定論ガードレール＋bd issue登録まで強制クローズ）。途中 commit時に `.sd/` wipeバグが発火したが `git show` ベースでクリーン復旧（データ損失ゼロ）。並行して at002 の bd issue を棚卸しし完了済み5件をclose、登録待ちゲートのsettings.jsonスニペットを作成。

---

## 確認結果

**実行したコマンド**
```bash
python scripts/sync-cli-commands.py        # 3ミラー生成
bd create --dry-run ... (at002)            # bd配線確認
git show e2b2cfb:<path> > <path> (×58)     # .sd/復元
```

**結果**
- ai-suspect: `.claude/commands/` 正本＋3ミラー生成・manifest登録・廃止語clean
- bd: at002で dry-run成功（type/priority/labels正常）・sd003はDB無でフォールバック
- `.sd/`: 全58ファイル復元・git status clean・HEAD tracked 59（+ai-suspect spec）
- at002 bd: 完了済み5件close（open 62→57・各証拠付き）

**動作確認**
- [x] `/ai-suspect` がスキル一覧に出現（登録成功）
- [x] `.sd/` 復元後 git status クリーン
- [ ] `/ai-suspect` 実運用ドライ走行（次回P2）

---

## 残っていること

**未完了タスク**
- [ ] at002 でスニペット①②③適用→再起動→検証→3c0.1/3c0.2/g6q close（P1・要 at002 再起動）
- [ ] 残り配信先への `/sd-upgrade` 展開（P1・継続）
- [ ] `.sd/` wipe `git add -A` リスクを auto-memory に追記（P2）

**次の手順**
- 次のタスク: 上記P1のスニペット適用 or 配信先upgrade
- 依存関係: スニペット検証は at002 での Claude Code 再起動が必要

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| /ai-suspect トリガー | 手動コマンドのみ | 自動ルール併設は判断1で除外（ルール増殖回避） |
| 完了の定義 | 決定論ガードレール＋bd issue登録 | 「気をつける」は対策にあらず（at002流） |
| ゲート頻度 | 3点ゲート | 柱4 Segmented Sequencing（全ステップ確認は過剰） |
| .sd/復元方法 | git show > file | git checkout はguardrailでブロック・非破壊 |

**採用しなかった案と理由**
- b810931 の revert: 良い変更（/ai-suspect）も消えるため、前進修正（git show復元）を採用
- bd auto-close: 未検証closeは虚偽報告の再発。証拠付き手動closeのみ

---

## 追加情報
- bd: global CLI、DBは各PJ `.beads/`。at002操作は `BEADS_DIR=/d/claudecode/at002/.beads bd ...`
- at002 `.beads/`（5件close）と `materials/text/` 新ファイルは未コミット（at002側・ユーザー判断）
- auto mode（auto-accept edits）は次回起動から全PJ有効（グローバルsettings.json）

---
