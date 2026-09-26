# SD003 Prompt Audit（2026-09-26）

## 前提（Step 0）

- **対象モデル**: Claude Opus 5.5（この監査を実行しているモデル。直近コミット 29f09e3 / 0d12d9a も Opus 5.5 公式ガイド準拠を掲げている）
- **スコープ**: `D:\claudecode\sd003` の Claude Code 向け一次指示ファイル
  - `CLAUDE.md`、`.claude/rules/**`、`.claude/commands/**`、自作 `.claude/skills/*/SKILL.md`（+ `sd-deploy/README.md`）、`.handoff/RULES.md`
- **除外**（読み手が Claude でない／第三者製／プロジェクト外）:
  - `AGENTS.md`・`.codex/`・`.grok/`・`.agents/`（Codex/Grok/agy 向け。`.agents`/`.grok` の skill は `scripts/sync-cli-commands.py` が commands から生成）
  - `_archive/`・`.sd/cleanup/archive/`
  - ベンダー取込スキル: drawio, d3-viz, webapp-testing, skill-creator, beautiful-mermaid, excalidraw-diagram, playwright-e2e-testing, implement-design, find-skills
  - プロジェクト外: `~/.claude/CLAUDE.md`、`D:\claudecode\CLAUDE.md`（指摘の根拠には使ったが編集提案はしない）
  - settings*.json・hooks・.mcp.json は読んでいない（秘密情報の可能性）
- **非Anthropic プロバイダ痕跡**: Codex/GPT・Grok・Gemini 協調文書あり（上記除外で扱い）。Claude API 呼び出しコードは無し

## サマリー

最も効くのは次の3点。

1. **存在しないコマンド・パスが常時／頻出ロードの指示に残っている。** `/spec:archive`・`/sd:validate-*`・`/workflow:*`・`/refactor:*`・`/cleanup:restore`・`/sd:deploy`・`.claude/rules/global/work-first.md` など。特に `spec-driven.md` は paths 制約なしで毎セッション注入され、存在しない検証コマンド3つを案内している。Opus 5.5 は指示を字義通りに追うので、存在しない道具を探しに行く。
2. **実行できない／危険な手順がスキルに残っている。** `blueprint-gate` は `.sd/specs/` への保存を Write で指示するが、Write は hook でブロックされ、Bash は allowed-tools に無い（主目的の保存が構造的に不可能）。`gas-e2e` の「AIの自律実行手順」はユーザーの Chrome を `Stop-Process -Force` で落とす。これは同ファイル L174・L246 の禁止と正面衝突している。`/sd-deploy` コマンド本体は v2.11.0 時代の手コピー表（存在しないファイル多数）で、CLAUDE.md の「手動デプロイ禁止」と矛盾。同名のスキル（deploy.ps1 経由）と二重定義になっている。
3. **圧力言語の制度化。** `claude-md-style.md` が全条件ブロックに `IMPORTANT:` を付ける書式を規約化し、CLAUDE.md に22個ある。全部が IMPORTANT だと強調は情報を失い、現行モデルでは過剰適用の原因になる。

件数（Group別）: Group 1（旧来プロンプト文）11 / Group 2（脆い設定ファイル: 陳腐化事実・矛盾・履歴）34 / Group 3（ツール記述）not applicable / Group 4（リクエスト構成）not applicable（Claude API 呼び出しコードなし）

提案 diff: `D:\claudecode\sd003\materials\text\prompt-audit-20260926.diff`（25ファイル・51 hunk、`git apply --check` 通過）

---

## 所見（確度順）

凡例: 行番号は監査時点。Action = remove / rewrite / move / add / flag。★ = diff に含む。

### High

