# DONE.md - 完了報告

Grok Lead。PreToolUse 誤動作を WSL なしの Windows だけで直した。

---

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `scripts/run-hook.js` | 新規。WSL スタブを使わず Git Bash で Claude 形式フックを起動 |
| `.claude/settings.json` | 実行時配線を `node run-hook.js` 経由へ（gitignore） |
| `.claude/skills/sd-deploy/templates/settings.json.template` | 正本を同じ配線に |
| `.claude/skills/sd-deploy/deploy.ps1` / `deploy.sh` | `run-hook.js` を配布 |
| `scripts/verify-deployment.mjs` | C2a（ランチャー同期） |
| User PATH | `d:\Program Files\Git\bin` を先頭追加（git 外） |

**変更内容の要約**
Grok が毎ツールで PreToolUse を失敗させていた原因は、未導入 WSL の `System32\bash.exe` だった。フック起動を Git Bash に切り替え、User PATH からも Git Bash が先に見えるようにした。

---

## 確認結果

**実行したコマンド**
```
node scripts/run-hook.js <hook.sh>   # Git Bash / exit 0 / deny JSON
node scripts/verify-deployment.mjs D:\claudecode\sd003 D:\claudecode\sd003
where.exe bash
```

**結果**
- ランチャー経由: session-skill-suggest / prune / watchdog = exit 0
- Grok 形式 payload の clasp undeploy = deny JSON
- verify-deployment C1〜C8 PASS（C2a 含む）
- `where bash` 先頭 = `d:\Program Files\Git\bin\bash.exe`（OSTYPE=msys）

**動作確認**
- [x] WSL スタブを使わないこと
- [x] Git Bash でフックが exit 0
- [ ] 新しい Grok セッションでの hook_execution 失敗ゼロ（再起動後）

---

## 残っていること

**未完了タスク**
- [ ] Grok を再起動して、この窓に残っている旧 `bash` フック失敗が消えることを確認する
- [ ] 既存デプロイ先へ `run-hook.js` を `/sd-upgrade` で渡す
- [ ] aa001 の npm / gas-fakes 要否（別セッション）
- [ ] aa001 空バックアップフォルダの整理

**次の手順**
- 次のタスク: Grok を終了して新しいセッションを開く
- 依存関係: この窓のフック一覧は起動時キャッシュ

---

## 判断したこと

**設計上の選択**
| 選択肢 | 採用 | 理由 |
|--------|------|------|
| WSL 導入 | しない | ユーザーが入れる予定なし |
| Claude フック取り込みを切る | しない | ガードが死ぬ |
| Git Bash ランチャー + PATH | 採用 | 既存 .sh を温存し、Windows だけで動く |

**採用しなかった案と理由**
- `compat.claude.hooks = false`: 失敗表示は消えるが clasp / `.sd/` ガードが Grok で無効
- フックを全部 pwsh に書き直し: 範囲过大、Git Bash が既にある

---

## 追加情報

- 詳細: `.sessions/session-20260919-163416.md`
- Lead lock: grok
