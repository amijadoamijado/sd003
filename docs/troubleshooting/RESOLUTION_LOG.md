# 解決ログ（Resolution Log）

対話型解決法で解決した問題の記録。
再発防止と知見の蓄積を目的とする。

---

## ログエントリテンプレート

```markdown
## YYYY-MM-DD [機能名・処理名]

### 差異カテゴリ
[ ] 仕様理解の誤り
[ ] 実装の逸脱
[ ] 参照データ・状態の誤り
[ ] 仕様の曖昧さ
[ ] 外部要因・環境（API変更、ライブラリ等）

### 処理フローの差異
期待: [期待されたフロー]
実際: [実際のフロー/理解]

### 参照データ・状態の差異
期待: [期待されたデータ・状態]
実際: [実際に参照していたデータ・状態]

### 解決策
[実施した修正内容]

### 教訓
[再発防止のための気づき]
```

---

<!-- 新しいエントリは上に追加 -->

## 2026-07-25 Playwrightブラウザバイナリのgit混入によるpush恒久不能（fw003/oc001/ac001）

### 差異カテゴリ
[x] 実装の逸脱（playwright-cache ルール違反が git 履歴に焼き付いた）
[x] 外部要因・環境（GitHub の1ファイル100MB上限）

### 症状
fw003 / oc001 / ac001 の3リポジトリで、Chromium バイナリ（chrome.dll 246〜254MB 等）が
コミットされており、**GitHub の100MB上限により push が構造的に不可能**だった。
oc001 は19コミットが取り残され、旧 post-commit（無音push）のため誰も気づかなかった
（＝B17「無音push失敗の可視化」が対象にした事象そのもの。文字化け復元コミットの push 失敗
HTTP 408 で発覚）。

| PJ | 混入パス | 未push容量 |
|----|---------|-----------|
| fw003 | `pw-browsers/` | 529MB |
| oc001 | `.playwright-browsers/` | 700MB |
| ac001 | `node_modules/playwright-core/.local-browsers/`（HEADに存在） | ahead 5 |

### 解決策（fw003 / oc001 実施済み）
1. バックアップ: `git bundle create .git/pre-filter-backup-20260725.bundle --all`（238MB/389MB、各リポジトリの .git/ 内に保全）
2. `git filter-repo --invert-paths --path <dir> --force` で履歴から除去
   （実行前に作業ツリー清浄を確認。filter-repo は reset --hard 相当を行うため未コミット変更があると失われる）
3. `.gitignore` に当該ディレクトリを追記して再発防止
4. origin 再設定（filter-repo が remote を削除する）→ force push → upstream 追跡を張り直し

**結果**: fw003 529MB→1.4MB、oc001 700MB→134MB。100MB超blob 0個。リモート一致確認済み。
fw003 はバイナリ混入がリモート先端より後だったため、それ以前のハッシュ不変で fast-forward になった。

### 未対応（ac001）
ac001 は無関係の未コミット変更99件（文字化け復元37件含む）を抱えており、filter-repo の
reset --hard で失われるため**保留**。復元ファイルの commit を済ませてから同手順を適用すること。

### 教訓
1. **100MB超のファイルを一度でも commit すると、そのリポジトリは履歴書き換えまで永久に push 不能。**
   pre-commit で 50MB 超をブロックする物理ガードレールが未整備（改善候補）。
2. `.claude/rules/global/playwright-cache.md`（共有キャッシュ `D:\playwright-browsers` 使用）の
   違反はディスク容量問題ではなく **push 恒久不能**として現れる。
3. 無音 push 失敗（旧 post-commit）が本問題を4か月隠した。B17 修正（auto-push.log + 失敗マーカー）の
   全 PJ 展開が根本対策。

## 2026-07-25 一括移行による18プロジェクト・229ファイルの文字化け（4か月放置）

### 差異カテゴリ
[x] 実装の逸脱（一括処理スクリプトのエンコーディング取り扱い）
[x] 参照データ・状態の誤り（UTF-8をCP932として読み書きした）

