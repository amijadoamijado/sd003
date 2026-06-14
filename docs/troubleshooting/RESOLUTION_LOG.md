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
