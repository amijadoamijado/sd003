# DONE.md - 完了報告

日時: 2026-09-16 10:20:36 ／ プロジェクト: D:\claudecode\sd003
対象: D:\claudecode\aa001（新規展開先）／ D:\claudecode（親repo・台帳）
セッション記録: `.sessions/session-20260916-102036.md`

---

## やったこと

**変更したファイル**

| ファイル | 変更内容 |
|---------|----------|
| `.claude/skills/sd-deploy/deploy.ps1` | Phase 1b（gitリポジトリ判定）/ Phase 1c（ソース未コミット警告）を新設 |
| `.claude/skills/sd-deploy/deploy.sh` | 同上 + settings.json を heredoc からテンプレート配布へ統一（既存バグ修正） |
| `.claude/skills/sd-deploy/SKILL.md` | Phase 1b/1c の仕様、Windowsパスの要クォートを明文化 |
| `.gitignore` | `materials/releases/`（691MB・関与先データzip）を除外 |
| `.claude/skills/codex-security/` ほか計6件 | 未コミットだったフレームワーク実体を新規commit |
| `D:\claudecode\aa001\`（608ファイル） | SD003 v2.19.2 を新規展開＋独立リポジトリ化＋private remote |
| `D:\claudecode\PROJECT_REGISTRY.md` | aa001 を登録（会計自動化ツール・active） |

**変更内容の要約**

空フォルダだった aa001 に SD003 を展開し、独立 git リポジトリ化して private remote へ push、台帳登録まで完了した。その過程で見つかった deploy の欠陥2件（①展開先をリポジトリ化しないままフックだけ置く ②deploy.sh の settings.json 正本が二重化しフック2本が欠落）を deploy.ps1 / deploy.sh 両方で修正し、実測で検証した。

---

## 確認結果

**実行したコマンド**

```bash
pwsh -File .claude/skills/sd-deploy/deploy.ps1 'D:\claudecode\aa001' [-DryRun]
bash  .claude/skills/sd-deploy/deploy.sh  <scratch-target>            # 3レイアウト × dry-run / 実run
gh repo create amijadoamijado/aa001 --private --source=. --remote=origin
git -C D:/claudecode/aa001 init -b master && git push -u origin master
```

**結果**

```
aa001 deploy : copied 600 / generated 8 -> ALL PASSED
               Phase 6 件数10項目 全PASS / Phase 6b C1〜C8 全PASS
Phase 1b 検証: 3レイアウト（リポジトリ外 / 親がignore / 親が追跡）を ps1・sh 双方で実測
               -> init / init / 警告のみ と期待どおり分岐
ps1 実run    : git init -> SD003フック残存 -> commit時 pre-commit 実発火（.sd/ 32件 自動ステージ）
sh 実run     : 修正前 [FAIL] C1 -> 修正後 Content verification PASSED / ALL PASSED / EXIT=0
               生成 settings.json に orchestrator-guard(PreToolUse) と prune-skill-state(SessionStart) を確認
配線の欠落   : 旧heredoc 17本 ⊂ テンプレ 19本（差分は上記2本の追加のみ＝失われる配線ゼロ）
最終状態     : sd003 / aa001 / 親repo すべて master...origin/master 同期、テストプロセス残骸0
```

**動作確認**

- [x] dry-run で失われる固有化がゼロであることを事前確認してから本実行
- [x] Phase 6b 内容検証が全PASS（aa001 / ps1テスト標的 / sh修正後標的）
- [x] auto-init 後に pre-commit が**実際に発火**することを確認（推測ではない）
- [x] Phase 1b の3分岐が ps1・sh 双方で一致
- [x] settings.json テンプレ統一で失われる配線がゼロであることを集合突合で確認
- [x] aa001 remote が PRIVATE であることを `gh repo view` で確認

---

## 残っていること

**未完了タスク**

- [ ] **既存デプロイ先への Phase 1b/1c 伝播**。修正は展開元のみで、各PJは `/sd-upgrade` を1回走らせるまで受け取らない。特に Linux/Mac 経由の配布先は settings.json に `orchestrator-guard.js`（PreToolUse）が入っていない可能性がある
- [ ] aa001 の `npm install` / gas-fakes の要否判断（aa001 は GAS ではないため不要の可能性が高い。別セッションの実装方針待ち）
- [ ] `D:\claudecode\aa001\.sd003-backup-20260916_080708`（空フォルダ）の整理方針。rm禁止ルールに従い残置中

**次の手順**

- 次のタスク: 配布先の洗い出しと `/sd-upgrade` 適用の要否判断
- 依存関係: aa001 の実装は別セッションが進行中。`src/` `scripts/accounting/` `tests/accounting/` は未コミットのまま**触らないこと**

---

## 判断したこと

**設計上の選択**

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 非リポジトリを常に `git init` / 条件付き | **条件付き（4分岐）** | 無条件だと monorepo のサブパッケージに勝手な入れ子リポジトリを作る。親が ignore していれば「親が管理を放棄」と確定できるので init、追跡していれば警告のみ |
| aa001 remote: private GitHub / ローカルのみ | **private GitHub** | at002・iv001・ta001・oc001 が全て PRIVATE と実測。顧客データ案件は非公開repoが確立パターン |
| deploy.sh の settings.json: heredoc 修正 / テンプレ統一 | **テンプレ統一** | heredoc を直しても正本が2つのままで同じ取り残しが再発する。正本を1つにするのが真因対処 |
| `materials/releases/`: commit / gitignore | **gitignore** | 691MB・最大380MB。GitHub 100MB上限は履歴書き換えなしに解除不能。かつ sd003 は public repo で中身は関与先データzip |
| `codex-security` 等: commit / 退避 | **commit** | `.sd003-managed` 付き・sync check OK の正規SD003スキル。既に全配布先へ渡っており、commit しないと配布が再現不能 |

**採用しなかった案と理由**

- deploy.sh の settings.json 欠落を「C1 が指摘した1本だけ」直す: 集合突合で2本目（PreToolUse の orchestrator-guard）が見つかった。エラーメッセージの範囲で直すと防御不活性が残る
- aa001 の `src/` 等を一緒にコミット: 別セッションが実装中のため、作業を横取りしない

---

## 追加情報

- **deploy.ps1 は UTF-8 BOM + CRLF 必須**（PS5.1 の CP932 誤読対策）。python で編集するときは**読み書き両方に `newline=''`** を指定すること（片方だけだと CRLF→LF に潰れる。本セッションで一度壊して復旧した）。deploy.sh は逆に BOM厳禁・LF
- **PowerShell から native git**: `$ErrorActionPreference='Stop'` 下では PS7.4+ が失敗を終了エラー化するため `$PSNativeCommandUseErrorActionPreference=$false` を関数スコープで設定。また `-C` を裸で渡すと PowerShell がパラメータ名と解釈するので git 引数は配列で渡す
- **deploy.sh は MSYS2 の fork コストで数分かかる**。Bashツールの120秒制限を超えるのでログへリダイレクト＋バックグラウンド実行。`run_in_background` とパイプの組み合わせは結果を取りこぼすことがある
- **aa001 は並行セッションが動いている**。触る前に `git log` / `git status` で進捗確認
- **sd003 は public repo**。コミット前に関与先データの混入を毎回確認

---