| # | Location | Evidence | Pattern | Why obsolete | Action |
|---|---|---|---|---|---|
| H1 | `.claude/rules/specs/spec-driven.md:13,17` | `` `/spec:archive {feature}` ``／`` 検証: `/sd:spec-status` `/sd:validate-gap` `/sd:validate-spec` `` | 2 Volatile specifics | 実在は `.claude/commands/spec-archive.md`（=`/spec-archive`）。`/sd:*` は `commands/sd/` に skills-* 3つしかない。常時注入ファイル | ★rewrite / remove |
| H2 | `.claude/rules/specs/spec-versioning.md:44-46,102-103` | `` `/spec:archive` `` `` `/spec:history` `` | 2 Volatile | 同上（実在 `/spec-archive` `/spec-history`） | ★rewrite |
| H3 | `.claude/rules/skills/skill-trust-policy.md:61-63` | `` `/skills:find` `` 等 | 2 Volatile | 実在は `/sd:skills-find|add|list` | ★rewrite |
| H4 | `.claude/rules/cleanup/file-organization.md:13`、`commands/cleanup.md:187`、`commands/cleanup-restore.md:6,13-16`、`CLAUDE.md` Quick Ref | `` `/cleanup:restore` `` ／ `` `restore`, `history` `` | 2 Volatile | 実在は `/cleanup-restore` `/cleanup-history`（commands 直下） | ★rewrite |
| H5 | `.claude/rules/global/claude-md-style.md:70`、`skills/sd-deploy/SKILL.md:82`、`commands/sd-deploy.md:11` | `` `/sd:deploy` `` | 2 Volatile | `commands/sd/deploy.md` は無い。実在は `/sd-deploy` | ★rewrite |
| H6 | `.claude/rules/testing/testing-standards.md:58-62,71` | `Mode 1 (claude-in-chrome) を最優先` `Mode 2 (connect_over_cdp)` `` `/workflow:test` `` | 2 矛盾 + Volatile | gas-e2e（blame 03-10、こちらが新しい）は Mode 2=chrome-devtools-mcp 推奨・4モード。`/workflow:*` は 07-05 に撤去済（ai-coordination.md） | ★rewrite |
| H7 | `.claude/rules/global/quality-standards.md:15` | `` `.claude/rules/global/work-first.md` `` | 2 Volatile | 実在は `docs/rules-reference/global/work-first.md` | ★rewrite |
| H8 | `.claude/commands/ai-suspect.md:307-309` | `.claude/rules/troubleshooting/root-cause-first.md` 他2 | 2 Volatile | `.claude/rules/troubleshooting/` は空。実体は `docs/rules-reference/{troubleshooting,global}/` | ★rewrite |
| H9 | `.claude/commands/ai-suspect.md:263-264` | `` 全プロジェクト共通の知見なら `~/.claude/projects/*/memory/feedback-*.md` `` | 2 矛盾 | CLAUDE.md（2026-09-15裁定）: 全PJ共通→`bd remember`、auto-memory はこのPJ・Claude Code 専用 | ★rewrite |
| H10 | `.claude/commands/sessionwrite.md:128` | `` `.claude/rules/skills/learning-nudge.md` `` | 2 Volatile | 実在は `docs/rules-reference/skills/learning-nudge.md`（CLAUDE.md もこちらを指す） | ★rewrite |
| H11 | `.claude/commands/sessionwrite.md:151-157` | `Co-Authored-By: Claude Opus 4.6 (1M context)`（複数行 -m） | 1d Fossil（モデル名固定）+ 2 矛盾 | 旧モデル名の固定。帰属はセッション指示で変わる。複数行 commit は CLAUDE.md Bash Policy と不整合、push 確認も CLAUDE.md の Session Completion と不整合 | ★rewrite |
| H12 | `.claude/commands/bug-quick.md:45,306` | `Unresolved --> Bug Dialog` | 2 Volatile | "Bug Dialog" は存在しない。3段目は `/dialogue-resolution`（同ファイル L249・CLAUDE.md） | ★rewrite |
| H13 | `.claude/commands/bug-trace.md:3`、`cleanup.md:3` | `allowed-tools: … TodoWrite` | 2 矛盾 | D:\claudecode\CLAUDE.md「do NOT use TodoWrite」 | ★remove |
| H14 | `.claude/commands/bug-trace.md:28,36,49-70` | `← NEW in v2.4`、`### New in v2.0 … v2.4` | 1d/2 History narrative | モデルに要るのは現行挙動で、版ごとの変更履歴ではない（git が持つ） | ★remove |
| H15 | `.claude/commands/sd-deploy.md` 全体 | `v2.11.0`、`workflow-init.md`・`ralph-wiggum-*`・`sd/spec-init.md` 等のコピー表、`🚨 絶対禁止事項` | 2 Volatile + 矛盾 + 1a | 列挙ファイルの多くが実在しない（Phase 4 検証が常に ❌）。実版は 2.19.5・`deploy.ps1`。CLAUDE.md「展開は /sd-deploy のみ。手動デプロイ禁止」なのに手コピー手順。同名スキルと二重定義 | ★rewrite（スキルへ委譲） |
| H16 | `.claude/skills/blueprint-gate/SKILL.md:8,148` | `allowed-tools: … Write`／`` `.sd/specs/{feature}/requirements.md` に保存 `` | 2 矛盾 | `.sd/` への Write/Edit は hook が物理ブロック（sd-safe-commit.md）。Bash も無く主目的の保存が不可能 | ★rewrite |
| H17 | `.claude/skills/blueprint-gate/SKILL.md:15-20` | `Opus 4.6の出力を信頼しすぎて…` | 1d Fossil + 2 History | 旧モデル名つきの成立経緯。挙動を規定しない | ★remove |
| H18 | `.claude/skills/gas-e2e/SKILL.md:350-381` | `# Step 1: Chromeプロセスを終了 … Stop-Process -Name chrome -Force` | 2 矛盾（安全側） | 同ファイル L174・L246「AIが勝手にChromeを閉じる・再起動するのは禁止」と衝突。ユーザー作業を破壊 | ★rewrite（ユーザー確認後に実行） |
| H19 | `.claude/skills/parallel-subagents/SKILL.md:28,60` | `` `/workflow:*` ``、`` `/refactor:init` `` | 2 Volatile | どちらも存在しない | ★rewrite / remove |
| H20 | `.claude/skills/find-duplicates/SKILL.md:83-93` | `` `/refactor:init` からの連携 `` | 2 Volatile | 存在しないコマンド | ★remove |
| H21 | `.claude/skills/git-worktrees/SKILL.md:26,28,114-123` | `` `/workflow:impl` ``、`` `/refactor:batch` ``、IMPLEMENT_REQUEST 手順 | 2 Volatile | 撤去済ワークフロー | ★rewrite / remove |
| H22 | `.claude/skills/sd-upgrade/SKILL.md:131-133` | `` `<target>/.sd/cleanup/archive/<YYYYMMDD>/` へ移動 `` | 2 矛盾 | 同ファイル L47・`upgrade.ps1:355-389` は `.sd003-archive/<YYYYMMDD>/`（旧パスは肥大化で廃止と明記） | ★rewrite |
| H23 | `.claude/skills/sd-deploy/SKILL.md:195` | `` 18 | `.sd/steering/` | ツリーコピー `` | 2 Volatile | `deploy.ps1` で 2026-07-26 retired。`.sd/steering` も無い | ★remove |
| H24 | `.claude/skills/sd-deploy/README.md` L41-484（SKILL.md L284-286 が参照） | `.gemini`・`gemini.md`・`/workflow:*`・`/sd:spec-*`・「Gemini CLI: 高速実装」 | 2 Volatile | 旧手動手順の全体。SKILL.md「詳細手順は README.md を参照」で読ませている | flag（大規模削除のため diff 外。推奨: README を `_archive/` へ移し SKILL.md L284-286 を削除、トラブルシュート節だけ SKILL.md へ） |
| H25 | `.claude/skills/sd-deploy/README.md:422` | `既存デプロイ先は settings.json を上書きしない仕様のため…削除して再deploy` | 2 矛盾 | `deploy.ps1:866` は `.sd003-keep` 無しなら上書き。SKILL.md L174 は保護解除を禁止 | flag（H24 と一緒に処理） |

