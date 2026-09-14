# DONE.md - 完了報告

**日時**: 2026-09-15 06:05
**セッション記録**: `.sessions/session-20260915-060556.md`

---

## やったこと

**変更したファイル**

| ファイル | 変更内容 |
|---------|----------|
| `D:\claudecode\kb001\`（新規プロジェクト） | llm-wiki v4 を配置。115ファイル・commits 15・**remote なし** |
| `D:\claudecode\kb001\.gitattributes` | 新規。`* -text`（`eol=lf` は CRLF 試験体 `e1-crlf` を壊すため不可） |
| `D:\claudecode\kb001\CLAUDE.md` | Windows 固有節を追加（LF/BOM 禁止・remote なし・rg の2つの罠） |
| `D:\claudecode\kb001\scripts\hook-lint.sh` | Windows パス正規化。hook 2本の無症状スキップを修正（`77736af`） |
| `D:\claudecode\sd003\CLAUDE.md` | Conditional Context に kb001 ルーティング1行（135行・上限200以内） |
| `D:\claudecode\PROJECT_REGISTRY.md` | kb001 をツール/実験系へ登録 |

**変更内容の要約**

SD003 に欠けていた「外の世界の知識」層を、別 repo（kb001 = llm-wiki）として設置した。
SD003 からは CLAUDE.md の1行だけで司書に到達する。SD003 内部の知識（手順・真因・規範）は
llm-wiki の `BRIEF.md §3` の境界に従い kb001 に入れない。

---

## 確認結果

**実行したコマンド**

```bash
node scripts/wiki lint --all          # kb001
cd /d/claudecode/kb001 && claude -p "…"   # headless 司書（投入・読み出し・庭師）
cd /d/claudecode/sd003 && claude -p "…"   # ルーティング検証
```

**結果**

```
lint --all: E0 / X0 (exit 0) · 114ファイル 0.144秒
kb001: entities 27 / records 16 / 未commit 0 / remote 0
sd003, D:\claudecode: push 済み (ahead 0)
```

**動作確認**

- [x] P0 器の設置 — lint E0/X0、CRLF/BOM の持ち込みなし、上流無改変版を `7d2f73a` に保存
- [x] P1 投入4件 → 白紙セッションがパス無しで全件を根拠パス付きで読み出し
- [x] P2 SD003 から指示なしで kb001 に到達（初版は失敗 → 順序の規則に書き換えて通過）
- [x] P3 庭師1周（修理1件・残件列挙・再訪3件・unresolved 滞留0）
- [x] hook 修正が実セッションで効くことを、同一セッション内の台帳生成で実測確認

---

## 残っていること

**未完了タスク**

- [ ] 関与先 entity を1件作る（事実を持っていないため未着手。ユーザーが題材を出す必要あり）
- [ ] hook パス正規化をまさお氏（上流）へ連絡
- [ ] 庭師の残件（W5 空の器8件 / W2 孤児1件）の可否をユーザー確認
- [ ] 2週間の運用評価（「入れたのに引けなかった」0件か）

**注意（バグとして追わないこと）**

- kb001 の `wiki save` / `sync` が出す push 失敗警告は**正常**。remote を意図的に付けていない
- kb001 の司書は `cd /d/claudecode/kb001 && claude -p "<自然文>"` で呼ぶ。
  SD003 側から直接ファイルを触っても司書ハーネスは効かない

**関連ファイル**

- 設計案（Artifact）: https://claude.ai/code/artifact/a1d69e84-fed5-4ea3-97c8-e2e2f03367cd
- 配置元: `C:\Users\a-odajima\Downloads\llm-wiki-main.zip`
- セッション記録: `D:\claudecode\sd003\.sessions\session-20260915-060556.md`
