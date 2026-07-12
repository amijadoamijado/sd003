# IMPLEMENT_REQUEST: 4AI Lead/Assist 設定の強化（16改善の実装）

- **案件ID**: 20260712-4ai-lead-hardening
- **日付**: 2026-07-12
- **依頼者**: Claude Code（Session Lead）
- **実装者**: Codex（Generator）
- **後続**: 実装完了後、Grokによる独立検証（Quiz Gate委譲の適用第1号: Codex=GeneratorのためEvaluator=Grok）→ Lead がゲート実行・コミット

## 1. 背景

SD003は4AI CLI（Claude Code / Codex / Antigravity=agy / Grok）を「ユーザーが開いた入口CLI = Session Lead（主役）・他はAssist（相談役）」として相互運用する体制を2026-07-12に正式化した。多角レビュー（6観点並列→事実性×実益性の2レンズ敵対検証、検証通過30 findings）の結果、以下の3系統の問題が確定した:

1. **実行系の物理的な穴（実測済み）**: bypassPermissions隔離ガード不在・dirty判定no-op・exit 0の沈黙偽成功（PermissionCancelled）
2. **旧世界残骸**: 2026-07-05のceremony撤去（7段階ワークフロー廃止）と2026-07-12のLead流動化が正本（ai-coordination.md）にしか反映されておらず、非Claude Leadが最初に読む一次文書（.handoff/RULES.md・AGENTS.md・antigravity.md・CODEX_GUIDE.md）と配布系（deployテンプレ・upgrade purgeリスト）が旧7段階ワークフローのまま
3. **Lead装備の非対称**: GROK_NATIVE.mdにあるLead装備がCODEX_NATIVE.md/agyに欠落、repo lockは宣言のみで実体なし

本依頼書はこの是正16件の実装依頼である。**改善の方向は「簡素化・欠落補完・物理ガードレール」のみ。儀式（フォーム・多段承認・重い書面）の追加は一切禁止。**

## 2. ゴール（ユーザーが受け取るもの）

- 全16改善が実装され、`npm run build && npm test && npm run lint` が全通過している状態のワーキングツリー
- 新規回帰テスト（WP1の2本）がPASSする実行ログ
- 実装報告書 `.sd/ai-coordination/workflow/review/20260712-4ai-lead-hardening/IMPLEMENTATION_REPORT.md`（WPチェックリスト・変更ファイル一覧・ゲート実行結果・逸脱事項）

内部の型・構造の美しさは完了指標ではない（柱2）。動くガードと正しい文書が成果物である。

## 3. 遵守ルール（違反したら差し戻し）

| # | ルール |
|---|--------|
| R1 | **git commit / push / branch作成 / PR作成をしない**。変更はワーキングツリーに残す（コミットはLeadが論理単位で実施） |
| R2 | **git checkout / restore / reset / stash / clean 等の破壊操作をしない** |
| R3 | **rm禁止**。退役させる内容はファイル削除でなく `.sd/cleanup/archive/20260712-4ai-lead-hardening/` へ移動（cp後に上書き） |
| R4 | ceremony追加禁止。新しい必須手順・フォーム・承認段階を作らない |
| R5 | `design.md` という名の仕様ファイルを作らない（spec.md統一・Antigravityが予約） |
| R6 | `.sd/ai-coordination/workflow/templates/` の[ARCHIVED]notice 6件は**触らない**（廃止notice化済み・現状維持） |
| R7 | TypeScriptはstrict・`any`禁止（`unknown`+型ガード）。既存コードのスタイル・コメント密度に合わせる |
| R8 | テストは実挙動の回帰テストのみ。空データ/自明アサーション/フォールバック付きテスト（VTD-001〜005）禁止 |
| R9 | 既存ファイルの改行コード・エンコーディングを維持（.gitattributes準拠。シェルスクリプトはLF） |
| R10 | agyの権限フラグ正準は `--sandbox --mode accept-edits`（providers.jsonでE2E実証済みの側）に統一 |
| R11 | 不明点・矛盾を発見したら勝手に解釈を広げず、報告書の「逸脱・発見事項」に記録して保守的に倒す |

## 4. 実装スコープ（Work Package順に実施。各WP完了ごとに build/test/lint を回す）

---

### WP1 = 改善#1 [P0] オーケストレーター実行系の物理ガード強化

