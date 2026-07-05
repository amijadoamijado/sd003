# Quiz Gate（クイズゲート・完了主張の検証）

## 原則

> Generator（実装者）の「完了した」という自己申告は、それ単体では証拠ゼロとして扱う。
> Evaluator が実装内容について具体的な質問（クイズ）を出題し、Generator が実データ・コードを
> 見ながら答えられて初めて、完了主張に裏付けが付く。

## 背景

記事「8技法」のクイズ技法（⑧）。既存の Claim/Evidence Gate（`claim_evidence_detect.py` /
`claim-evidence-stop.sh`）は、テキストパターンから**受動的に**未検証の因果断定を検出するが、
実装内容そのものを**能動的に問う**仕組みは SD003 になかった。両者は補完関係にある。

## 対象範囲（ceremony回避のため限定）

**Blueprint Gate 必須ライン以上のタスクのみに適用する**（`.claude/skills/blueprint-gate/SKILL.md`
の適用基準＝1時間以上かかる、またはゴールとアウトプットが言語化できていなかったタスク）。

- Work First で直接着手した小さな修正・タスクには適用しない
- 毎コミット・毎タスクへの適用は禁止（ノイズ化・ceremony化を防ぐ）

## known-unknowns.md の禁止事項との切り分け（重要）

`.claude/rules/global/known-unknowns.md` の禁止事項に「検出不能な Unknown Unknown をゲート化
する ceremony を作る（マージ前クイズ等）」とある。これは**原理的に検出不可能な無自覚の未知**を
無理にゲート化するな、という意味であり、Quiz Gate とは対象が異なる。

Quiz Gate が対象にするのは、Generator が既に「完了した」と自己申告した実装＝**コード差分として
存在し、Evaluator が読めば検証可能なもの**。検出不能ではない。混同しないこと。

## 出題フロー

1. Generator（実装者）が Blueprint Gate 必須ラインのタスクで実装完了を主張する
2. `/codex:review`（既存の Codex ディスパッチ導線）で、実装差分と要件定義書の検証観点
   （Blueprint Gate Phase 3）を Evaluator（Codex）に渡す
3. Evaluator は差分の内容に即した具体的な質問を1〜3問作り出題する
   （例:「なぜこの実装方式にしたか」「この入力パターンでどう振る舞うか」）
   フォーム化・定型質問リスト化はしない。実装内容に応じて都度作る
4. Generator は実データ・コードを見ながら回答する（暗記・推測での回答は不可）
5. Evaluator が回答の妥当性を判定する

## 不合格時の扱い（非ブロッキング警告）

`claim-evidence-stop.sh` と同型。fail-open。

- 不正解、または Evaluator が回答に疑義を持った場合でも、完了報告・コミット・マージ自体は
  **ブロックしない**
- 「クイズ不合格あり・要再確認」であることをユーザーに見える形で明示するに留める
  （systemMessage相当、または報告メッセージへの一文追記）
- ハードゲート化（マージブロック・強制差し戻し）は行わない。決定論的な自動採点を前提にした
  ブロッキングは、Generator と Evaluator の両方を AI が担う場合に「AIの判定にAIの判定を検証
  させる」循環に陥りやすいため避ける

## 禁止事項

| 禁止 | 理由 |
|------|------|
| Blueprint Gate 必須ライン未満のタスクへの適用 | ceremony化・非効率 |
| 定型質問リストのフォーム化 | 実装内容に即さない質問は検証にならない |
| 不合格時のハードブロック | AI同士の循環判定になりやすい。既存の fail-open 方針と不整合 |
| Unknown-Undetected（無自覚の未知）の検出目的での使用 | 対象外。known-unknowns.md 参照 |

## 全AIモデル共通

Codex を Evaluator として呼び出す前提のため、実務上は Claude Code（Generator/司令塔）から
`/codex:review` を呼ぶ形が主。Codex 側は既存の `.claude/skills/codex-dispatch/` 導線をそのまま使う。
Antigravity(agy) / Grok が Generator の場合も、Evaluator は Codex に固定する（役割分岐の一貫性）。

## 関連

- `.claude/hooks/claim-evidence-stop.sh` / `.claude/hooks/claim_evidence_detect.py`（受動検出）
- `.claude/rules/global/known-unknowns.md`（Unknown-Undetected との切り分け）
- `.claude/rules/workflow/ai-coordination.md`（Codex ディスパッチ導線）
- `.claude/skills/blueprint-gate/SKILL.md`（適用ラインの定義元）
