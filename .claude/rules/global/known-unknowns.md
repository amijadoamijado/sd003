# 無知の知（Known Unknowns / 4象限）

## 原則

> 検証前に不確実性を明示する。「知らないことを知らないまま進める」のが最大のリスク。
> 着手前に、自分の未知を Known Unknown の箱へ**先回りして移す**。
> 無知の知とは、知識がないことの肯定ではなく、**自分の理解の限界を把握する力**。

## 背景

3つの層が同じ現象を別の解像度で語っている:

| 層 | 出典 | 役割 |
|----|------|------|
| 無知の知 | ソクラテス | 態度・哲学（自分の理解の限界を認識する姿勢） |
| 4象限 unknowns | Thariq "A Field Guide to Fable: Finding Your Unknowns" | AI協働での操作可能な手順 |
| GREEN/YELLOW/RED | SD003 / bl001 | 運用ラベル |

無知の知が思想、Thariqの4象限がその実装、GREEN/YELLOW/RED が運用ラベル。
接続を一文で: **無知の知が強い人ほど、本来 Unknown Unknown に落ちるはずだったものを
Known Unknown の箱へ先回りして移せる。**

**なぜフレームワークに組み込むか**: 弱いモデルの失敗は大きく局所的だが、**強いモデルの失敗は
静かで累積的**——不完全な地図（プロンプト/CLAUDE.md）を忠実に実行するため、書かれていない
前提のコストが跳ね上がる。この層は「静かな失敗」に対抗する=行動前に未知を宣言させる。
**ceremony（重い記入フォーム・マージ前クイズ）は追加しない。それ自体が弱モデル向けの
手取り足取り＝撤去対象**（cf. 2026-07-05 Ralph Loop/7段階workflow/context-autonomy 撤去）。

## 4象限（Thariq）と SD003ラベルの対応

正式訳語（2026-07-05確定）: 既知の既知・既知の未知・無自覚の既知・無自覚の未知。
危険なのは下段2つ、特に無自覚の未知。

| 象限 | 正式訳語 | 定義 | ラベル | 扱い |
|------|---------|------|--------|------|
| Known Known | 既知の既知 | 既に分かっている／プロンプトに書かれている | **GREEN** | 進む |
| Known Unknown | 既知の未知 | 分かっていないと自覚している | **YELLOW** | 確認してから進む |
| Unknown Known | 無自覚の既知 | 当たり前すぎて書かないが、見れば分かる | (blindspot passで表面化) | 明文化する |
| Unknown Unknown | 無自覚の未知 | そもそも考えてすらいない | **RED疑い** | blindspot pass／乖離検出→Bug Trace |

### GREEN / YELLOW / RED 定義

- **GREEN = Known Known**（証拠あり・確認済み）。
- **YELLOW = Known Unknown**（分かっていないと分かっている・要確認）。
  **YELLOWの発生条件 = 「Known Unknown の自己申告」**（この一文が定義）。
  YELLOW は条文・通達・事例・実データ確認を経てから GREEN へ昇格する。
- **RED = Unknown Unknown 疑い**（想定外の乖離）。`/bug-trace`（3エージェント並列調査）へエスカレーション。

## Claim/Evidence 4象限（confidence labeling）

既存の `claim-evidence-stop.sh`（Stop hook）と接続する。証拠の確信度を4象限でラベリング:

| ラベル | 意味 | 扱い |
|--------|------|------|
| Known-Confirmed | 証拠あり | GREEN。進む |
| Known-Assumed | 自己申告のみ・証拠なし | **claim-evidence-stop.sh が検出・ブロック**（「知っていると主張しているが実は知らない」） |
| Unknown-Flagged | 分からないと自覚し申告済み | **推奨・報酬対象（罰しない）**。YELLOW として扱う |
| Unknown-Undetected | そもそも気づいていない | 事前検出は原理的に不可能。事後回収（`implementation-notes.md`／セッション備考）で補う |

**Unknown-Undetected 専用ゲート（マージ前クイズ等）は作らない。**
検出不能なものをゲート化するのは ceremony。事後ログでの回収が現実的な80%。

## Blindspot Pass（Unknown Unknown → Known Unknown 変換）