対象: `src/orchestrator/runner.ts`, `src/orchestrator/types.ts`, `docs/orchestrator-contract.md`, `tests/integration/orchestrator-e2e.test.ts`, `config/orchestrator.providers.json`

1. **bypassPermissionsプリフライト**: `runScenario` 冒頭に追加。展開後のprovider argsに `bypassPermissions` または `--dangerously-skip-permissions` を含むstageがある場合、resolve済みworkspaceが本repoルート/配下または共有worktree（`path.resolve`比較＋`git -C <ws> rev-parse --git-common-dir`で判定）なら、scenarioが `unattendedWorkspaceAck: true` を明示しない限りthrowで拒否する。
2. **dirty判定の修正**: `isDirtyGitWorkspace` の `fs.existsSync(path.join(workspace,'.git'))` 判定を `git -C <ws> rev-parse --is-inside-work-tree` に置換（gitコマンド失敗時のみ「repoでない」扱い）。dirty判定は `git -C <ws> status --porcelain -- .`（workspace配下スコープ）にする。gitignoredの test-results/ 配下は空出力で従来どおり通ること。
3. **沈黙失敗検出の一般化**: `hasProviderCancellation` の検査対象をstdout+stderr連結に変更。`ProviderDefinition` に `cancellationPatterns?: string[]` を追加（未指定時の既定=現行Grok regex）。claude/agyの実測マーカーは未確定のため、契約文書に「claude/agyをstageに使うscenarioはper-stage expectedArtifacts必須（実測登録まで）」と明記する。
4. **stage単位artifact検査**: `StageDefinition` に任意 `expectedArtifacts?: string[]` を追加。stage成功直後にresolveInside＋existsSync検査し、欠落なら該当stageをfailedにして即中断（run末尾の一括検査は互換のため残す）。
5. **dead config除去と契約修正**: `types.ts` の未実装 `required?: boolean` を削除。契約の "every required stage succeeds" 文言を実装どおり全stage必須に修正。契約に「orchestratorフィールドは説明責任ラベルであり、実行主体は決定論runner」の1段落と、置換変数一覧への `${role}` 追記。
6. **回帰テスト2本**: 「repoルート直指定＋bypassPermissionsで拒否される」「実repoサブディレクトリがdirtyのとき拒否される」。既存テストの流儀（fixture provider方式）に合わせる。

受け入れ基準: 新テスト2本PASS・既存84テスト回帰なし・`npm run orchestrate:dry-run -- config/orchestrator.codex-e2e.json` が従来どおり成功。

---

### WP2 = 改善#2 [P0] dispatchラッパーのfail-loud統一

対象: `.claude/skills/grok-dispatch/grok-run.ps1`, `.claude/skills/grok-dispatch/SKILL.md`, `.claude/skills/codex-dispatch/codex-run.sh`, `.claude/skills/codex-dispatch/SKILL.md`

1. grok-run.ps1: 実行引数に `--permission-mode bypassPermissions` を明示追加（providers.jsonと正準統一。config.tomlのalways-approve前提を除去）。
2. grok-run.ps1: verify節に runner.ts と同一のregex（`cancellationCategory["\:=\s]+PermissionCancelled` 相当・大文字小文字無視）でstderr（progressファイル）を検査し、検出時はrc=0でもFAIL（exit 1）。
3. grok-run.ps1: `-PromptFile <path>` パラメータを追加（指定時はtemp化をスキップし `--prompt-file` へ直渡し。`-Prompt` との排他）。
4. codex-run.sh: verifyを `[ "$RC" -eq 0 ] && [ -s "$OUT" ]` に変更。rc≠0はprogress tail表示＋exit 1。
5. codex-run.sh: 第4引数（プロンプト）が実在ファイルパスならスクリプト内で `PROMPT="$(cat "$4")"` を行う（コマンドラインを通るのは短いパスのみ）。
6. codex SKILL.md: `codex exec "$(cat …)"` 型の正準例を撤去し「長文プロンプトはWriteでファイル作成→パス渡し」に更新。
7. grok SKILL.md: 「効いた設定」表に bypassPermissions必須（2026-07-12 E2E実測）と隔離workspace注意を追記。

受け入れ基準: 両ラッパーが「rc≠0」「PermissionCancelledマーカー検出（grok側）」で確実にexit 1になること（ダミー入力での手元確認結果を報告書に記載）。

---

### WP3 = 改善#3,4,5,15 [P1/P2] 入口・共通文書の現行化

