# RULES.md - 共通開発ルール

このファイルは、**全AIモデルに共通の開発作法**を定義します。
モデル固有の設定ファイル（CLAUDE.md、AGENTS.md、grok.md等）は、このファイルを参照してください。

## プロジェクト構造

| ディレクトリ | 役割 |
|-------------|------|
| `.handoff/` | 引き継ぎパック（ORDER.mdはアクティブ指示があるときのみ実体を持つ、DONE.md） |
| `.sd/specs/` | 仕様書（requirements.md、spec.md、tasks.md） |
| `src/` | 実装コード |
| `tests/` | テストコード |
| `dist/` | ビルド出力（.gitignore） |

## Core Doctrine - 4本柱（最上位）

SD003 の全判断の根拠。詳細: `docs/core-doctrine.md`

| 柱 | 要点 | 根拠 |
|----|------|------|
| 1. Output Primacy | 「完了」=ユーザーが見るものが存在。画面ゼロ=未着手 | `.claude/rules/global/output-primacy.md` |
| 2. Silent Interior | 内部は黙って動け。設計の優雅さを議論しない | `.claude/rules/global/silent-interior.md` |
| 3. Real Data First | 実データで動かす。テストのためのテスト禁止 | `.claude/rules/global/real-data-first.md` |
| 4. Segmented Sequencing | 非ブロッキング連続 → 末端に1回確認。省略禁止 | `.claude/rules/global/segmented-sequencing.md` |

## Work First - まず動かす原則（最上位）

> 動かないソフトウェアに対するテスト・レビュー・文書は無価値。
> 詳細: `.claude/rules/global/work-first.md`

### 開発順序（厳守）
1. 最小コードで動かす（50行でいい）
2. 実環境で動作確認する（ブラウザで操作する）
3. 動いたら、テストを書く
4. 必要になったら抽象化する

### 変更前の3点固定
| # | 項目 | 確認内容 |
|---|------|---------|
| 1 | 運用ルール | push/deployの使い分け |
| 2 | 反映方法 | どのコマンドで反映するか |
| 3 | 確認対象URL | どのURLで確認するか |

### 禁止
- 動作確認なしでテスト・レビュー・文書作成に進む
- 原因確定前の修正反映の繰り返し
- 複数の挙動を一度に変更

## 無知の知（Known Unknowns / 4象限）

> 検証前に不確実性を明示する。「知らないことを知らないまま進める」のが最大のリスク。
> 詳細: `.claude/rules/global/known-unknowns.md`

- 着手前に自分の未知を **Known Unknown** の箱へ先回りして移す（blindspot pass・1問・フォーム化しない）。
- ラベル: **GREEN**=Known Known（証拠あり） / **YELLOW**=Known Unknown（要確認・条文/実データで潰す） / **RED**=Unknown Unknown疑い（乖離→bug-trace）。
- **未知の宣言は報酬対象**（罰しない）。検出不能な Unknown Unknown をゲート化する ceremony は作らない。
- 地図≠現場: CLAUDE.md/スキルは代理表現。強いモデルの失敗は静かで累積的。過剰な手取り足取りは定期的に棚卸し・削除。

---

## 基本コマンド

```bash
# ビルド
npm run build

# テスト
npm test

# Lint
npm run lint

# まとめて実行（推奨）
npm run build && npm test && npm run lint
```

## 命名規則

| カテゴリ | 規則 | 例 |
|---------|------|-----|
| ファイル | kebab-case | `handoff-pack.ts` |
| クラス | PascalCase | `HandoffPack` |
| メソッド | camelCase | `generatePack()` |
| 定数 | UPPER_SNAKE_CASE | `MAX_ITERATIONS` |
| ディレクトリ | kebab-case | `.handoff/` |

## 作業完了時の必須アクション

作業終了時は、必ず **DONE.md** を出力してください。内容は以下を含めます：

1. やったこと（変更ファイルと要約）
2. 確認結果（実行コマンドと結果）
3. 残っていること（未完了があれば理由と次の手順）
4. 判断したこと（設計上の選択があれば）

## 判断が必要な場面での振る舞い

**勝手に判断して進めないでください。** 判断が必要な場面では：

1. 選択肢を提示してください
2. 各選択肢のメリット・デメリットを簡潔に説明してください
3. ユーザーに選択を委ねてください

## GASデプロイルール（全AI共通・厳守）

| コマンド | 許可 | 条件 |
|---------|------|------|
| `clasp push` | 常時許可 | コード反映の標準手段 |
| `clasp deploy` | **ユーザー明示指示のみ** | 勝手に実行禁止 |

- GASのコード反映は `clasp push` のみ。`clasp deploy` はユーザーの明示指示なしに実行してはならない
- 引数なし `clasp deploy` は新規デプロイメントを作成する（既存URLが増える）ため特に危険
- 固定URL更新が技術的に必要でも、まずユーザーに確認すること

## 禁止事項

