# DONE.md - 完了報告（2026-09-27 19:58 Claude Code セッション）

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `scripts/run-hook.js` | `--only=<preset>` を追加。関係ないコマンドでは bash を起動せずに抜ける |
| `.claude/hooks/block-commit-on-test-fail.sh` | ドキュメントだけの commit では全テストを省く |
| `.claude/skills/sd-deploy/templates/settings.json.template` | Bash 用の7つの hook に `--only` を付けた |
| `CLAUDE.md` | Build & Test・Quick Command Reference を削除し、Grok の段落を短縮（「Lead mode」の語は残す） |
| `.claude/rules/global/claude-md-style.md` | 「書かないもの（コードから分かる内容）」の節を追加 |
| `D:\claudecode\CLAUDE.md` | 改訂履歴を削除（D:\claudecode 13d9d27） |

**変更内容の要約**
/doctor の結果を反映して、使っていない skill・plugin を無効化し、指示ファイルを削った。保護 hook は、関係ないコマンドのときに bash を起動しない形にして高速化した。

---

## 確認結果

- `--only` の動作: 関係ないコマンドは約0.25秒で抜ける。`.sd` を消す rm と clasp deploy では、今までどおり拒否する
- commit 時のテスト hook が初めて最後まで走り、verify-deployment の C7 失敗を検出した。原因の CLAUDE.md の語句を戻した後、C7 は PASS、commit も通った
- ドキュメントだけの commit（42c4fb0）では、テストを省略して即時に commit できた

---

## 残っていること

- [ ] 配布先へ run-hook.js と設定を展開（`/sd-upgrade`。`.sd003-keep` で保護している PJ は手動）。commit 時のテストが初めて本当に走るので、隠れていた失敗が出る前提で進める
- [ ] `CLAUDE.md.template` の Build & Test・Quick Command Reference を新しいスタイルガイドに揃えるか判断する
- [ ] MCP の無効化は sd003 だけ。他 PJ では `/mcp` を操作するか、claude.ai の Connectors から外す
- [ ] 本セッション外の未 commit 変更（`sessionwrite.md`, `ai-usage-monitor.py`）と、未追跡の `session-20260926-131310.md`

---

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| 保護 hook を1本の node に書き直す | 不採用 | 保護の中身を作り直すことになり、ずれる危険がある |
| run-hook.js で事前にふるい分ける（`--only`） | 採用 | 各 hook の反応条件をすべて含む条件で判定するので、保護範囲は変わらない |
| commit 時のテストを関連テストだけに絞る | 不採用 | 配布先ごとにテストの仕組みが違う。ドキュメントだけの commit を省く方が安全 |