**#3 `.handoff/` 引き継ぎパック** — 対象: `.handoff/RULES.md`, `.handoff/ORDER.md`, `.handoff/ORDER.template.md`

1. RULES.md: 「AI協調ワークフロー」表（WORK_ORDER/IMPLEMENT_REQUEST_{NNN}等の旧7段階文書体系）を現行形へ差し替え — 依頼書=`.sd/ai-coordination/workflow/spec/{案件ID}/`（自由形式）・報告書=`review/{案件ID}/`・正本=`.claude/rules/workflow/ai-coordination.md`。
2. RULES.md: 「テンプレートなしの依頼書作成」を禁じる行を削除。
3. RULES.md: `.sd/`コミットの旧絶対ルール行（同一bash内add+commit必須）を正本 `sd-safe-commit.md` 現行形へ差し替え: 「.sd/変更後は早めにcommit（同一bashが最も安全）。未commitの.sd/変更はwipe時にL4で復元されない」。
4. RULES.md: バージョン行を更新し、末尾付近の混入文字「c」を除去。`.handoff/`説明行に「ORDER.mdはアクティブ指示があるときのみ実体を持つ」1文を追記。
5. ORDER.md: 完了済み2026-02計画の本文を `.sd/cleanup/archive/20260712-4ai-lead-hardening/ORDER-20260215.md` へcp保存した上で、本体を「アクティブな指示なし。新規タスクはORDER.template.mdをコピーして記入、完了後DONE.md出力→本noticeへ戻す」の3行プレースホルダに置換。
6. ORDER.template.md: 参照例の `.sd/specs/xxx/design.md` を `spec.md` へ1語修正。

**#4 AGENTS.md（Codex入口）** — 対象: `AGENTS.md`

7. 「### Specification」ブロックの `$workflow-init`〜`$workflow-test` 7行を削除。Utility節から `$refactor-plan` のみ削除（実在するコマンドは残す）。
8. Templates参照行を「AI協調の依頼・報告: `.claude/rules/workflow/ai-coordination.md`（正式時のみ `spec/{案件ID}/` 自由形式）」へ置換。
9. `.sd/`同一bash行を正本現行形へ同期（上記3と同文）。
10. 掲載コマンド一覧を現存の `.codex/skills/` 実体（22件）と突合し完全一致させる。

**#5 antigravity.md（agy入口）** — 対象: `antigravity.md`

11. Templates節とReferenceのTemplates行を削除（参照先は全て[ARCHIVED]notice）。
12. Trigger/Role表の「Read IMPLEMENT_REQUEST, execute」「Read TEST_REQUEST, execute」を現行形へ: アドホック=プロンプト直接渡し（WP4のagy-dispatch経由）、正式=`spec/{案件ID}/`配下の自由形式依頼文書。
13. Pipeline Flow図の「/workflow:request→IMPLEMENT_REQUEST作成」起点を「依頼プロンプト（会話内 or spec/{案件ID}/）または `scripts/orchestrate.js`（2026-07-12実E2E実証済み経路）」へ差し替え。
14. agent-implement.sh導線に廃止注記を付ける（第3の並行入口化を防ぐ）。
15. `.sd/`同一bash行を正本現行形へ同期。
16. 権限フラグの正準を `--sandbox --mode accept-edits` と明記し、`--dangerously-skip-permissions` 記載を置換。

**#15 CLAUDE.md本体** — 対象: `CLAUDE.md`

17. `.sd/`コミットのIMPORTANTブロック（「MUST complete git add + commit in the SAME bash command…」）を正本現行形へ差し替え: 「.sd/変更後は早めにcommit（同一bashが最も安全）。未commitの.sd/変更はwipe時にL4で復元されない。真因はspec-workflow.test.tsの隔離で修正済み（f5f6648）」相当の1-2行。

受け入れ基準: 上記4ファイルに旧7段階ワークフロー語彙（WORK_ORDER必須・IMPLEMENT_REQUEST_{NNN}固定命名・$workflow-*・/workflow:*）が生きた指示として残っていないこと（grepで確認し報告書に記載）。

---

### WP4 = 改善#6 [P1] agy-dispatch正準ラッパーの新設

対象: `.claude/skills/agy-dispatch/SKILL.md`（新規）, `.claude/skills/agy-dispatch/agy-run.ps1`（新規）

