# DONE.md - 完了報告（2026-09-19 23:51）

## やったこと

**変更したファイル**
| ファイル | 変更内容 |
|---------|----------|
| `scripts/ai-usage-monitor.py` | Grok 直書き値を撤去し、Grok CLI ログ（`D:\grok\logs\unified.jsonl`）の最新課金情報を表示。切替案内を絶対パス化 |
| `.claude/commands/ai-usage.md` | スクリプトを絶対パスで呼ぶ形に変更 |
| `C:\Users\a-odajima\.claude\commands\ai-usage.md` | 個人用コマンドを新設（どのPJからでも `/ai-usage`） |

**変更内容の要約**
`/ai-usage` をどのプロジェクトからでも使えるようにし、Grok 欄を直書きの値から Grok 自身のログの実値へ切り替えた。

---

## 確認結果

**実行したコマンド**
```bash
cd /d/claudecode/at002 && python D:/claudecode/sd003/scripts/ai-usage-monitor.py
python D:/claudecode/sd003/scripts/ai-usage-monitor.py
```

**動作確認**
- [x] at002 から実行して4サービスとも表示
- [x] Grok: SuperGrok・残り0%・期限 09/20 17:16 JST・記録時刻 09/19 17:41 JST を表示
- [x] 別セッションのコミット 71cb683 後も Grok 表示が動作

---

## 残っていること

**未完了タスク**
- [ ] Grok は起動時点の値のみ（起動後の消費は反映されない）
- [ ] 個人用と sd003 のコマンド定義が二重管理（sd003 更新時は個人用へコピー）

**次の手順**
- 71cb683 を入れた別セッションがどのCLIか確認（同じスクリプトを並行編集している）

---

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| スクリプトを各PJへ配る | 不採用 | 修正時に古いコピーが残る |
| 取得できない値を直書きで補う | 不採用 | 実データと見分けがつかない |
| Grok ログの課金行を読む | 採用 | Grok が起動時に実値を記録している |

---

## 追加情報
- 詳細記録: `D:\claudecode\sd003\.sessions\session-20260919-235133.md`
