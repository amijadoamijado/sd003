# 記憶の層（Memory Layers）

## 原則

> 記憶の置き場は「誰が・いつ・何のために読むか」で決まる。
> 同じ事実を2か所に書かない。書くなら上位が正、下位はポインタか削除。

## 背景

2026-09-15 の棚卸しで、記憶が7層に分散し、内部知識の4層
（規範 / auto-memory / `bd remember` / `.sessions`）の境界がどこにも書かれていないと判明。
親 `D:\claudecode\CLAUDE.md` の beads 定型文「`MEMORY.md` を使うな」に対し、
実態は auto-memory 39件が主力・`bd remember` は2件で、ルールと運用が割れていた。
前日（09-14）に kb001（repo外の世界）だけ線を引いたので、本書で残りを引く。

## 層の一覧

| 層 | 実体 | 入れるもの | 読む主体 | 寿命 |
|----|------|-----------|---------|------|
| 規範 | `CLAUDE.md`・`.claude/rules/`・`docs/rules-reference/` | 守らせる行動。事故の再発防止。ガードレール同時設計 | 全CLI・毎セッション自動 | 恒久（改訂履歴つき） |
| 横断知見 | `bd remember`（`D:\claudecode\.beads`） | `D:\claudecode` 全PJ・全CLIに効く環境事実・規約の要点。アカウント/マシン跨ぎで持ち越すもの | `bd prime` を打つ全CLI | 恒久 |
| PJ知見 | auto-memory `~/.claude/projects/<PJ>/memory/` + `MEMORY.md` 索引 | このPJで Claude Code が次回も使う知見（feedback / project / reference / user） | Claude Code のみ・このマシンのみ・自動注入 | 陳腐化したら削除 |
| 経緯 | `.sessions/`（session-current / session-* / TIMELINE） | 何をした・何が未検証・次に何をするか。「いつ」が意味を持つもの | `/sessionread` を打ったCLI | 追記のみ（会話ログは7日超を退避） |
| 受け渡し | `.handoff/ORDER.md` `DONE.md` | いま次のAIへ渡す指示と結果 | 次に起動するCLI | 1回限り・上書き |
| 課題 | `bd` issues | やること。知識ではない | 全CLI | close で終了 |
| 仕様 | `.sd/specs/{feature}/` | 何を作るか・決定の履歴 | 実装するCLI | feature 単位 |
| 外の世界 | kb001（llm-wiki）の司書 | repo外の事実（顧客・制度・ツール仕様・記事・人） | `cd /d/claudecode/kb001 && claude -p` | 恒久 |

## 判断フロー（上から最初に当たった所へ・1か所だけ）

1. 対象は repo の外か（顧客・制度・製品・記事・人）→ **kb001**
2. 「やること」か → **bd issue**
3. 「守らせたい行動」か（同じ事故を二度起こさない）→ **規範**（CLAUDE.md 1行 + rules-reference + ガードレール）
4. `D:\claudecode` の他PJ・他CLIでも効くか → **bd remember**
5. このPJで Claude Code が次回も使うか → **auto-memory**
6. いつ・何をした・何が未検証か → **.sessions**（`/sessionwrite`）
7. どれでもない → **書かない**

## 昇格（下から上へ・3回出てから）

`.sessions` 備考 →（同種の修正2回: learning-nudge が提案）→ auto-memory
→（他PJ・他CLIで再び要る）→ `bd remember` →（行動を強制する必要）→ 規範 + ガードレール。

既存の auto-memory は一括移行しない。触ったときに上の層へ動かし、元は削除する。

## 衝突したら

上位が正: **規範 > bd remember > auto-memory > .sessions**。下位は削除かポインタ化。
親 CLAUDE.md の beads 定型文「`MEMORY.md` を使うな」は auto-memory との共存を否定しない
（`bd remember` の射程は横断、auto-memory は PJ 別。2026-09-15 裁定、親 CLAUDE.md に明記）。

## 退役・休眠（2026-09-15）

| 対象 | 状態 | 処置 |
|------|------|------|
| `notebooklm-memory` スキル | 必須設定 `.sd/notebooklm-config.json` がどのPJにも無く、配信46PJで一度も起動していない | 退役。`.sd/cleanup/archive/20260915-memory-layers/` に保管、sd-upgrade の DELETE list に登録（配信先は次回 upgrade で消える） |
| `claude-mem`（非公式） | 本体は撤去済み（npm/hook/plugin 無し） | 残骸 `~/.claude-mem/`（28MB）の削除はユーザー判断 |

## 検証（2026-09-15）

白紙セッション（`cd /d/claudecode/sd003 && claude -p`）に「保存先はどこか、根拠のパス付きで」と3問。
指示なしで本書の判断フローに到達し、(1) .ps1 BOM 欠落の実測 → `bd remember`（手順4）、
(2) 顧問先の決算期 → kb001（手順1）、(3) deploy.ps1 の改修予定 → `bd` issue（手順2）と全問正答。
(1) では既存 auto-memory `reference_ps1_bom_cp932_gotcha.md` を「昇格」節に従い上位へ移す旨まで自発的に述べた。

## 関連

- 保存の自己評価: `memory-nudge.md`（同ディレクトリ）
- 修正パターンの提案: `../skills/learning-nudge.md`
- kb001 の境界: `D:\claudecode\kb001\CLAUDE.md`