grok-run.ps1をミラーして作成:
1. プリフライト: `Get-Process agy,antigravity` による二重起動チェック＋認証状態の疎通確認（antigravity.mdのハング原因2系統=排他ロック競合・認証待ち、の対策をコード化）。
2. 権限フラグ: `--sandbox --mode accept-edits` に統一。
3. stdout→out.md / stderr→progress.log の分離。
4. 成功判定: rc==0 ＋ 呼び出し時に宣言された期待成果物のディスク実在検証（`-ExpectedArtifact <path>` 任意パラメータ。agy自己報告を信用しない教訓の機械化）。
5. タイムアウト付き実行（既定10分・パラメータで変更可）。タイムアウト時はプロセスkill＋exit 1。
6. SKILL.md: 使用例・brain/迷子時の `bash scripts/recover-agy-artifacts.sh` 回収手順リンク・grok-dispatch/codex-dispatchとの使い分け1行。

受け入れ基準: `pwsh -File agy-run.ps1` がパラメータ検証・プリフライト・タイムアウトを正しく通ること（agy実呼び出しはLead側で後続実測するため、構文・分岐の静的確認＋可能な範囲の手元確認でよい）。

---

### WP5 = 改善#13 [P1] repo lockの実体化

対象: `scripts/lead-lock.ps1`（新規）, `.claude/rules/workflow/ai-coordination.md`, `.claude/skills/grok-dispatch/grok-run.ps1`, `.claude/skills/codex-dispatch/codex-run.sh`, `.grok/GROK_NATIVE.md`, `.codex/CODEX_NATIVE.md`

1. `scripts/lead-lock.ps1 acquire|release|status <ai名>` を新設。lockファイルは `.git/sd-lead.lock`（.git/配下はランタイムworking-tree refreshの対象外）に `{ai, pid, startedAt}` のJSON1行。acquire時に既存lockのpidが死んでいればstale扱いで自動奪取（fail-open・人手介入不要）。
2. grok-run.ps1 / codex-run.sh のプリフライトに「lock保持者が呼び出し元以外なら実行拒否（exit 1・保持者情報表示）」を追加。既存のGet-Process確認対象に `claude` も追加。WP4のagy-run.ps1にも同じプリフライトを入れる。
3. GROK_NATIVE.md / CODEX_NATIVE.md のセッション開始項の「他AIが編集中でないか注意する」を `pwsh -File scripts/lead-lock.ps1 acquire <ai>` の具体1行に置換（CODEX_NATIVE.mdへの追記はWP6の同ファイル編集とまとめてよい）。
4. ai-coordination.md の「Lead が repo lock を持つ」を実体（`.git/sd-lead.lock`・lead-lock.ps1）への参照に更新。

受け入れ基準: acquire→status→release→stale奪取の4動作を手元実行で確認し結果を報告書へ。lockファイルがgit statusに現れないこと（.git/配下のため）。

---

### WP6 = 改善#7,8,9,10 [P1] Lead装備パリティ＋記憶・検証ループ

**#7 CODEX_NATIVE.md Lead mode節** — 対象: `.codex/CODEX_NATIVE.md`

1. GROK_NATIVE.mdのLead装備（セッション開始チェック〜handoff表）をミラーした「Lead mode」節を20-30行で追加: ユーザー直接起動=Codex Lead／開始時に git status＋`.sessions/session-current.md`＋`TIMELINE.md` を読む（既存Handoff Recovery手順を再利用し、発動条件を「Claude停止時」から「Lead開始時も」へ拡張）／完了定義=柱1（ユーザーが開ける成果物が存在し検証済み）／handoff表（E2E→agy・入口復帰→Claude・独立検証→Grok・Quiz Gate該当時はCodex以外へ出題委譲）／経過メモは `.sd/ai-coordination/sessions/codex/`（ディレクトリが無ければ README.md 1行付きで新設）。
2. 終了手順に「セッション終了時（または大きな区切り）に `.codex/skills/sessionwrite` を実行し session-current.md / TIMELINE.md を更新する」1行追加。
3. 「IMPLEMENT_REQUEST_{番号}.md」固定命名を「`spec/{案件ID}/` 配下の依頼文書（自由形式）」へ緩和。
4. handoff-log文言を統一形「任意（AI間handoff発生時に1行推奨）」へ。

