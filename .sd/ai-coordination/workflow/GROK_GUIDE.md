# Grok 運用ガイド（Lead / Assist）

正本ルール: `.claude/rules/workflow/ai-coordination.md`  
Native 実行: `.grok/GROK_NATIVE.md`  
仕様: `.grok/GROK_SPEC.md`

## 役割

Grok は SD003 の **Session Lead 候補**。汎用控え専用ではない。

| モード | 地位 | 典型シナリオ |
|--------|------|--------------|
| **Lead** | 司令塔 | ユーザーが Grok TUI を開く / 「Grok主導で」 |
| **Assist** | 被呼び出し | Claude 等から `grok-dispatch` |

### 所有ドメイン（Lead 時の第一候補）

- セッション工程・完了報告
- 探索実装 / worktree 改修 / 中規模実装（担当固定時）
- 調査・独立検証・セカンドパス
- 設計・方針の速い第二意見

### 譲るドメイン

| 領域 | 主担当 |
|------|--------|
| 公式品質印レビュー | Codex |
| 本番 E2E / iframe 操作 | agy |
| `clasp deploy` / 固定URL | ユーザー明示時のみ（独断禁止） |

## Lead mode の始め方

1. リポジトリ直下で Grok CLI / TUI を起動する。
2. **起動直後に `grok.md` と `.grok/GROK_NATIVE.md` を明示的に読ませる。** Grok CLI は `grok.md` を自動検出しない（`grok inspect` の Project Instructions で確認。自動読込されるのは `AGENTS.md` / `CLAUDE.md` / `.claude/rules/*.md` 等のみ。公式: `D:\grok\docs\user-guide\12-project-rules.md`）。
3. 必要なら冒頭で「このセッションは Grok Lead」と明示する（直接起動なら省略可）。
4. `.grok/GROK_NATIVE.md` のセッション開始チェックを行う（`git status`、sessionread 相当、`lead-lock acquire grok`、無知の知）。
5. ゴールと完了条件（ユーザーが何を見ればよいか）を先に書く。
6. 実装・検証を進め、成果物をプロジェクト内に置く。

### Lead トリガー語

`Grok主導で` / `grokで進めて` / `このセッションはGrok` / `Grokに任せる`

## Assist mode の始め方

Claude Code 等から:

```powershell
pwsh -File .claude/skills/grok-dispatch/grok-run.ps1 <repo> <out.txt> "<prompt>" [model]
```

- 既定モデル: `grok-build`
- 最終回答: `out.txt`（stdout plain）
- 詳細: `.claude/skills/grok-dispatch/SKILL.md`

### Assist トリガー語

`grokに依頼` / `grokに相談` / `grokにレビュー` / `grokで実装`（他 Lead から委譲）

## 報告・成果物

| 種別 | 保存先 |
|------|--------|
| アドホック | 会話内完結（書面不要） |
| 正式（案件IDあり） | `review/{案件ID}/` または `spec/{案件ID}/` |
| 長時間 Lead メモ | `../sessions/grok/` |
| ユーザー向け成果物 | `materials/` 等（AppData 禁止） |

Artifact（claude.ai）は Grok では使えない。構造化確認は **HTML / Markdown を materials に置く**か、会話内の簡潔表で代替する。

## handoff（他AIへ渡す）

1. 作業を止め、repo の同時編集を避ける。
2. 渡す内容: 目的、触ったパス、検証結果、残タスク、期待する相手の作業。
3. Codex（レビュー）/ agy（E2E）/ Claude（入口復帰）へ渡す。
4. handoff-logは任意（AI間handoff発生時に1行推奨）。

## 失敗時

- 同型失敗の盲目リトライ禁止（root-cause-first）。
- Assist のフラグ失敗は `*.progress.log` を診断に使う（通常は読まない）。
- RAM 逼迫や他 CLI 稼働中は人手ハンドオフ（依頼をユーザーに返す）。
