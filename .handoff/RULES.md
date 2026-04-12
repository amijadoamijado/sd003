# RULES.md - 共通開発ルール

このファイルは、**全AIモデルに共通の開発作法**を定義します。
モデル固有の設定ファイル（CLAUDE.md、AGENTS.md、GEMINI.md等）は、このファイルを参照してください。

## プロジェクト構造

| ディレクトリ | 役割 |
|-------------|------|
| `.handoff/` | 引き継ぎパック（ORDER.md、DONE.md） |
| `.sd/specs/` | 仕様書（requirements.md、design.md、tasks.md） |
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
- [ ] **.sd/ファイル変更をbash呼び出しをまたいでcommitする**（同一コマンド内でadd+commit必須。詳細: `.claude/rules/git/sd-safe-commit.md`）
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
2. `design.md` - どう設計するか
3. `tasks.md` - タスクリストと進捗

---

## ファイル配置ルール（全AI共通 - Single Source of Truth）

このセクションは全AIモデル（Claude Code, Codex, Gemini CLI, Antigravity）に適用される。
各AI設定ファイル（CLAUDE.md, AGENTS.md, gemini.md）はこのルールを参照すること。

### 仕様書

| ファイル | 保存先 |
|---------|--------|
| 要件定義書 | `.sd/specs/{feature}/requirements.md` |
| 技術設計書 | `.sd/specs/{feature}/design.md` |
| タスクリスト | `.sd/specs/{feature}/tasks.md` |

### AI協調ワークフロー

| ファイル種別 | 保存先 |
|-------------|--------|
| 発注書 | `.sd/ai-coordination/workflow/spec/{projectID}/WORK_ORDER.md` |
| 実装指示 | `.sd/ai-coordination/workflow/spec/{projectID}/IMPLEMENT_REQUEST_{NNN}.md` |
| テスト依頼 | `.sd/ai-coordination/workflow/spec/{projectID}/TEST_REQUEST_{NNN}.md` |
| レビュー結果 | `.sd/ai-coordination/workflow/review/{projectID}/REVIEW_{type}_{NNN}.md` |
| テスト報告 | `.sd/ai-coordination/workflow/review/{projectID}/TEST_REPORT_{NNN}.md` |

### セッション

| ファイル | 保存先 |
|---------|--------|
| 現在セッション | `.sessions/session-current.md` |
| タイムライン | `.sessions/TIMELINE.md` |
| セッション履歴 | `.sessions/session-YYYYMMDD-HHMMSS.md` |

### 配置禁止

- プロジェクトルート直下への新規ファイル作成
- `.antigravity/` への依頼書作成
- テンプレートなしの依頼書作成

---

**RULES.md v2.0** - Updated: 2026-02-15
c