**#8 ai-coordination.md＋周辺** — 対象: `.claude/rules/workflow/ai-coordination.md`, `.sd/ai-coordination/workflow/README.md`, `.sd/ai-coordination/workflow/GROK_GUIDE.md`

5. agy Lead行に「暫定: Lead正本未整備。長時間セッションはClaude/Grokへのhandoff推奨」と注記（Lead節の増設はしない）。
6. Lead切替の明示トリガー節の直後に2行追加: 「切替前に元Leadは (a) WIPをcommitして渡す、または (b) 未コミットパス一覧と所有権移転を宣言する。宣言があれば新Leadは当該パスを編集してよい（GROK_NATIVE原則『未コミット変更に触るな』の明示的例外）」。
7. 保存ルール表のhandoff-log行に義務レベル「任意（AI間handoff発生時に1行推奨）」を明記。workflow/README.mdの「記録必須」とGROK_GUIDE.mdの「可能なら」を同一文言へ統一。
8. 実務リンク節にagy-dispatch（WP4）を1行追加。

**#9 記憶・検証ループ** — 対象: `.grok/GROK_NATIVE.md`, `.claude/rules/global/quiz-gate.md`, `.claude/commands/sessionread.md`

9. GROK_NATIVE.md「Lead Session」末尾に「終了時（または大きな区切り）に生成済み `.grok/skills/sessionwrite` を実行して session-current.md / TIMELINE.md を更新する」1行追加。
10. GROK_NATIVE.mdのhandoff表に「Quiz Gate該当（Blueprint級実装の完了主張）時は既存のCodex handoff導線で出題を依頼」1行追加。
11. quiz-gate.mdに2行追記: 「CodexがGeneratorの場合のEvaluatorはGrok（独立検証ドメインの所有者）に振る」「非Claude Leadでは/codex:review（Claude専用プラグイン）の代わりに各Leadの既存Codex handoff導線（会話またはreview/依頼）で出題を依頼する」。fail-open・非ブロッキング・Blueprint級限定は不変。
12. sessionread.mdに1ステップ追加: 「`.handoff/DONE.md` が `.sessions/session-current.md` より新しい場合は併読し、差分をユーザーに通知する」。

**#10 CODEX_GUIDE.md全面書き直し** — 対象: `.sd/ai-coordination/workflow/CODEX_GUIDE.md`

13. GROK_GUIDE.mdを雛形に全文書き直し: 役割=公式品質印（アドホックFast Reviewは`.codex/CODEX_NATIVE.md`参照）／呼び出し=Claude Lead時は`/codex:review`プラグイン・Codex Lead時は直接／正式レビュー時のみ `review/{案件ID}/` に自由形式で保存（「templates/REVIEW_REPORT.mdを必ず使用」「Phase 2/Phase 5担当」「/workflow:review起動」を全廃）／Output Primacy配点表（UI/アウトプット60・機能動作30・内部品質10）は維持。旧全文は `.sd/cleanup/archive/20260712-4ai-lead-hardening/CODEX_GUIDE-old.md` へcp保存してから上書き。

受け入れ基準: CODEX_NATIVE/GROK_NATIVE/ai-coordination/README/GROK_GUIDE/CODEX_GUIDE間で、handoff-log義務レベル・依頼書配置・Lead判定の記述が完全一致していること。

---

### WP7 = 改善#11(準備),12,14(準備),16 [P1/P2] 配布系同期＋E2E保全＋実測準備

**#12 deploy/upgrade配布系の4AI時代同期** — 対象: `.claude/skills/sd-deploy/templates/CLAUDE.md.template`, `.claude/skills/sd-deploy/deploy.ps1`, `.claude/skills/sd-deploy/SKILL.md`, `.claude/skills/sd-upgrade/upgrade.ps1`, `scripts/verify-deployment.mjs`