### Medium

| # | Location | Evidence | Pattern | Why obsolete | Action |
|---|---|---|---|---|---|
| M1 | `CLAUDE.md` Conditional Context 全行（22箇所）＋ `.claude/rules/global/claude-md-style.md:12,28-29,42,47-55` | `IMPORTANT: …` を全ブロックに付与する規約 | 1a Pressure language | 全部に付くと強調は情報を失い、現行モデルでは過剰適用・硬直を招く。条件（When…）が既にルーティングを担っている | ★rewrite（接頭辞を外し、規約に「強調は実測で守られなかった1ルールに理由付きで」） |
| M2 | `.claude/rules/global/quality-standards.md:24-25` | `カバレッジ80%以上` `ユニット/統合/E2E全層` | 2 矛盾 | CLAUDE.md 柱3「カバレッジ目標…禁止」、同ファイル L42-43 とも衝突（blame: 03-08、CLAUDE.md 側が新） | ★remove |
| M3 | `.claude/rules/workflow/ai-coordination.md:9-17` | `> **2026-07-05 変更**: 旧「7段階ワークフロー」…` `> **2026-07-12 変更**…` | 1d Migration-relative + 2 History | 現行ルールを差分として語っている。モデルは旧版を知らない | ★rewrite（現在形3行） |
| M4 | `.claude/commands/bug-trace.md:82-95`（+ L249/434/496/536 の「必ず」） | `MANDATORY OUTPUT REQUIREMENTS / The following outputs are REQUIRED. DO NOT skip or omit them.` | 1a | 理由なし大文字強調＋チェックボックス儀式。理由（ユーザーは解説を読む）を1行で言えば足りる | ★rewrite（L249 以降の重複「必ず」は未編集・任意） |
| M5 | `.claude/commands/ai-suspect.md:283-301` | `参考: 模範5Why（at002 2026-06-13 — このレベルと構造を目指す）` | 1c 単一ゴールド例 + 2 History | 単一の模範例は長さ・領域（弥生CSV）ごと模倣される。Step 4 に表テンプレートがある | ★remove |
| M6 | `.claude/commands/cleanup.md:198-210` | `タイムアウト 処理全体: 5分 / AI判断: 60秒`、`CLEANUP_SCAN_COMPLETE` 等マーカー表 | 1f Output choreography / Unenforced | 何も強制・解析していない（マーカーを読むコードは無い） | ★remove |
| M7 | `.claude/commands/dialogue-resolution.md:15-17,50,65,97,127` | `⛔ 禁止事項（最重要）/ 絶対に行ってはならない`、`ユーザーの回答があるまで絶対に次に進まない。`×3 | 1a | 各Step後の停止は正当な要件（CLAUDE.md も要求）だが、1回理由付きで言えば足りる | rewrite 推奨（diff 外。案:「各Step後は AskUserQuestion で止まり回答を待つ（この手法の核心は人間の照合）」を冒頭1回） |
| M8 | `.claude/skills/sd-upgrade/SKILL.md:95,108,113` | `dry-run が正直になった（誤報の根絶）`、`もはや "UPGRADE OK / 全部無傷" とは誤報しない` | 1d Migration-relative | 旧版との差分表現 | ★rewrite |
| M9 | `.claude/skills/codex-dispatch/SKILL.md:11-16` | `⚠️ 2026-05-26 事故対策（必読・二度と同じ間違いをしないため）… 全失敗の原因` | 2 History + 1a | 規則（stdout/stderr 分離・effort 明示）は下の正準コマンドで既に述べている。理由だけ残して現在形に | ★rewrite |
| M10 | `.claude/skills/grok-dispatch/SKILL.md:103-109` | 改訂履歴表（`-m grok-build`） | 1d Fossil + 2 History | L54「grok-build は死亡」と矛盾する旧 invocation を載せている | ★remove |
| M11 | `.claude/skills/gas-e2e/SKILL.md:185` | `（現環境: 145 ✅）` | 2 Volatile | スナップショット値 | ★rewrite |
| M12 | `.claude/skills/blueprint-gate/SKILL.md:173` | `保存先はあみおに確認する。` | 2 矛盾 | L148-149 が保存先を固定済み | ★remove |
| M13 | `.claude/skills/git-worktrees/SKILL.md` 冒頭 | （worktree=ブランチ作成の旨なし） | 2 矛盾（add） | CLAUDE.md Solo運用「ブランチ作成はユーザー指示時のみ」 | ★add（1行） |
| M14 | `.claude/skills/gas-e2e/SKILL.md:78-99 vs 470-491`、`168,239` 他 | 同じフローチャート2つに「AIは必ずこれに従う」、`🚨 もたつき防止ルール（AIは厳守）` `★★★` | 1a + 重複の不一致（L197/L505 のインストール行で `-y` の有無が違う） | 理由は表に既にある | rewrite 推奨（diff 外。1つに統合し装飾を外す） |
| M15 | `.claude/skills/gas-e2e/SKILL.md:305-306` | `Step 1: take_snapshot … Step 2: navigate_page` | 2 手順の誤り | 遷移前にスナップショットを取っている | rewrite 推奨（diff 外。順序入替） |
| M16 | `.claude/skills/grillme/SKILL.md:42-51` | 名前の由来・却下された名前候補 | 2 History | 挙動に無関係 | remove 推奨（diff 外） |
| M17 | `.claude/skills/notebooklm-research/SKILL.md:44-49,184,201` | 「GitHubチェック必須」×3、コマンドなし | 1a 反復 | 実行手段がない強調 | rewrite 推奨（diff 外。1回＋ `gh release list -R teng-lin/notebooklm-py -L 1` 等の実コマンド） |
| M18 | `.claude/skills/html-report/SKILL.md:50` | `{{SECTION_1_CONTENT}} ~ {{SECTION_6}}` | 2 Volatile | テンプレ実物は `SECTION_2_1`〜`5_2` 等。`SECTION_6` 無し、Known Unknowns 節の枠も無い | rewrite 推奨（diff 外。実プレースホルダ列挙） |
| M19 | `.claude/skills/sd-deploy/SKILL.md:163-172` | 検証 C1–C6 の表（L294 は C8 に言及） | 2 Volatile | スクリプトは C1–C8 | add 推奨（diff 外） |
| M20 | `.claude/commands/sessionwrite.md:157` | `post-commit hookが非同期pushを自動実行。` | 2 矛盾 | CLAUDE.md は pull --rebase・push・up to date 確認を要求 | ★rewrite（H11 と同 hunk） |