### 症状
`2026-03-28` に全プロジェクトへ流した `.kiro→.sd` 一括移行（sd003 側の記録は
「28 projects .kiro->.sd migrated」）が、18リポジトリ・3,155ファイルを書き換えた際、
**229ファイルの日本語を破壊**した。ac001 では CLAUDE.md と `.claude/rules/` 7本が焼け、
**AIが自分の運用ルールを読めない状態**のまま119日間放置されていた。

被害上位: nm001 54件 / pc001 53件 / ac001 37件 / oc001 23件 / sb001 13件 / fw003 10件。

### 真因
一括処理が UTF-8 のファイルを CP932 として読んで書き戻す経路を通った。
被害は日本語に留まらない — CP932 の先頭バイトが隣接する **ASCII文字や改行まで飲み込む**ため:

| 移行前 | 移行後 |
|--------|--------|
| `# 🖥️ 【重要】動作環境：Windows + GAS` | `# 笨・indows + GAS` |
| `- API統合: 3つのOCR API並列実行` | `- API 3OCR API` |
| `api_quota: "APIクォータ",` | `api_quota: "API,`（閉じ引用符ごと消失） |
| 826行 | 728行（改行まで食われて行が結合） |

このため **文字コードを変換し直す方式では復元できない**（情報が物理的に失われている）。

### 解決策（復元）
移行コミットの**親リビジョンは全て正常**であることを利用し、git から取り直した。

| Tier | 方法 | 件数 |
|------|------|------|
| A | そのPJの移行直前リビジョンから復元 + 移行が意図した `.kiro→.sd` を再適用 | 226 |
| B | SD003本体の 2026-03-28 時点の同一パスから復元（移行で新規作成された等でA不可の分） | 3 |

**安全設計（情報欠落ゼロの根拠）**:
1. Tier A は「移行コミット以降そのファイルが変更されていない」場合のみ適用。この条件下では
   現在の中身は親から機械的に生成されたものしか含まないため、復元で失う情報が原理的に無い。
2. 移行後にコミットがある場合も、その差分が `.kiro→.sd` のリネームのみなら復元で再現されると
   機械判定して適用（例: cf001 `24ef3aa`「BOM/mojibake fix WIP」）。
3. リネームを再適用すべきか否かは、「原文のまま」と「置換後」の2候補のうち
   **破損版に残ったASCIIパストークンの出現数に近い方**を機械選択した
   （破損側のASCII骨格照合は、化けの過程で元々存在しないASCII断片が生成されるため誤検知する）。

**検証**: 復元後に8,872ファイルを再走査し**文字化け残存0件**。
スクリプト: `C:\AppData\Local\Temp\claude\...\scratchpad\restore_mojibake.py`（--apply で適用）

### 教訓
1. **全プロジェクト一括処理は、失敗も一括で配る。** 1回のスクリプトが18リポジトリを同時に壊した。
   一括処理には「1件で試す → 検証 → 残りへ展開」の段取りを必ず挟む。
2. **文字化けは日本語だけの問題ではない。** ASCIIも改行も消える。「表示が読めない」ではなく
   「データが欠損している」と扱う。
3. **git は最良のバックアップだった。** 親リビジョンが無事だったので全件復旧できた。
   逆に言えば、未コミットのまま一括処理を流していたら全損だった。
4. **壊れたことに誰も気づかなかった経路も直す。** 文字化けは静かに残る。定期的な機械スキャン
   （`縺/繧/繝/笨` 等の出現数 vs ひらがな数）で検出可能。
5. 過去に一度 `24ef3aa`「BOM/mojibake fix WIP」で修復が試みられ、**途中で止まっていた**。
   WIPで止めた作業は、残りが自動的に消えるわけではない。

## 2026-07-25 Codex自動レビューhookの無音故障（約4か月）＋ 自動pushの無音失敗