1. CLAUDE.md.templateへ本体CLAUDE.mdの4AIブロックを同期: Overviewの「AI協調: Session Lead=入口CLI + …」行、Grok two-modes（Lead/Assist）IMPORTANTブロック、artifact-output-location IMPORTANTブロック、ai-coordinationブロックへのLead判定言及。テンプレのプレースホルダ規約（{{PROJECT_NAME}}等）は既存流儀を維持。
2. verify-deployment.mjsのコンテンツ検証に「配布先CLAUDE.mdにGrok Lead modeトークン（例: `Lead mode`）が存在する」チェックを1件追加（既存C1-C6の流儀に合わせてC7等として）。
3. upgrade.ps1の `$overengCmdNames` へ `workflow-init` `workflow-order` `workflow-request` `workflow-review` `workflow-status` `workflow-test` の6件を追加。`$overengExtra` へ `.claude/hooks/sd003-stop-hook*.sh/.ps1`（endgame含む・実ファイル名を確認して列挙）と `scripts/deploy-ralph-wiggum.sh` を追加。
4. deploy.ps1の単ファイルコピー節へ `scripts/recover-agy-artifacts.sh` を追加（`.ps1`版が実在すれば同様に追加。存在しなければ.shのみで、その旨を報告書へ）。dry-runのスキャン対象リストにも同様に追加。
5. sd-deploy SKILL.mdの動的コピー対象表から `.sd/ralph/` と `.sd/refactor/config.json` の幻エントリ2行を削除。

**#14 実E2Eシナリオのgit保全（準備）** — 対象: `config/orchestrator.real-e2e.json`（新規）

6. `test-results/orchestrator-real-e2e/scenario.json`（成功run 20260712T014328959Zの入力）を `config/orchestrator.real-e2e.json` としてコピー配置。機微情報（トークン・実在顧客名・個人情報）が含まれないことを確認し報告書に明記。WP1で導入した `unattendedWorkspaceAck` 等の新契約に適合するよう必要最小の調整を行う。**agy実測（担当入れ替えrun）は実施しない**（Lead側で後続実施）。
7. docs/orchestrator-contract.md の置換変数一覧に `${role}` を追記（WP1-5と重複するなら1回でよい）。

**#11 Grok Lead実測（準備のみ）** — 対象: `.sd/ai-coordination/workflow/spec/20260712-4ai-lead-hardening/GROK_LEAD_TEST_PLAN.md`（新規）

8. 実測手順書を作成: 隔離worktreeでGrok TUIをrepo直下起動→(a) grok.mdが自動読込されているか冒頭質問で確認、(b) GROK_NATIVE.mdのセッション開始チェック遵守確認、(c) 結果のTIMELINE 1行記録、(d) 自動読込されない場合の是正（GROK_GUIDE「Lead modeの始め方」へ「起動後まずgrok.mdを読ませる」1行追記）。**実測自体は実施しない**（ユーザー参加が必要）。

**#16 setup-guide簡素化** — 対象: `docs/sd003-setup-guide.md`

9. 手動導入節（`cp -r {sd003}/.gemini ./` 等）を削除し「/sd-deploy（deploy.ps1）が唯一の導入経路。手動deployは禁止」の1行に簡素化。冒頭の自動展開一覧から `.antigravity/` を除去、保護対象表から `gemini.md` を除去。残存するRalph Loop・context-autonomy・workflow-*等の撤去済み機能への参照も除去。

受け入れ基準: `node scripts/verify-deployment.mjs` の自己整合（既存テストがあれば通過）。upgrade.ps1/deploy.ps1は構文チェック（`pwsh -NoProfile -Command "Get-Command -Syntax"` 相当またはparse確認）を通ること。

---

## 5. 検証（全WP完了後に必ず実行し、出力要約を報告書へ）

```bash
npm run build
npm test          # 既存84 + 新規2 = 86テスト想定
npm run lint
node scripts/check-orchestrator-providers.js
npm run orchestrate:dry-run -- config/orchestrator.codex-e2e.json
```

## 6. 報告書

`.sd/ai-coordination/workflow/review/20260712-4ai-lead-hardening/IMPLEMENTATION_REPORT.md` に以下を記載:

- WP1〜WP7のチェックリスト（項目単位の完了/未完了/逸脱）
- 変更・新規・アーカイブ移動ファイルの全一覧
- 検証コマンドの実行結果要約（PASS/FAIL・件数）
- 逸脱・発見事項（R11）: 依頼書の前提と実ファイルが食い違っていた箇所、保守的に倒した判断
- 未実施事項の明示: コミット（R1）、Grok Lead実測（#11）、agy実測（#14後半）

最終stdoutにも同内容の要約を出すこと。

## 7. 除外事項（本依頼の対象外・Lead側で後続実施）

- git commit / push（Lead実施）
- Grok Lead modeの実機実測（#11、ユーザー参加）
- agyの非対話挙動実測と cancellationPatterns 登録（#14後半）
- Grokによる独立検証（実装完了後にLeadがディスパッチ）