### Flag（編集提案なし）

| # | Location | 内容 | 理由 |
|---|---|---|---|
| F1 | `.handoff/RULES.md:99-105` vs `:142` / CLAUDE.md 柱4 | 「勝手に判断して進めないで…選択肢を提示しユーザーに委ねて」vs「毎ステップでブロックする」禁止 | blame: 99-105 は 02-11、142 は 04-12。古い側が禁止文、新しい側が禁止を緩める向きなので規約上 flag。ユーザー判断: 99-105 を柱4 に合わせて「結果を左右する判断だけ末端で1回確認」に書き換えるか |
| F2 | `.handoff/RULES.md:126` vs `:128,141` / 柱3 | 「テストを書かずに実装のみを完了とする」禁止 vs「テストのためのテスト禁止」 | 同上（古い側が禁止文）。削除か「本番バグ再現時はテストで固定」への書換えかはユーザー判断 |
| F3 | `.claude/commands/bug-trace.md:75-76` | 「Skip user confirmation at any step」禁止、AskUserQuestion ゲート約8か所 | 柱4「毎ステップ確認も禁止」と緊張。例外は /dialogue-resolution のみ。修正前（Step 6→7）と分類のゲートは残し他を統合するか要判断 |
| F4 | `.claude/commands/cleanup.md:139-148` | `ARCHIVE_DIR=".sd/cleanup/archive/…"` → `mv` | `scripts/orchestrator-guard.js` が `.sd/` を含む mv をブロック（変数で隠れているだけ）。cp+元削除 or ガード例外を決めて明記 |
| F5 | `.claude/templates/workflow/{IMPLEMENT_REQUEST,REVIEW_REPORT,TEST_REPORT}.md` | 撤去済ワークフローのテンプレ。指示ファイルからの参照ゼロ、強調語21個 | 自動ロードされないので害は小。アーカイブ候補 |
| F6 | `CLAUDE.md` Bash Tool Policy | 「監視対象バグ: #15599, #24956, #11225, #34330」 | 検証日なしの外部 issue 番号。auto-memory では #34330 説は誤診の可能性大とされる（プロジェクト外情報なので flag のみ） |
| F7 | `.claude/commands/sessionwrite.md:3 vs 161` | allowed-tools に Edit が無いのに「Write/Edit で更新」 | Low |
| F8 | `.claude/skills/gas-e2e/SKILL.md:10` | `mcp__claude-in-chrome__screenshot`（存在しないツール） | Low |
| F9 | `.claude/commands/session-search.md:19 vs 40` | 並び順・件数の記述が食い違う（head_limit 50 と上位10件） | Low |
| F10 | `.claude/commands/bug-trace.md:216`、`parallel-subagents/SKILL.md:22,88` | 「公式 Prompting Claude Opus 5 準拠」等の作者向け注記 | Low・モデル名つき出典。ルールだけ残せばよい |
| F11 | `jobs-review/SKILL.md:61-77`、`find-duplicates/SKILL.md:50-81`、`html-report/SKILL.md:53-59`、`blueprint-gate/SKILL.md:58` | 判断タスクの固定手順・一般知識の説明 | Low（1c）。挙動を見てから削る |

### クリーンだったファイル

bug-quick（H12 以外）、sessionread、sessionhistory、ai-usage、agy-dispatch、dialogue-trigger、excel-com-required、bugyou-yayoi-conversion、codex-security、web-design-principles（Opus 5.5 のフロントエンド既定スタイル列挙は正しい形。維持）、skill-check-before-action（事故由来の理由つき。維持）

---

## 適用時の注意

- `.claude/commands/**` は `scripts/sync-cli-commands.py` の生成元（AGENTS.md）。適用後に再生成しないと `.agents/`・`.grok/` 側に旧文面が残る。
- `sd-deploy`・`sd-upgrade` 系の変更は配布物に入る。次の `/sd-deploy` / `/sd-upgrade` で各PJへ伝播する。
- 検証: 適用後、削除したコマンド名（`/spec:archive`、`/workflow:`、`/refactor:`、`/sd:deploy`、`/cleanup:restore`、`Bug Dialog`）を `git grep` し、`_archive`・`.sessions`・生成物以外に残っていないことを確認する。