- [ ] **動作確認なしでテスト・レビュー・文書作成に進む**（Work First違反）
- [ ] **動かないソフトウェアに対する抽象化・パターン適用**
- [ ] **原因確定前の修正反映の繰り返し**
- [ ] プロジェクトルート直下へのファイル新規作成
- [ ] 既存の命名規則を無視した変更
- [ ] `.sd/specs/` 内の仕様書を無断で変更
- [ ] テストを書かずに実装のみを完了とする
- [ ] DONE.mdを出力せずに作業を終了する
- [ ] **テストのためのテスト**（本番エラー発見以外の目的のテスト）
- [ ] **モックデータ・ダミーデータ・空データでのテスト**（本番データまたはそのコピーを使うこと）
- [ ] **フォールバック付きテスト**（失敗時にスキップ/デフォルト値で通過するテスト）
- [ ] **VTD検証未通過のままテスト完了とする**（`npm run test:validate-data` で確認必須）
- [ ] **ファイルの直接削除（rm）**（アーカイブフォルダへ移動すること）
- [ ] **.sd/変更を長時間未commitで放置する**（変更後は早めにcommit。同一bashが最も安全。未commitの.sd/変更はwipe時にL4で復元されない）
- [ ] **作業前にブランチ／PRを勝手に作る**（一人運用=master/main直接作業。ブランチ／PRはユーザーが指示したときのみ作成。詳細: `.claude/rules/git/branch-strategy.md`）
- [ ] **`.claude/settings.json`をgit追跡する**（.gitignoreに入れること。追跡するとランタイムが.sd/を消す）
- [ ] **ユーザー提供ファイル・成果物の上書き**（元ファイル保持、修正版は別名で新規作成）
- [ ] **skills/フォルダ未確認でのファイル操作**（該当スキルがあればその手順に厳密に従うこと）
- [ ] **Playwright ブラウザキャッシュのローカル化**（必ず `D:\playwright-browsers` を使う。`PLAYWRIGHT_BROWSERS_PATH` をプロジェクトローカルパスに上書き禁止。詳細: `.claude/rules/global/playwright-cache.md`）
- [ ] **画面なし状態で「完了」と報告する**（柱1 Output Primacy 違反。ユーザーが見るものが存在するまで未着手扱い）
- [ ] **動く前の内部パターン導入**（柱2 Silent Interior 違反。Adapter-Core、Env Interface等は動いた後）
- [ ] **テストのためのテスト・カバレッジ目標のテスト**（柱3 Real Data First 違反。実データで動かす方が優先）
- [ ] **ユーザー確認をスキップする・毎ステップでブロックする**（柱4 Segmented Sequencing 違反。非ブロッキング連続→末端1回集約）

> テストの唯一の目的は「本番環境のエラーを発見し修正すること」。
> 詳細: `.claude/rules/testing/testing-standards.md`

## 仕様書の読み方

作業開始前に、必ず `.sd/specs/` を確認してください：

1. `requirements.md` - 何を作るべきか
2. `spec.md` - どう設計するか（`design.md` は使わない。Antigravity がUI設計用に予約）
3. `tasks.md` - タスクリストと進捗

---

## ファイル配置ルール（全AI共通 - Single Source of Truth）

このセクションは全AIモデル（Claude Code, Codex, Antigravity, Grok）に適用される。
各AI設定ファイル（CLAUDE.md, AGENTS.md, grok.md）はこのルールを参照すること。

### 仕様書

| ファイル | 保存先 |
|---------|--------|
| 要件定義書 | `.sd/specs/{feature}/requirements.md` |
| 技術設計書 | `.sd/specs/{feature}/spec.md` |
| タスクリスト | `.sd/specs/{feature}/tasks.md` |

### AI協調ワークフロー

| ファイル種別 | 保存先 |
|-------------|--------|
| 依頼書（自由形式） | `.sd/ai-coordination/workflow/spec/{案件ID}/` |
| 報告書（自由形式） | `.sd/ai-coordination/workflow/review/{案件ID}/` |

正本は `.claude/rules/workflow/ai-coordination.md`。

### セッション

| ファイル | 保存先 |
|---------|--------|
| 現在セッション | `.sessions/session-current.md` |
| タイムライン | `.sessions/TIMELINE.md` |
| セッション履歴 | `.sessions/session-YYYYMMDD-HHMMSS.md` |

### 成果物・レポート（AIが生成する文書・データ）

| 種別 | 保存先 |
|------|--------|
| ユーザー向けレポート・文書（.md/.html/.txt） | `materials/text/` / `materials/html/` |
| 表・データ（.csv/.xlsx） | `materials/csv/` / `materials/excel/` |
| 画像・PDF | `materials/images/` / `materials/pdf/` |
| フレームワーク・プロセス文書 | `docs/` |

**agy固有**: agyは既定で `~/.gemini/antigravity-cli/brain/<会話ID>/`（AppData隠しディレクトリ）に
保存するが、CLIユーザーからは見つけられない。SD003ではこの既定を上書きし、成果物を必ず
プロジェクト内へ書き出すこと。詳細: `.claude/rules/workflow/artifact-output-location.md`

### 配置禁止

- プロジェクトルート直下への新規ファイル作成
- `.antigravity/` への依頼書作成
- **`~/.gemini/antigravity-cli/brain/` 等のAppData隠しディレクトリへの成果物の唯一保存**
  （ユーザーが探せない。プロジェクト内 `materials/` 等へ書き出すこと）

---

**RULES.md v2.15.0** - Updated: 2026-07-12