### 差異カテゴリ
[x] 実装の逸脱（外部CLIの引数仕様と実装の乖離）
[x] 外部要因・環境（codex CLI の排他引数）
- 共通の増幅要因: **`2>/dev/null` による stderr 破棄**（＝失敗の無音化装置）

### 症状
1. コミットのたびに `.codex-review-result.md` が「Codex CLI exited with code 2」の
   エラースタブだけを含んで生成される。**16プロジェクトで同状態**を確認。
   最後に成功したレビュー実体は oc001 の 2026-03-08 が最後。
2. ob001 は `.codex-review-result.md` が `.gitignore` 未登録のため、毎コミット
   **未追跡ファイル**として出現していた（sd003 / ta001 は登録済みのため不可視だった）。
3. 明示的な `git push` が常に "Everything up-to-date" を返す。post-commit hook が
   既に非同期 push 済みのため。しかも **push 失敗時は完全に無音**。

### 真因
| # | 真因 | 証拠 |
|---|------|------|
| 1 | commit `231aca3`(2026-03-31)「migrate Codex calls from `codex exec --full-auto` to native `codex review`」で `codex review --commit <SHA> "<PROMPT>"` に変更した。codex CLI は `--commit` と `[PROMPT]` が**排他**（`--uncommitted` も同様）。 | 実測: `error: the argument '--commit <SHA>' cannot be used with '[PROMPT]'` → exit 2（codex-cli 0.145.0） |
| 2 | 呼び出しが `2>/dev/null` で stderr を捨てていたため、上記エラー文が4か月間一度も表示されず、記録も「exit code N」だけ＝真因が断絶していた。 | `.claude/hooks/agent-review.sh` 旧118行 |
| 3 | post-commit の `nohup git push ... >/dev/null 2>&1 &` が終了コードも出力も破棄。 | `.git/hooks/post-commit` 旧92行 |

### 検証（実測 2026-07-25 / codex-cli 0.145.0）
- `codex review --commit 4db367a "<prompt>"` → **exit 2**（引数排他エラー・1秒未満）
- `codex review --uncommitted "x"` → **exit 2**（同上）
- `codex review --commit 4db367a`（PROMPT無し・正しい形）→ **240秒経過しても未完（exit 124）**
  → 修正して実際に動かすと、PostToolUse hook（settings.json の `timeout: 600`）が
  **毎コミット数分 Claude Code をブロックする**。既定ONにはできないことが判明。

### 解決策
| # | 対策 | 種別 | 対象 |
|---|------|------|------|
| 1 | 呼び出しを正準 `codex exec`（`RUST_LOG=error` / `-c model_reasoning_effort=medium` / `--sandbox read-only` / `-o` / `2> progress.log`）へ戻す | 実装修正 | `.claude/hooks/agent-review.sh`, `scripts/agent-review.sh`, `scripts/agent-pipeline.sh` |
| 2 | 失敗時は **stderr の tail を必ず成果物に添付**（原因断絶の解消） | 可視化 | 同上 |
| 3 | 自動レビューを **既定OFF・opt-in (`SD_AUTO_REVIEW=1`)** 化＋タイムアウト上限（既定300秒） | 設計変更 | `.claude/hooks/agent-review.sh` |
| 4 | 自動pushの結果を `.git/auto-push.log` に必ず記録、失敗時は `.git/auto-push-failed` マーカーを残し**次回コミット冒頭で警告** | 可視化 | `templates/git-hooks/post-commit`（+ 実体 `.git/hooks/`, AIミラー） |
| 5 | deploy 時に `.codex-review-result.md` を配信先 `.gitignore` へ自動追加 | 配信整合 | `.claude/skills/sd-deploy/deploy.ps1` Phase 5-5b |

### 教訓
1. **`2>/dev/null` は「失敗の無音化装置」**。エラーパスでは stderr の tail を必ず残す。
   これが無かったため、1秒で判明するはずの引数エラーが4か月生き残った。
2. **外部CLIの呼び出し形式を変えるコミットは、成功パスの実測なしにマージしない。**
   `231aca3` は「移行した」だけで、移行後に1度も成功していない。
