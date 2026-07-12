# Grok Native Operation Guide

このファイルは SD003 を **Grok が Session Lead（司令塔）** として扱う時の実行優先順位を定義する。
Claude Code 正本を置き換えず、Grok が Claude 経由なしで完結するための薄い実行レイヤーである。

正本の役割定義: `.claude/rules/workflow/ai-coordination.md`  
Grok 仕様: `.grok/GROK_SPEC.md`  
運用ガイド: `.sd/ai-coordination/workflow/GROK_GUIDE.md`

## Lead mode とは

| 項目 | 内容 |
|------|------|
| 起動 | ユーザーが Grok CLI / Grok TUI を直接起動した、または「Grok主導で」等の明示 |
| 地位 | そのセッションの **Session Lead**（工程・方針・完了報告の責任者） |
| Assist との差 | `grok-dispatch` で他AIから呼ばれた場合は Assist。repo 所有権は Lead 側 |

Lead mode 中、Grok は「セカンドオピニオン待ち」ではなく **主担当として最後まで進める**。

## 原則

1. Claude Code のスラッシュコマンドを Grok で直接実行しない。意図を読み、同等の作業を Grok 自身で行う。
2. `/workflow:*`、`/codex:*`、他 CLI の再帰呼び出しはしない。必要な差分確認・実装・検証・報告は Grok が行う。
3. 正式 Workflow と日常作業を分ける。案件IDがない場合は会話内で完結する（`.sd/ai-coordination/` に書面を増やさない）。
4. `.claude/commands/**` は authoring source。生成済み `.grok/skills/**` は手編集せず、同期スクリプト経由で更新する。
5. 既存の未コミット変更はユーザーまたは他 AI の作業として扱い、明示指示なしに戻さない・上書きしない。
6. 同一 repo への複数 AI 同時書き込みは禁止。Lead 中は Grok が repo lock を持つ前提で動く。
7. GAS は `clasp push` のみ。`clasp deploy` / `clasp undeploy` はユーザー明示指示なしに実行しない。
8. 人間向け出力は日本語。Windows では PowerShell（`pwsh`）を優先する。
9. 完了 = ユーザーが開ける成果物（画面・ファイル・報告）があり、検証済み（柱1 Output Primacy）。

## セッション開始（Lead 時）

1. `git status --short` と直近コミットを確認する。
2. 可能なら `.sessions/session-current.md` と `.sessions/TIMELINE.md` を読む（sessionread 相当）。
3. 共通ルール `.handoff/RULES.md` と本ファイルを前提にする。
4. 他 AI（codex/agy/別 grok）が同一 repo を編集中でないか注意する。
5. 無知の知: 着手前に「知らないと痛いこと」を1つ以上自己宣言する。

## Fast Review

案件IDなしでレビューやチェックを依頼された場合:

1. `git status --short` で作業ツリーを確認する。
2. `git diff --stat` と必要な `git diff` を読む。
3. 可能な範囲で関連テスト、型チェック、lint を実行する。
4. 指摘は重大度順に、場所・影響・修正案を示す。
5. `.sd/ai-coordination/` には保存しない（会話内完結）。

## Fast Implement

案件IDなしで実装・修正を依頼された場合:

1. 変更範囲を限定し、既存パターンに合わせる。
2. Work First: 動かす → 実環境確認 → 必要なら最小テスト → 抽象化は後。
3. 検証可能なコマンドを実行し、失敗時は原因と残作業を明記する。
4. 不要なリファクタ・スコープ拡大をしない。
5. ユーザー明示なしに force-push、`--hard` reset、ブランチ勝手作成をしない。

## Lead Session（中〜長時間）

1. ゴールと完了条件（ユーザーが何を見ればよいか）を最初に言語化する。
2. 非ブロッキング作業（調査・実装・検証）は連続実行し、確認は末端に集約する。
3. 成果物はプロジェクトツリー内へ（`materials/`、`.sd/`、`docs/` 等）。AppData 隠しパスに残さない。
4. 長時間作業では `.sd/ai-coordination/sessions/grok/` に短い経過メモを残してよい。
5. 終了時は完了報告（何を・どこを・どう検証したか・次手）を日本語で出す。

## いつ他AIへ渡すか（handoff）

| 状況 | 渡す先 | 渡し方 |
|------|--------|--------|
| 公式品質印・厳格レビューが必要 | **Codex** | diff 範囲・観点・確認済み事項を会話または `review/` に要約して依頼 |
| 本番 E2E・iframe 操作・本番確認 | **agy** | 確認対象URL・期待結果・前提を渡す |
| ユーザーが Claude 入口に戻したい | **Claude Code** | session 要約 + 残タスク + 触ったパス |

handoff 時は **repo の同時書き込みを止め**、どちらが lock を持つかを一文で明示する。

## Assist mode との境界

| | Lead mode | Assist mode |
|--|-----------|-------------|
| 起動 | ユーザー直接 / 「Grok主導」 | `grok-dispatch` 等で他AIから |
| 工程判断 | Grok | 呼び出し元 |
| モデル | 対話 TUI 優先（実装は `grok-build` 可） | 既定 `grok-build` + `--output-format plain` |
| 詳細 | 本ファイル | `.claude/skills/grok-dispatch/SKILL.md` |

## Handoff Recovery（他 Lead 停止時）

Claude Code 等のレート制限・停止で Grok が引き継ぐ場合:

1. sessionread 相当（session-current / TIMELINE / git status）を読む。
2. P0/P1、未コミット、検証不足を分ける。
3. 次に安全に進められる最小単位だけ実行する。
4. 完了後、元 Lead 向けの要約を残す。

## 禁止・注意

- 旧7段階ワークフローの書面儀式を復活させない。
- 公式レビュー印の代行を名乗りすぎない（必要なら Codex に渡す）。
- 本番固定デプロイ URL を独断で増やしたり消したりしない。
- 「動くはず」で完了にしない。確認結果を書く。
