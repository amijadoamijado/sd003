Quiz Gateに基づき、読み取り専用で敵対的検証を開始します。依頼書・報告書・関連ルールと実装diffを並行で確認します。重点箇所の実装を読み取り、敵対的に突きます。ガード・正規表現・受け入れ基準の実装細部を精査します。Windowsのパス大文字小文字でガードすり抜けを確認済み。正規表現と他の受け入れ基準も続けて検証します。# Quiz Gate 独立検証報告（Evaluator = Grok）

対象: `906b488..fb744d4` / 依頼書 WP1〜WP7  
方法: 依頼書・報告書を読んだうえで **diff と実行時プローブ** で受け入れを再検証（報告書は証拠に使っていない）

---

## 1. WP別判定表

| WP | 判定 | 根拠 |
|----|------|------|
| **WP1** | **PARTIAL** | dirty は `rev-parse --is-inside-work-tree` + `status --porcelain -- .` に置換済み（`runner.ts:39-44`）。test-results 配下 workspace の dry-run は dirty で落ちないことを実行確認。cancellation は stdout+stderr・既定 regex で json/colonspace/equals を実行時検出。stage `expectedArtifacts` あり（`runner.ts:108-110`）。新テスト2本あり（`orchestrator-e2e.test.ts:131-148`）。**ただし `isRepositoryWorkspace` が Windows で大文字小文字非正規化のため、`d:\...` 指定で bypassPermissions ガードをすり抜け可能（後述 P0）**。`runner.ts:59-64,87-90` |
| **WP2** | **PASS** | `codex-run.sh:41-48` は `RC==0 && -s OUT` のみ OK。`grok-run.ps1:90-98` は PermissionCancelled・rc≠0・空出力で exit 1。`--permission-mode bypassPermissions`・`-PromptFile`・`--ignore-user-config` 撤去・stdin `</dev/null`・medium 固定を確認。正常系条件は狭く、成功を誤 FAIL する分岐は見当たらない。※依頼の「ダミー手元確認」は報告書どおり未実施（R11記載） |
| **WP3** | **PASS** | `RULES.md` 依頼/報告を自由形式へ、旧 safe-commit を現行形へ、ORDER を notice 化、`ORDER.template` の `spec.md` 修正、AGENTS から `$workflow-*` 削除・skills 22件と実体一致、antigravity の 7段階起点撤去・権限フラグ統一、CLAUDE.md safe-commit 2箇所同期。入口に生きた 7段階起動指示なし（禁止/歴史説明のみ） |
| **WP4** | **PARTIAL** | `agy-run.ps1` に二重起動・認証 probe・`--sandbox --mode accept-edits`・stdout/stderr 分離・timeout・ExpectedArtifact・空出力 FAIL あり。SKILL も最小だが用途は記載。**ExpectedArtifact の `StartsWith($root)` はプレフィックス誤認（後述 P1）**。`agy-run.ps1:16` |
| **WP5** | **PARTIAL** | `scripts/lead-lock.ps1` で acquire/release/status・stale 奪取ロジックあり。実行で `status` → `stale ai=claude ...` を確認。wrapper に lock チェックあり。**ただし `SD003_LEAD_AI` 未設定時は lock があっても拒否しない fail-open（報告書も認める）。依頼の「呼び出し元以外は拒否」は運用上ほぼ無効**（P2） |
| **WP6** | **PARTIAL** | CODEX Lead mode・quiz-gate の Grok Evaluator 委譲・sessionread の DONE 併読・CODEX_GUIDE 全面書換・handoff-log「任意…」の主要文書統一は確認。**GROK_NATIVE の Quiz Gate/sessionwrite が handoff 表ではなく Fast Review 直下に誤配置**（`.grok/GROK_NATIVE.md:41-43` vs handoff 表 71-77）。受け入れの「完全一致」は未達 |
| **WP7** | **PARTIAL** | C7 は `Lead mode` 検出で self-check PASS。upgrade purge に workflow-* 6件と退役 hook 名を追加（現役本体には stop-hook 実体なし＝誤 purge リスク低）。`recover-agy-artifacts` 配布・setup-guide 簡素化・`orchestrator.real-e2e.json` 配置は OK。**`CLAUDE.md.template` は 1行ブロックのみで、依頼の Grok two-modes / artifact-output IMPORTANT 未同期。さらに旧 safe-commit（SAME bash MUST）が残存**（`CLAUDE.md.template:3,63`） |

---

## 2. 発見した欠陥

### P0 — `bypassPermissions` 隔離ガードの Windows 大文字小文字すり抜け

`isRepositoryWorkspace` が文字列等価 / `startsWith` と `gitCommonDir` の **大小文字付き path 文字列比較のみ**（`runner.ts:59-64`）。

実行プローブ結果:

| workspace | dry-run + `args: ['bypassPermissions']` |
|-----------|------------------------------------------|
| `D:\claudecode\sd003`（正規） | **failed** — `Guard blocked ... unattendedWorkspaceAck` |
| `d:\claudecode\sd003`（ドライブ小文字） | **succeeded** — ガード未発火 |

`gitCommonDir` も `D:\...\ .git` vs `d:\...\ .git` で不一致。相対パス・サブディレクトリは塞がれているが、**依頼が明示した case 攻撃面が未塞ぎ**。P0 の隔離ガードとして不十分。

### P1 — `agy-run.ps1` ExpectedArtifact の path プレフィックス判定

