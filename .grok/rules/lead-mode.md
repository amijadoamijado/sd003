# Grok Lead Mode（自動読込）

Grok CLI が `.grok/rules/` 経由で自動注入する Lead mode 要約。
詳細正本: `.grok/GROK_NATIVE.md` / `.grok/GROK_SPEC.md` / `.sd/ai-coordination/workflow/GROK_GUIDE.md`

## 地位

- ユーザーが Grok TUI/CLI を直接起動した、または「Grok主導で」等 → **Session Lead**
- `grok-dispatch` で他 AI から呼ばれた場合は **Assist**（工程判断は呼び出し元）

## セッション開始（必須）

1. `git status --short` と直近コミットを確認する。
2. `.sessions/session-current.md` と `.sessions/TIMELINE.md` を読む（sessionread 相当）。
3. `.handoff/RULES.md` を前提にする。
4. repo 直下で `pwsh -File scripts/lead-lock.ps1 acquire grok` を実行する（worktree では `.git` がファイルのため失敗し得る → その場合は本 checkout 直下で取得するか、同時書き込みを避ける）。
5. 無知の知: 着手前に「知らないと痛いこと」を1つ以上自己宣言する。

## 実行原則

1. Claude のスラッシュコマンドは実行しない。意図を読み Grok 自身で同等作業を行う。
2. `/workflow:*`、`/codex:*`、他 CLI の再帰呼び出しはしない。
3. 案件 ID なし → 会話内完結（`.sd/ai-coordination/` に書面を増やさない）。
4. `.claude/commands/**` は authoring source。`.grok/skills/**` は手編集せず sync 経由。
5. 明示指示なしに未コミット変更を戻さない・上書きしない。
6. 同一 repo への複数 AI 同時書き込み禁止。Lead は repo lock を持つ。
7. GAS は `clasp push` のみ。`clasp deploy` / `undeploy` はユーザー明示時のみ。
8. 人間向け出力は日本語。Windows では `pwsh` を優先。
9. 完了 = ユーザーが開ける成果物があり検証済み（柱1 Output Primacy）。

## Work First

動かす → 実環境確認 → 必要なら最小テスト → 抽象化は後。「動くはず」で完了にしない。

## 他 AI へ渡すタイミング

| 状況 | 渡す先 |
|------|--------|
| 公式品質印・厳格レビュー | Codex |
| Blueprint 級実装の完了主張（Quiz Gate） | Codex（自己クイズ禁止） |
| 本番 E2E・iframe 操作 | agy |
| Claude 入口へ復帰 | Claude Code（要約 + 残タスク + 触ったパス） |

handoff 時は同時書き込みを止め、lock 保持者を一文で明示する。

## 終了時

- 完了報告（何を・どこを・どう検証したか・次手）を日本語で出す。
- 大きな区切りでは `.grok/skills/sessionwrite` 相当で `session-current.md` / `TIMELINE.md` を更新する。