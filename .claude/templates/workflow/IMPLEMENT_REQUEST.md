# IMPLEMENT_REQUEST_{NNN}

> ⚠️ このテンプレートの Section 0（Quality Prerequisites）は**変更・削除禁止**。
> 自動挿入され、実装者は全項目を満たしてレビューに回すこと。
> Section 1/2/3/5/6 は案件ごとに具体化する。
>
> 実体コピー時: このファイルを `.sd/ai-coordination/workflow/spec/{案件ID}/IMPLEMENT_REQUEST_{NNN}.md` にコピーし、Section 1-7 を具体化する。

---

## 0. Quality Prerequisites（⛔ 変更不可）

SD003 Core Doctrine `docs/core-doctrine.md` に準拠。以下を**着手前に理解**し、完了時に全項目を満たすこと。

### 0.1 TypeScript（strict 前提、柱2 Silent Interior）
- [ ] `any` 型の使用禁止。やむを得ない場合は `unknown` + 型ガード
- [ ] `@ts-ignore` / `@ts-nocheck` / `@ts-expect-error` 全面禁止（pre-commit hookで自動拒否予定）
- [ ] `noImplicitAny` / `strictNullChecks` / `noUnusedLocals` 通過
- [ ] `null` / `undefined` を返す関数は戻り値型に明示
- [ ] 外部入力（API応答、JSON.parse結果等）は型ガード or zod等で検証

### 0.2 命名・構造
- [ ] ファイル: kebab-case、クラス: PascalCase、関数/変数: camelCase、定数: UPPER_SNAKE_CASE
- [ ] import path alias は tsconfig.json の paths を使用。`@/client/...` と `@/...` を混在させない
- [ ] export は **named export を基本**。default export は UI コンポーネントルート等の慣例時のみ
- [ ] 1ファイルで default と named を混在させない

### 0.3 Lint
- [ ] ESLint エラー 0 件
- [ ] `console.log` 禁止（Logger 経由のみ）
- [ ] マジックナンバー禁止（名前付き定数に）
- [ ] ネスト深さ3階層以下

### 0.4 テスト（柱3 Real Data First・テストのためのテスト禁止）

> **絶対原則**: テストのためのテストは書かない。実データで動かして修正する方が効率的。
> テストは「本番で発生したバグを再現・防止する」ためにのみ書く。

- [ ] カバレッジ目標のためだけのテスト禁止
- [ ] `toBeDefined()` のみのアサーション、`expect(true).toBe(true)` 等の自明テスト禁止
- [ ] モック・ダミー・空データでのテスト禁止（実データコピーのみ）
- [ ] フォールバック付きテスト（失敗時にスキップ/デフォルト値通過）禁止
- [ ] VTD-001〜005 全通過（`npm run test:validate-data`）
- [ ] 動作確認は**まず実データ + ブラウザ**。テストを先に書かない
- [ ] 実データで再現したバグに対してのみ、最小テストを追加する

### 0.5 エラー処理
- [ ] try/catch で握り潰し禁止（ログ or 上位に伝搬）
- [ ] Result型 or throw の方針を統一（1ファイル内で混在させない）

### 0.6 GAS 案件のみ適用（該当時チェック）
- [ ] Node.js APIs (`fs`, `path`, `process`) 使用禁止
- [ ] Env Interface Pattern 使用（IEnv 経由でGAS/Local切替）
- [ ] iframe制約の認識（`window.location.href` 不可、`position: fixed` 不可等）
- [ ] `clasp push` のみ。`clasp deploy` はユーザー明示指示時のみ

### 0.7 Work First 順序（柱1 Output Primacy）
- [ ] **UI（画面）から作る**。型定義 → interface → adapter → core のボトムアップ禁止
- [ ] 最小で動く状態をまず作り、ブラウザで開いて確認してから内部を整える
- [ ] 「動かないが型は揃っている」状態でコミットしない
- [ ] 実装後、必ずブラウザで画面が表示されることを確認しスクリーンショットを取得する

---

## 1. 案件情報
- **案件ID**: {案件ID}
- **タスク番号**: {タスク番号}
- **ブランチ名**: feature/{案件ID}/{タスク番号}-{slug}
- **stack**: {GAS / Next.js / Vanilla / CLI / Other}（package.json から検出）

## 2. ゴール（ユーザーが見る画面・受け取るもの）⭐ 必須

> ⚠️ この欄は柱1 Output Primacy により**必須**。
> 空のまま作成することは禁止。空なら workflow-request コマンドが拒否する。

{ここに「完成時にユーザーが見る画面・受け取る成果物」を具体的に書く}

### 成果物の種類（チェック）
- [ ] 画面（URL + スクショ取得対象）
- [ ] ファイル出力（CSV / Excel / PDF / 画像）
- [ ] CLI 出力（stdout + ログ）
- [ ] API レスポンス（エンドポイント + サンプル応答）

### 確認URL / ファイルパス
{具体的な URL、またはファイル保存先}

## 3. 実装対象

### 3.1 変更可能ファイル
{WORK_ORDER から特定したファイル一覧}

### 3.2 禁止領域
- フレームワークファイル（`.claude/`, `.handoff/`, `docs/core-doctrine.md` 等）
- 他の IMPLEMENT_REQUEST で担当中のファイル
- `.sd/` 直下（セッション記録等）

### 3.3 stack 情報（自動検出推奨）
{package.json から抽出: dependencies の主要フレームワーク、script コマンド}

## 4. Acceptance Criteria（完了条件）

以下を**すべて満たすまで review に進めない**:

- [ ] Section 0 の Quality Prerequisites 全項目通過
- [ ] `npm run build && npm test && npm run lint` 通過
- [ ] `npm run test:validate-data` 通過（VTD-001〜005）
- [ ] dev server 起動しブラウザで Section 2 に記述した画面が表示される
- [ ] スクリーンショット取得済み（`materials/images/{案件ID}/`）
- [ ] ユーザーが画面を見て承認（User Confirmation Gate）

## 5. テストケース
{WORK_ORDER のテスト要件から展開。ただし「テストのためのテスト」は書かない（柱3）}

実データで再現可能なもののみ記載すること。

## 6. コミット方針
{標準形式: `feat/fix/refactor: {要約}`}

## 7. 段取り（実装順序・柱4 Segmented Sequencing 準拠）

**推奨実装順序**:
1. **画面スケルトン作成**（HTML/CSS ベタ書きでOK） → ブラウザで表示確認
2. **本番データ（またはコピー）で直接動かす**（モック経由しない）
3. 実データで動かしながら型と実装を整える
4. 実データで再現したバグがあれば、そのバグを捕まえる最小テストのみ追加
5. dev server 起動 + 主要画面スクショ取得
6. ユーザー確認依頼（Section 4 の最後）

**逆順禁止**:
- ❌ 型定義 → interface → adapter → core → UI（柱2違反）
- ❌ テスト先行 → 実装 → 動作確認（柱3違反、Adapter層を除く）
- ❌ モックで動作確認 → 本番データ差し込み（柱3違反）

---

**ユーザー確認不要ゾーン**: Step 1-5 は AI が連続実行。ユーザー待ちなし。
**ユーザー確認ブロッキングゾーン**: Step 6 のみ。workflow-impl Step 6 で AskUserQuestion 発火。

失敗時は即停止して報告。省略は禁止。
