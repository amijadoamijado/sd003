# スキル確認必須ルール（ファイル操作前）

## 物理ガードレール（PreToolUse hook で強制）

> このルールは**ルール宣言だけでなく hook による物理強制**として実装されている。
> AIの「読まなくても分かる」という判断を介在させない。

| 構成 | パス | 役割 |
|------|------|------|
| 中央レジストリ | `.claude/skills/registry.json` | 拡張子/キーワード/path → 必読skill逆引き |
| PreToolUse hook | `.claude/hooks/enforce-skill-read.sh` | 該当 skill 未読なら Bash/Write/Edit/MultiEdit を deny |
| PostToolUse hook | `.claude/hooks/track-skill-read.sh` | SKILL.md の Read を `~/.claude/state/sd003/read-skills.log` に追記 |
| SessionStart hook | `.claude/hooks/session-skill-suggest.sh` | P0/P1タスクから必読skillを起動時に提示 |

該当ファイル拡張子・キーワード・path に触ろうとした時、対応する SKILL.md を**このセッションでまだ Read していない**場合、ツール呼び出しは hook によって `permissionDecision=deny` で物理ブロックされる。

## 原則

> ファイル操作（Excel, CSV, PDF, 画像等）を行う前に、必ず `skills/` フォルダを確認する。
> 該当スキルがあれば、その手順に**厳密に**従う。

## 背景（2回の事故 → 物理ガードレール化）

### 事故1: cf001（過去）
cf001プロジェクトで、AIが `.claude/skills/` を確認せずにExcelファイル操作を開始。
`consolidated_pl_update_skill.md` にExcel COM必須・xlsxライブラリ禁止と明記されていたが、
スキルの存在を知らないままxlsxライブラリで書き出し、書式・罫線・色・列幅が全破壊された。

→ 対策: ルール文書 `skill-check-before-action.md` を追加（**宣言のみ**）

### 事故2: サクセス変換（2026-04-26 再発）
奉行→弥生CSV変換タスクで AI が SKILL.md を未読のまま作業。前セッションで自分が作ったテストCSVを「正解の参照」と誤認し、複合仕訳バグを出した。
ルール文書は存在したが、AIは「読まなくても分かる」と判断してスキップ。

→ 対策: **物理ガードレール（hook + registry.json）に格上げ**。AIの判断を介在させない。

**失敗チェーン**:
1. `skills/` フォルダ未確認で作業開始
2. 該当スキルの存在を知らないまま独自実装
3. スキルの禁止事項（Excel COM必須 / 業務ルール）に違反
4. レイアウト崩壊 / バグ → ユーザー指摘で初めてスキル発見

## 確認フロー（3ステップ・省略禁止）

```
Step 1: skills/ フォルダを検索
  → .claude/skills/ 配下を glob で確認
  → ファイル操作対象に関連するスキルがあるか確認

Step 2: 該当スキルがあれば SKILL.md を読む
  → 必須ツール、禁止事項、手順を把握
  → スキルの指示に厳密に従う
  → Read ツールで読むこと（track-skill-read.sh が log に追記する）

Step 3: 該当スキルがなければ通常手順で実行
  → スキルが存在しない場合のみ、独自判断で実装
```

**ただし Step 1-2 を AI が省略しても、PreToolUse hook が物理的に止める。**
hook がブロックした場合の対応:
1. ブロック理由に表示された SKILL.md パスを Read で読む
2. SKILL.md の指示を理解する
3. 同じツール呼び出しを再試行 → 通る

## チェックリスト

ファイル操作を開始する前に以下を確認:

- [ ] `.claude/skills/` を検索したか？
- [ ] 対象ファイル形式に関連するスキルがあるか確認したか？
- [ ] スキルがある場合、SKILL.md の禁止事項を読んだか？
- [ ] スキルの指定ツール（例: Excel COM）を使用しているか？

## 対象となるファイル操作

| 操作 | 例 |
|------|-----|
| Excel読み書き | `.xls`, `.xlsx` の読込・書出・更新 |
| CSV加工 | `.csv` の変換・集計 |
| PDF生成 | レポート出力 |
| 画像処理 | リサイズ・変換 |
| データ変換 | フォーマット変換全般 |

## 違反時の復元手順

スキル未確認でファイルを破損した場合:

1. 破損ファイルをアーカイブに移動（削除禁止）
2. 元ファイルのバックアップから復元
3. 該当スキルを確認し、正しい手順で再実行
4. `docs/troubleshooting/RESOLUTION_LOG.md` に記録

## 全AIモデル共通

このルールはClaude Code、Codex、Gemini CLI、Antigravity全てに適用される。
`.handoff/RULES.md` の禁止事項にも記載済み。