```16:16:.claude/skills/agy-dispatch/agy-run.ps1
if ($ExpectedArtifact) { $artifact=[IO.Path]::GetFullPath((Join-Path $Repo $ExpectedArtifact)); $root=[IO.Path]::GetFullPath($Repo); if (-not $artifact.StartsWith($root) -or -not (Test-Path $artifact)) { ... } }
```

`D:\proj` に対し `D:\project\...` が `StartsWith` true になり得る。`resolveInside` 相当（root 一致 or `root + sep`）が必要。

### P1 — `CLAUDE.md.template` の 4AI 同期不足 + 旧 safe-commit 残存

- 依頼: Overview 4AI 行・Grok two-modes IMPORTANT・artifact-output IMPORTANT を本体と同期  
- 実装: 先頭 1 行 blockquote + C7 用 `Lead mode` トークンのみ（`CLAUDE.md.template:3`）  
- 本体では直した safe-commit がテンプレに旧文のまま（`:63` の MUST same bash）  
- 新規 deploy 先が旧ルールを再配布する

### P2 — lead-lock 強制が env 依存 fail-open

`SD003_LEAD_AI` 未設定時、lock 保持中でも wrapper は実行可（`grok-run.ps1:68`, `codex-run.sh:24-27`, `agy-run.ps1:6`）。報告書の保守的倒しは分かるが、WP5 受け入れの「拒否」は実質任意。

### P2 — GROK_NATIVE の Quiz Gate / sessionwrite 配置ミス

Lead Session 末尾・handoff 表への追加が依頼。現状は Fast Review 見出し直下に混入（`.grok/GROK_NATIVE.md:41-43`）。handoff 表に Quiz Gate 行なし。

### P2 — bypass 検出が exact token のみ

`arg === 'bypassPermissions'`（`runner.ts:89`）。`--permission-mode=bypassPermissions` 一体引数は未検出。現行 providers.json は分離 args なので実害は限定的。

### なしと確認したもの

- gitignored `test-results/` の dirty 誤検知: 問題なし（実行確認）  
- upgrade purge が現役 stop-hook を消す: 本体に実体なし、archive のみ → 誤 purge なし  
- C7 が常時 PASS/FAIL: self-check で PASS、トークン不一致で FAIL する設計として妥当  
- 入口文書の旧 7 段階「生きた指示」: 主要入口は掃除済み  

---

## 3. 総合判定

# **REQUEST_CHANGES**

**理由:** WP の大半は意図どおり入っているが、WP1 の核心である **bypassPermissions 隔離ガードが Windows パス大文字小文字で実行時すり抜け可能**であり、依頼が敵対検証項目に挙げた攻撃面が未閉鎖のため、完了主張は承認できない。加えて template 4AI 同期不足と agy artifact 判定のプレフィックス欠陥が残る。

（Quiz Gate は fail-open。本判定はマージをハードブロックしないが、**要再確認** を明示する。）

---

## 4. クイズ（Generator 向け・回答は本場では不要）

**Q1.** `isRepositoryWorkspace` で `path.resolve(__dirname,'..','..')` と workspace を比較している。Windows で scenario の `workspace` が `d:\claudecode\sd003`（ドライブ小文字）、実 repo が `D:\claudecode\sd003` のとき、プレフィックス判定と `git rev-parse --git-common-dir` 比較はそれぞれ true/false のどちらになり、結果として `bypassPermissions` ガードは発火するか。発火しない場合、正規化はどう入れるべきか。

**Q2.** `agy-run.ps1` の ExpectedArtifact 検査で `$artifact.StartsWith($root)` を使うと、`$Repo = 'D:\proj'` かつ成果物実パスが `D:\project\evil` のとき判定はどうなるか。`runner.ts` の `resolveInside` と同じ条件にするなら何と比較するか。

**Q3.** `verify-deployment.mjs` の C7 は `CLAUDE.md` に文字列 `Lead mode` があるかだけを見る。`CLAUDE.md.template` 先頭に `Lead mode` を1語入れ、本体では直した `.sd/` safe-commit 文をテンプレに旧「MUST complete git add + commit in the SAME bash command」のまま残した場合、C7 は PASS しうるか。それは WP7#1「本体 4AI ブロック同期」の受け入れを満たすか。

---

## Task Completion Report

### Summary
読み取り専用の敵対的検証を完了。総合 **REQUEST_CHANGES**（P0: Windows case による bypassPermissions ガードすり抜け）。

### Changes Made
| File | Action | Description |
|------|--------|-------------|
| （なし） | — | 検証のみ。一時プローブは `test-results/` に作成後削除 |

### Verification Commands
実行したもの: `git diff/show` 範囲確認、`node` による `isRepositoryWorkspace` / dry-run プローブ、cancellation 実行時検出、`node scripts/verify-deployment.mjs . .`、`pwsh scripts/lead-lock.ps1 status`

### Next Steps
- [ ] Generator: `isRepositoryWorkspace` を `path.resolve` + 可能なら `fs.realpathSync.native` / 大小文字正規化（Windows は lower）で修繕し回帰テスト追加  
- [ ] Generator: `agy-run` ExpectedArtifact を `resolveInside` 同等に  
- [ ] Generator: `CLAUDE.md.template` を本体 4AI + 現行 safe-commit に同期  
- [ ] 上記修正後、Evaluator が Q1〜Q3 相当を再プローブ
