# DONE.md - 完了報告（2026-10-02 23:10 Claude Code セッション）

## やったこと

**変更したもの**
| 対象 | 変更内容 |
|------|----------|
| `D:\claudecode` 直下・`D:\` 直下 | 不要物を `D:\_cleanup_candidates_20261002\` に集約（移動のみ。一覧は同フォルダの `MANIFEST.md`） |
| `D:\claudecode\PROJECT_REGISTRY.md` | 例外リストの ffmpeg・serena・SuperClaude_Framework を「退避済」に更新（`D:\claudecode` の `8250f6c`・未 push） |
| `D:\claudecode\aa001\.tmp` | 約11GB を削除（再生成物）。D: の空き 11.1GB → 21.5GB |
| `HKCU:\Software\Google\DriveFS` | `ContentCachePath` = `F:\GoogleDriveCache`（Drive のキャッシュを F: へ） |
| C: 上 | Drive の Logs・Orca の AppData を削除、OneDrive をオンラインのみに設定。C: の空き 3.5GB → 5.1GB |

**変更内容の要約**
D: と C: の容量逼迫への対応。整理は移動のみで、削除したのは再生成物（`aa001\.tmp`・Drive の Logs）と、ユーザーが使わないと明言した Orca のデータだけ。

---

## 確認結果

- worktree 13個＋3個の移動後も、`git worktree list` で新しいパスに更新されていることを確認
- Drive 再起動後に `G:\マイドライブ\ob001-raw-exports` が見えること、`F:\GoogleDriveCache` に `content_cache` が作られることを確認
- `aa001\.tmp` の削除後、残りはファイル157個（5.5MB）・フォルダ0個
- sd003 のコードは変更していないため、テスト・ビルドは対象外

---

## 残っていること

- [ ] **P0** `Desktop`（8.8GB）と `Documents`（8.4GB）の中身を一覧にして整理方針を決める（ユーザー「明日やる」）
- [ ] **P1** Google ドライブへの退避は未完了。`robocopy` は約21,000ファイルで中止。G: に途中コピーが残る（残すか消すか未決定）。`D:\tmp\upload`（約27GB）・`D:\claudecode\.archive`（約22GB）は未コピー。zip にまとめる案あり
- [ ] **P1** `D:\claudecode` ルートの commit `8250f6c` を push する
- [ ] **P1** `C:\Windows\SoftwareDistribution.old`（2.7GB）を管理者権限で削除（コマンドはユーザーに案内済み）
- [ ] **P1** `pagefile.sys`（9.1GB）を F: へ移す案（再起動が必要）
- [ ] P2 `.codex\sessions` の整理、Cowork 利用時の `vm_bundles` 対策、Orca 本体のアンインストール、`MANIFEST.md` の追記

---

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| Drive のキャッシュを junction で F: へ | 不採用 | Drive が junction を「ディレクトリではない」と判断して起動に失敗した。元に戻した |
| レジストリ `ContentCachePath` で F: へ | 採用 | 公式の設定で、再起動時に自動で移る。戻すときは値を消すだけ |
| 整理は削除せず1か所へ移動 | 採用 | あとで Google ドライブへまとめて移す方針（ユーザー指示） |
| Drive へのコピーを zip なしで続ける | 不採用（中止） | 細かいファイルが多く時間がかかるため、ユーザーが時間切れで中止を指示 |
