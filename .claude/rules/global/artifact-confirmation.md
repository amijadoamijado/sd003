# Artifact確認（確認事項の Artifact 提示）

## 原則

> 構造化された確認事項は、ターミナルの文字列の壁ではなく **Artifact（claude.ai 上の閲覧可能ページ）**で
> 提示し、ユーザーの認知負荷を下げる。**判断そのものは AskUserQuestion で末端集約する**
> （Artifact は「見せる層」であって「決める層」ではない）。

## 背景

ユーザー指示（2026-07-05）: 「ユーザーの認知負荷を軽減するため、確認事項は Artifact ツールにする」。

大量・多項目の確認事項をターミナルのスクロールで読ませるのは負荷が高い。視覚的に構造化された
ページ（表・pill・進捗・before/after）の方が把握が速い。これは柱1 Output Primacy とも整合する
（＝ユーザーが見て確認できる成果物を届けることが「確認」の完了条件）。

## 適用（Artifact化する / しないの線引き）

| 確認事項の性質 | 提示方法 |
|---------------|---------|
| 単純な二択・短い1問（「実行してよいか」等） | **AskUserQuestion をインライン**（Artifact不要） |
| 構造化・複数項目（計画/マトリクス/レビュー結果/多ファイル・多PJ一覧/差分要約/before-after/スコアリング） | **Artifact ページ化 → AskUserQuestion で判断** |
| 進行状況の可視化（長時間・多段の作業の途中経過） | **Artifact を進捗ダッシュボード化**（同一URLへ再デプロイで更新） |

**判断基準（1問）**: 「これはスクロールで読ませると把握しづらいか？」
Yes → Artifact。No → インライン。迷ったらインライン（軽い方に倒す）。

## 手順

1. **`artifact-design` スキルを読み込む**（Artifact作成の必須前提。ツール仕様で義務化されている）
2. 確認事項を自己完結HTMLで作成（対象の世界に根ざした構造・状態は pill/chip 等で符号化・両テーマ対応）
3. `Artifact` で公開し、**フルパスURL**をユーザーに提示（`fullpath-display.md` に準拠）
4. `AskUserQuestion` で判断ゲート（柱4 Segmented Sequencing = 末端に1回集約）

## 制約・正直な限界

- **Claude Code / claude.ai 固有機能**。Codex / agy(Antigravity) / Grok は Artifact を持たない
  → **本ルールは Claude Code 専用**。他AIは従来どおりテキスト＋確認でよい。
- **可用性はバージョン/アカウント依存**。Artifact ツールが無い環境では、簡潔なテキスト＋
  AskUserQuestion に**フォールバックする（ブロックしない）**。
- **物理ガードレール化しない**: Artifact 使用を hook で強制することは原理的にできず、また些細な確認まで
  Artifact化を強制するのは ceremony（`known-unknowns.md` が戒める弱モデル向け儀式＝次の Ralph Loop）。
  本ルールは**制御機構ではなくブリーフィング**として扱う（地図≠現場）。

## 禁止事項

| 禁止 | 理由 |
|------|------|
| 単純な二択・1問までArtifact化する | 過剰 ceremony・かえって遅い・認知負荷を下げるどころか上げる |
| Artifact を出して AskUserQuestion を省く | 判断ゲートは必須（柱4）。Artifact は提示層であって決定ではない |
| `artifact-design` を読まずに Artifact を作る | ツール仕様違反（必須前提）＋テンプレ的低品質 |
| Artifact 不可の環境でブロックする／エラーで止まる | 可用性は保証されない。テキストへフォールバックが必須 |
| 認知負荷が低い単発報告までページ化する | Silent Interior（柱2）に反する過剰投資 |

## 全AIモデル共通か

**いいえ — Claude Code 専用**（Artifact は他AIに存在しない）。
`.handoff/RULES.md`（全AI共通）には載せない。他AI（Codex/agy/Grok）はテキスト＋確認を継続する。

## 関連

- ドクトリン: `docs/core-doctrine.md` 柱1（Output Primacy）/ 柱4（Segmented Sequencing）
- `.claude/rules/global/segmented-sequencing.md`（確認は末端に1回集約）
- `.claude/rules/global/known-unknowns.md`（ceremony回避・地図≠現場）
- `.claude/rules/global/fullpath-display.md`（保存先/URLはフルパスで案内）
- 必須前提スキル: `artifact-design`（Artifact作成前に読み込む）
