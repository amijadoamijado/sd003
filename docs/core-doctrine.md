# SD003 Core Doctrine（開発ドクトリン）

SD003 における全ての開発判断の根拠となる思想。ルール・スキル・コマンド・ガードレールはこのドクトリンから派生する。

## 最上位原則

> **原則を書くのではなく、ガードレールを作る。**
> 「動けばいい」を実現するのは精神論ではなく仕組み。違反を物理的に止められない原則は、原則でない。

---

## 4本柱

### 柱1: Output Primacy（アウトプット最優先）

**定義**: 「完了」とはユーザーが見る画面・受け取る成果物が存在し検証済みの状態をいう。

**否定形**:
- ファイル数、テスト数、型定義数、コミット数は完了の指標ではない
- 画面がない状態は、他の進捗がいくらあっても**未着手**として扱う
- 「実装完了」という言葉を画面存在と切り離して使わない

**帰結**:
- IMPLEMENT_REQUEST の Section 2 必須トップ項目は「ユーザーが見る画面・受け取るもの」
- 進捗レポートはスクリーンショットを含まない限り受理されない
- コードレビューの配点は UI/アウトプット >> 内部コード品質

**根拠ルール**: `.claude/rules/global/output-primacy.md`

### 柱2: Silent Interior（内部は黙って動け）

**定義**: 内部実装（adapter / core / interface / types）は動けばよい。内部設計の優雅さを議論しない。

**否定形**:
- 型定義 → interface → adapter → core のボトムアップ順で作らない
- Adapter-Core 分離パターンを動く前に導入しない
- 内部アーキテクチャの議論が output を阻害する時は、議論を打ち切り最短で output を作る

**帰結**:
- 内部の議論は output を阻害する時のみ許可
- 「綺麗なコード」より「動くコード」
- 内部リファクタは output が安定した後

**根拠ルール**: `.claude/rules/global/silent-interior.md`

### 柱3: Real Data First（実データ先行・テスト最小主義）

**定義**: 実データまたはコピーで直接動かす。モック経由しない。テストは本番バグ再現時のみ書く。

**否定形**:
- モック・ダミー・空データでテストしない
- カバレッジ目標のためにテストを書かない
- `toBeDefined()` のみ、`expect(true).toBe(true)` 等のアサーションなしテストを書かない
- フォールバック付きテスト（失敗時にスキップ/デフォルト値通過）を書かない

**帰結**:
- Adapter層は本番データコピーでのみ検証
- 動作確認は「実データ + ブラウザ」で行う
- 実データで再現したバグを固定する時だけ、その最小テストを追加する
- カバレッジ80%目標は廃止。代わりに VTD-001〜005 + 実データ動作確認

**根拠ルール**: `.claude/rules/global/real-data-first.md`

### 柱4: Segmented Sequencing（段取りの分離）

**定義**: ユーザー確認不要な作業を連続実行 → 最後に1回だけユーザー確認ゲート。

**否定形**:
- ユーザー確認を毎ステップ挟まない（効率低下）
- ユーザー確認を完全にスキップしない（安全性崩壊）
- 早期のユーザーブロッキングで流れを止めない

**帰結**:
- workflow-impl 内: `tsc → lint → test(VTD) → dev server → ブラウザ疎通 → スクショ` を非ブロッキング連続実行
- 最後の1ステップで `AskUserQuestion` を発火（ここだけがユーザーブロッキング）
- 夜間モード (`/ralph-wiggum:run`) はこの原則の夜間版。非ブロッキング部分のみ実行し、確認は朝1回
- ユーザー確認の**省略は禁止**。タイミングをずらすのは OK

**根拠ルール**: `.claude/rules/global/segmented-sequencing.md`

---

## ガードレール対応表

| 柱 | Template (T1) | Pre-commit (T2) | Workflow Stop (T3) | Command (T4) | Observability (T5) |
|----|--------------|----------------|-------------------|-------------|-------------------|
| 1: Output Primacy | IMPLEMENT_REQUEST 画面欄必須 | - | スクショなしで review 不可 | workflow-request 欄検証 | session 記録に画面有無 |
| 2: Silent Interior | - | `any`, `@ts-nocheck` 拒否 | - | - | - |
| 3: Real Data First | - | VTD + アサーションなし拒否 | - | - | - |
| 4: Segmented Sequencing | - | - | User Confirmation record 必須 | workflow-impl Step 6 AskUserQuestion | 確認Y/N記録 + スキップ検出 |

## 既存ルールとの関係

このドクトリンは既存のルールを**置き換えない**。既存ルールを4本柱の下に再配置する。

| 既存ルール | 属する柱 |
|-----------|---------|
| `.claude/rules/global/work-first.md` | 柱1（output）+ 柱3（real data） |
| `.claude/rules/global/quality-standards.md` | 柱2（silent interior の品質基準） |
| `.claude/rules/testing/testing-standards.md` | 柱3（real data first） |
| `.claude/rules/testing/production-data-tdd.md` | 柱3（real data first） |
| `.claude/rules/ui/web-design-principles.md` | 柱1（output primacy の具体） |
| `.claude/skills/blueprint-gate/SKILL.md` | 柱1（要件定義フェーズでの output 先行） |
| `.claude/rules/architecture/adapter-core-pattern.md` | 柱2（動いた後に適用するパターン） |

## 禁止される議論

以下の議論に時間を溶かさない（柱2違反）:
- 「綺麗なインターフェース設計」（動いてから）
- 「再利用性のための抽象化」（3回同じコードが出てから）
- 「将来の拡張性」（今必要でないものは作らない）
- 「型の美しさ」（`any` 禁止は守りつつ、それ以上は追求しない）

## 変更履歴

| 日付 | バージョン | 変更 |
|------|-----------|------|
| 2026-04-12 | 1.0.0 | 初版（セッション中のユーザー対話を原典化） |
