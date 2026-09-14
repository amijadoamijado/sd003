# DONE.md - 完了報告

対象: `/sessionread` の退避チェックが無音で落ちていた件の真因特定と修正、掃除機構2件の新設、版表記ズレの解消
日時: 2026-09-14 09:07 / ブランチ: master / コミット: f4fcd3a（sd003）, 35d21c82（at002）

---

## やったこと

**変更したファイル**

| ファイル | 変更内容 |
|---------|----------|
| `~/.claude/scripts/archive-sessions.sh` | ループ内 fork を除去（`find -printf` 1回 + bash組込み `printf %()T`）。mv に3回リトライとエラー本文表示を追加。※リポジトリ外・git管理外 |
| `.claude/hooks/prune-skill-state.sh` | **新規**。SessionStart で14日超のスキル読取ログを tar.gz に丸めて削除。24hスロットル・fail-open |
| `.claude/settings.json` | SessionStart に上記フックを配線（timeout 30）。※gitignore対象・ローカルのみ |
| `.claude/skills/sd-deploy/templates/settings.json.template` | 同上（配布に効くのはこちら） |
| `.claude/skills/sd-deploy/deploy.ps1` / `deploy.sh` | `.sd003-keep` 保護下の CLAUDE.md でも版スタンプのトークンだけ in-place 更新 |
| `D:\claudecode\at002\CLAUDE.md` | 版スタンプ 2.18.0 → 2.19.1、旧注記を現行の正に書き換え |
| `.sessions/`, `.handoff/DONE.md` | セッション記録 |

**変更内容の要約**

「ある時点から `/sessionread` で過去セッションの整理が起動しない」の真因は、
`archive-sessions.sh` が1ファイルごとに `stat` / `date` を fork していたこと。
MSYS2 の fork は約67ms/回で、jsonl が1,243件に増えた時点で所要133秒となり
Bashツールの120秒タイムアウトを超え、バックグラウンドへ落ちて無音で消えていた。
09-05 の `78df469` によるステップ削除（`cf9869d` で復旧済）とは別の二つ目の原因。

同じ fork の罠を新規実装の `prune-skill-state.sh` でも踏んだ（`rm` ループで89秒）ため、
`xargs` 化して 3,000件ベンチ 3.3秒に修正済み。

---

## 確認結果

**実行したコマンド**
```bash
npm run build && npm test && npm run lint
bash ~/.claude/scripts/archive-sessions.sh 7 preview   # 修正前後で出力 diff
bash ~/.claude/scripts/archive-sessions.sh 7 execute
bash .claude/hooks/prune-skill-state.sh                # 隔離HOME + 実データ + 3,000件ベンチ
pwsh -NoProfile -Command '...Parser::ParseFile...'     # deploy.ps1 構文
bash -n .claude/skills/sd-deploy/deploy.sh
```

**結果**
```
Test Suites: 12 passed / Tests: 105 passed  （ps1-sh-parity 含む）
build OK / lint OK
archive preview : 133,000ms → 2,801ms、出力は行順含め旧版と完全一致（diff 0）
archive execute : 418件/192MB 移動完了、退避候補 0件（失敗4件はリトライ後に全成功）
prune          : 3,949件 → 1,166件（2,784件を121KBのtarball 1個へ）
prune bench    : 3,000件 3,258ms（rmループ版は 89,172ms）/ スロットル経路 175ms
```

**動作確認**
- [x] 退避チェックが120秒以内に完了し `/sessionread` から報告される
- [x] 退避実行後の候補が0件
- [x] prune が期限切れのみ丸め、`read-skills.log` / `intake-marker.json` / 新しいログは残す
- [x] tar.gz から元ログを復元できる
- [x] 24時間スロットルが二重実行を抑止する
- [x] 保護CLAUDE.mdの版スタンプ in-place 更新が該当1行だけを書き換える（隔離テスト）
- [x] at002 の表記と deploy.ps1 の値が一致（ともに 2.19.1）

---

## 残っていること

**未完了タスク**
- [ ] 版表記ズレの残り22プロジェクト（実体2.19.1・表記のみ古い）。次回 deploy/upgrade で自動整合
- [ ] at002 は `.claude/hooks` を `.sd003-keep` 保護しているため `prune-skill-state.sh` が自動配布されない
- [ ] `prune-skill-state.sh` の初回自動発火確認（今回マーカー作成済のため24時間は無発火が正常）
- [ ] `archive-sessions.sh` は `~/.claude/scripts/` にありgit管理外。sd003にコピーを持つか要検討

**次の手順**
- 次のタスク: 上記のうち at002 への個別配置の要否判断
- 依存関係: なし

---

## 判断したこと

**設計上の選択**

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| prune を PostToolUse(Read) vs SessionStart | SessionStart | track/enforce は全ツール呼び出しで発火する。そこにディレクトリ走査を足せない |
| 期限切れログを削除 vs tar.gz へ丸める | tar.gz | SD003 の rm禁止/アーカイブ移動の趣旨を満たしつつ、ディレクトリは読める状態に戻る |
| 月別アーカイブ vs 実行ごと1ファイル | 実行ごと | tar は追記できない。24hスロットルなので年365個が上限で十分少ない |
| 版スタンプ: 表記を消す vs 保護下でも自動更新 | 自動更新 | 表示自体には価値がある。壊れていたのは「手で更新せよ」というルール依存の部分 |
| 版表記ズレ23件を一括修正 vs at002のみ | at002のみ（ユーザー裁定） | 他22リポジトリに未コミット変更を作らない。2026-03-28の一括処理事故と同型のリスクを回避 |

**採用しなかった案と理由**
- prune を毎回無条件実行: スロットル無しだと初回89秒級の処理がセッション開始を止めうる
- 退避失敗4件を「Drive側の問題」として放置: 手動再試行で成功したため一時的I/Oエラーと確定でき、
  リトライで解決する種類の失敗だった

---

## 追加情報

- **MSYS2 の fork は約67ms/回**（実測: `stat` 100回 = 6,679ms）。シェルでループを書くときは
  ループ内の外部コマンド呼び出し × 件数を必ず見積もる。今回このコストで2箇所（133秒・89秒）が壊れていた
- `/sessionread` の版チェックは `CLAUDE.md` の表記ではなく `deploy.ps1` の `$FRAMEWORK_VERSION` を読む。
  表記はあくまで人向けの表示
- `.claude/settings.json` は sd003 では gitignore 対象。配布に効くのは
  `.claude/skills/sd-deploy/templates/settings.json.template`