非自明な作業の着手前、AIは**1回だけ**問う（フォーム化しない・1問）:

> 「この作業で、コードベース／ドメインについて自分が知らない前提は何か？ 触る前に洗い出せ。」

関連コード／ドメインを**実際に読んでから** Known Unknown を列挙し、ユーザーに提示する（YELLOW）。
Thariq の例: 「認証プロバイダを追加するが、このコードベースの認証モジュールを何も知らない。
blindspot pass で自分の未知の未知を洗い出し、より良いプロンプトを書けるよう手伝ってほしい」。

- Blueprint Gate に **Phase 5.5** として組込済（`.claude/skills/blueprint-gate/SKILL.md`）。
- 表面化した Known Unknown だけを扱う。「網羅した感」の演出は禁止。

## 会計税務ドメインへの適用（bl001）

> 「ここまでは分かっている。ただ、この部分は**条文・通達・事例確認が必要**」

この切り分けが **YELLOW ラベルの定義そのもの**。bl001 の信頼度ラベルは GREEN/YELLOW/RED を
そのまま採用し、**YELLOW は条文確認を強制してから進む**。

- 仕事が危ない人 = 知らないことを知らないまま進める。
- 仕事が強い人 = 知らない部分を早めに発見し、確認・相談・検証に回す。

## 地図 ≠ 現場（map ≠ territory）— 上位ドクトリン

CLAUDE.md／スキル／プロンプトは全て仕事の**代理表現（地図）**であって、仕事そのものではない。
強いモデルは地図を忠実に実行するため、書かれていない前提のコストが**静かに累積**する。ゆえに:

- **CLAUDE.md は制御機構ではなくブリーフィング文書**として扱う。
- スキルパッケージ（at001/at002/bl001 等）が**弱いモデル向けの過剰な手取り足取り**を
  含んでいないか定期的に棚卸しし、不要な儀式は削除する
  （2026-07-05 の Ralph Loop／7段階 workflow／context-autonomy 撤去はこの原則の実践）。

## 禁止事項

| 禁止 | 理由 |
|------|------|
| Unknown-Undetected を Known であるかのように進める | 「知らないことを知らないまま進める」＝最大のリスク |
| 検証前に不確実性を明示しない | 静かな失敗の温床 |
| 未知を宣言した者（Unknown-Flagged）を罰する | 宣言が報酬にならないと誰も宣言しなくなる |
| 検出不能な Unknown Unknown をゲート化する ceremony を作る（マージ前クイズ等） | 検出不能なものはゲートにできない |

> **切り分け**: 上記は Unknown-Undetected（検出不能な無自覚の未知）を対象にした禁止であり、
> Generator が既に「完了した」と自己申告した実装＝検証可能なものを対象にした
> `.claude/rules/global/quiz-gate.md`（非ブロッキング・Blueprint Gate必須ライン限定）とは別物。混同しない。
| 4象限を記入フォーム化して「網羅した感」を演出する | それ自体が次の Ralph Loop（弱モデル向け儀式） |

## 正直な限界

Unknown Unknown を**事前に**検出する方法は、ソクラテスにも Thariq にも存在しない
（原理的に不可能）。両者とも「事前検出」ではなく「**事後に発覚を早める仕組み**」しか
提供していない。この限界は融合しても消えない。過度な期待は禁物。

## 全AIモデル共通

このルールは Claude Code / Codex / Antigravity(agy) / Grok 全てに適用される。

## 関連

- ドクトリン: `docs/core-doctrine.md`（4本柱）
- 証拠ゲート: `.claude/hooks/claim-evidence-stop.sh`（Known-Assumed 検出）／`/ai-suspect`
- 着手前定義: `.claude/skills/blueprint-gate/SKILL.md`（Phase 5.5 Blindspot Pass）
- 迷走検出: `.claude/rules/troubleshooting/dialogue-resolution.md`
- RED エスカレーション: `.claude/rules/troubleshooting/bug-quick.md`（→ bug-trace）
- 完了主張の能動的検証: `.claude/rules/global/quiz-gate.md`（Unknown-Undetected とは対象が異なる。上記参照）