3. **壊れたまま静かに回る自動化は、無いより悪い**（毎コミット無意味なファイルを撒く）。
   直す＝有効化ではない。直したうえで「常時実行してよいコストか」を測って決める。
4. hookの成果物は**配信先の `.gitignore` まで含めて1セット**。片方だけ配ると未追跡ゴミになる。

## 2026-06-14 AI挙動不審: 未検証の起動方法を「確定済み」と断定（証拠＜語りの過信）

### 類型
[x] (A)捏造/過信  [x] (B)ルール不遵守（root-cause-first 検証ステップ省略）  [x] (C)プロキシ誤認（バナー→起動方法）

### 症状（定量被害）
- auto-accept が自動ONにならない件で、冒頭 `Exited Plan Mode` バナー1個を根拠に「プランモードで起動された」と推定し、2回目応答で「調査で**確定済み**」へ格上げ（新証拠ゼロ）。
- 起動方法は session内から観測不能な事実。さらに同session内の反証（`-ExecutionPolicy Bypass` 拒否時の "Claude Code auto mode classifier" 稼働＝acceptEdits有効）を訂正まで未開示。
- 実害: 誤原因を2回提示／ユーザーに訂正コスト1回／真因特定が1往復遅延。気づきはユーザー指摘（自己発見でない）。

### 真因（5Why Why5）
優先順位の逆転＝「もっともらしい説明を出す ＞ 観測事実で詰める／不明を不明と言う」。
結論先行（acceptEdits is broken）→ 都合のよい proxy を権威化 → 観測不能を「確定」で埋め → 手元の反証を捨てる。
模範5Why(at002 2026-06-13)「実物の証拠 ＞ スキル ＞ 自分の知識」の逆転と同根。root-cause-first の「自分を先に疑い"検証してから"断定」を飛ばした一点に収束。

### 決定論対策（採用したガードレール・実装＋実測済み）
- 機構: `.claude/hooks/claim-evidence-stop.sh`（Stop hook）＋ `.claude/hooks/claim_evidence_detect.py`（決定論検出器）＋ 回帰テスト `tests/hooks/claim-evidence-detect.test.sh`。
- 判定（二条件AND・低FP）: 因果確信語（原因は…だ/真因は/確定/確定済み/確認した）present **かつ** 同ターンに証拠（tool実行 / `path:line`引用 / `backtick`出力引用）absent → 非ブロッキングで warn。
- fail-open: warn のみ・Stop を block しない（2026-05-26 重ゲート自壊を踏まない）。`.claude/settings.json` の Stop に配線済み。
- 実測: 回帰テスト4本 ALL PASS（陽性1/陰性3）。gate経路を合成transcriptで陽性=systemMessage警告／陰性=plain approve を確認。

### bd issue（sd003 は .beads 未初期化 → フォールバック記録）
- bd CLI: present。sd003 `.beads/`: **なし**。よって bd issue 未発行。
- **bd化TODO（issue intent）**: title=「claim-evidence Stop hook の sd003 配線・回帰テスト常設」/ labels: ai-misconduct,guardrail,A
  acceptance: 「(1) claim-evidence-stop.sh が settings.json Stop に配線され (2) 回帰テストが CI/npm test 経路で実行され (3) 本incidentの主張（『原因は…確定済み』証拠ゼロ）を再現入力すると detector が FLAG する」。
- **incident状態**: この bd化TODO が解消（sd003 で bd init → issue発行 → close、または回帰テストの常設実行経路への組込）まで **OPEN**。

### 教訓
実物の証拠 ＞ 語り。観測不能な事実は「確定」と言わず『推測』と明示する。手元の反証は結論より先に反映する。文書化のみでは5/5再発＝機構（hook＋回帰テスト）に焼き込んで初めて閉じる。

## 2026-05-07 SD003仕様書配置ルール違反（at001-v1事故）

