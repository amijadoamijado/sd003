# DONE.md - 完了報告（2026-06-15 GLM運用構成セッション）

## やったこと

**変更したファイル**（全て gitignore 対象＝非commit。正本/メモリ含む）
| ファイル | 変更内容 |
|---------|----------|
| `C:\Users\a-odajima\.claude\settings.json` | `alwaysThinkingEnabled:false`（思考暴走対策・ユーザー手動反映） |
| `D:\claudecode\sd003\.claude\settings.local.json` | `deny:["Agent","Task"]` 追記（local上書き問題の修正） |
| `D:\claudecode\.claude\settings-glm.json` | `alwaysThinkingEnabled:false`（正本） |
| `...\memory\feedback_glm_zai_model_selection.md` | GLM知見を新規保存＋実証3件追記 |
| `...\memory\MEMORY.md` | index 追記 |

**変更内容の要約**
z.ai GLM運用構成（5.2メイン+4.7背景+deny封印+ToolSearch無効）を検証・修正した。グローバル `deny:[Agent,Task]` が PJ local の `deny:[]` に上書きされ無効化していた問題を発見し sd003 local に deny 追記。alwaysThinkingEnabled:false で思考暴走を11分→6分に半減。

---

## 確認結果

**動作確認（新規セッション実測）**
- [x] メイン `glm-5.2[1m]` 表示確認
- [x] deny有効化＝Agent/Task呼ばずBash直実行にフォールバック、`/sessionread` 正常完走（文字化けタスク事故ゼロ）
- [x] alwaysThinkingEnabled:false で思考11分→6分に半減
- [x] auto-mode `⏵⏵ accept edits on` 表示確認（前回P0クローズ）

---

## 残っていること

**未完了タスク（前回からの継続）**
- [ ] P1: sd003 `bd init` → /ai-suspect incident を正式 issue 化して close
- [ ] P1: claim-evidence ガードレールを deploy テンプレ `settings.json.template` へ展開
- [ ] P2: 他PJ local の `deny` 確認（GLM運用PJは `deny:[Agent,Task]` 追記必要・local上書き問題）

**次の手順**
- glm-5.2 の6分応答はユーザー判断で解決扱い（モデル更新待ち・再検証不要）

---

## 判断したこと

| 選択肢 | 採用 | 理由 |
|--------|------|------|
| alwaysThinking true vs false | false (B1) | 5.2能力維持しつつ思考暴走（最大の害）を抑止 |
| deny修正の即実行 vs 承認待ち | 承認待ち→明示的go後実行 | classifierが選択≠承認を検出。前回/ai-suspect真因と同根の自戒 |
| glm-5.2の6分応答 | issue化せず解決扱い | モデル自体の遅さ＝モデル更新待ち（ユーザー判断） |

---

## 追加情報
- **設定は起動時1回読込**。検証は必ず新規セッション起動で行う（起動済みセッションには非反映）。
- deny の local 上書きは横展開要注意（グローバルだけでは各PJに効かない）。

---