### 差異カテゴリ
[x] 仕様理解の誤り（AIが docs/specs/ を選択 / SD003標準は .sd/specs/）
[x] 実装の逸脱（標準パスが空のまま、非標準パスに成果物が蓄積）
[x] 仕様の曖昧さ（spec-driven.md の paths 制約が「鶏卵問題」を生む構造）

### 処理フローの差異

| 項目 | 期待（SD003標準） | 実際（at001-v1） |
|------|------------------|------------------|
| 仕様書配置 | `.sd/specs/{feature}/` | `docs/specs/at001-v1/`（SD003標準外） |
| 物理ガードレール | あり（PreToolUse hookで物理deny） | **不在** |
| ルール発火条件 | 常時 | `.sd/specs/**/*` に置いた時のみ |

### 根本原因（複合要因）

**主因1: paths制約の構造的欠陥（鶏卵問題）**

`.claude/rules/specs/spec-driven.md` の frontmatter:
```yaml
paths:
  - ".sd/specs/**/*"
  - ".sd/steering/**/*"
```

→ 「`.sd/specs/` 配下にファイルがあるときだけルールを発火」する設計。
裏返すと「`.sd/specs/` に置かなければルール自体が読まれない」。
**違反した瞬間にルールが消える設計**で自己修正不可。

**主因2: 物理ガードレールの不在**

`.claude/rules/skills/skill-check-before-action.md` には PreToolUse hook
（`enforce-skill-read.sh`）があり、SKILL.md未読時にツール実行を物理denyする。
過去2回の事故（cf001 / サクセス変換）から導入された仕組み。

仕様書配置については同等のhookが存在せず、AIの「自然な判断」で容易に破られる。

**主因3: 直感的な docs/ 選択**

AI（Claude Code）は一般的なOSS慣習（多くが docs/ 配下に仕様書を置く）に従い、
`docs/specs/at001-v1/` を選択。SD003ルールを確認せずに開始した。

**副因: at001-v1の統合パッケージ性質**

SD003 spec-driven は「1 feature = 1 spec」想定だが、at001-v1 は29スキル・15顧客の
統合パッケージで構造的に収まらず、AIが docs/specs/ に逃した可能性。

### 解決策

| # | 対策 | 種別 |
|---|------|------|
| 1 | docs/specs/at001-v1/ → .sd/specs/at001-v1/ に git mv | 物理移動 |
| 2 | `.claude/hooks/enforce-spec-location.sh` 新設（PreToolUse） | 物理ガードレール |
| 3 | spec-driven.md の paths 制約撤廃（または `**/specs/**` に拡大） | 構造修正 |
| 4 | CLAUDE.md Conditional Context に spec 配置を明記 | ルート修正 |
| 5 | 仕様書ファイル名を `design.md` → `spec.md` に統一 | 命名規約変更 |
| 6 | 全12デプロイ済みPJで `design.md` → `spec.md` リネーム | 既存資産整合 |

**spec.md採用理由**: Google Antigravity が `design.md` を UI 設計ファイルとして
予約済み。SD003 内部仕様書と衝突するため `spec.md` に分離する。

### 教訓

1. **「ルール宣言 ≠ 強制」**: skill-check-before-action.md の教訓
   「ルール文書だけでは不十分。物理ガードレールが必要」が specs にも当てはまる
2. **paths制約は二刀流**: 「配下にあるとき発火」は監視には有効だが、
   「配置を強制する」目的には逆効果（鶏卵問題）。配置強制は別の hook で行う
3. **AI の「直感」を信用するな**: OSS慣習（docs/）と SD003 規約が矛盾するなら、
   物理的に止める仕組みが必要
4. **既存資産との整合**: ルール変更時は既存配布物（12PJ）の追従リネームを
   忘れずに含める。さもなくば「新ルール準拠の新規」と「旧ルール準拠の既存」が
   混在し、再び混乱の原因になる

### 関連
- セッション: `.sessions/session-20260507-093444.md`（次回更新時）
- 影響PJ: at001（移動対象）, sd003本体（ルール改訂）, 全12デプロイPJ（リネーム）
