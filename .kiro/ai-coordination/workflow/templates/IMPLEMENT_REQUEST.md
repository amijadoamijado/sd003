# 実装指示: {タスク名}

## メタデータ
| 項目 | 値 |
|------|-----|
| 案件ID | {YYYYMMDD-NNN-slug} |
| タスク番号 | {NNN} |
| 発行日時 | YYYY-MM-DD HH:MM |
| 発行者 | Claude Code |
| 宛先 | Gemini CLI |
| 発注書 | ./WORK_ORDER.md |
| ステータス | Pending / In Progress / Completed / Blocked |

## 1. 対象ブランチ

| 項目 | 値 |
|------|-----|
| 作業ブランチ | `feature/{案件ID}/{タスク番号}-{slug}` |
| ベースブランチ | `master` |
| マージ先 | `master` |

```bash
# ブランチ作成コマンド
git checkout -b feature/{案件ID}/{タスク番号}-{slug}
```

## 2. 実装タスク概要

**タスク番号**: {NNN}
**タスク名**: {発注書のタスク一覧から}

### 2.1 目的
{このタスクで達成すべきこと}

### 2.2 依存タスク
| 依存タスク番号 | 状態 | 備考 |
|--------------|------|------|
| {NNN} | Completed | {必要に応じて} |

## 3. 実装範囲

### 3.1 変更可能ファイル
| ファイルパス | アクション | 説明 |
|------------|----------|------|
| `src/xxx/yyy.ts` | Create | {新規作成の理由} |
| `src/aaa/bbb.ts` | Modify | {変更箇所の概要} |
| `tests/xxx.test.ts` | Create | {テストファイル} |

### 3.2 禁止領域（変更不可）
| ファイル/ディレクトリ | 理由 |
|---------------------|------|
| `CLAUDE.md` | フレームワーク設定 |
| `.kiro/specs/` | 仕様書は変更不可 |
| `src/env/IEnv.ts` | 共通インターフェース |

### 3.3 参照のみ（読み取り可、変更不可）
| ファイルパス | 参照理由 |
|------------|---------|
| `.kiro/specs/{feature}/design.md` | 設計仕様の確認 |
| `src/types/*.ts` | 型定義の確認 |

## 4. 追加・変更仕様（差分）

### 4.1 機能仕様
```typescript
/**
 * {関数/クラス名}
 *
 * @description {機能の説明}
 * @param {paramName} - {パラメータ説明}
 * @returns {戻り値説明}
 * @throws {例外説明}
 *
 * @example
 * // 使用例
 * const result = functionName(param);
 */
```

### 4.2 インターフェース定義
```typescript
interface INewInterface {
  field1: string;
  field2: number;
  method1(param: string): void;
}
```

### 4.3 ビジネスルール実装
| ルールID | 実装方法 | 実装箇所 |
|---------|---------|---------|
| BR-001 | {具体的な実装方法} | `src/xxx.ts:functionName` |

## 5. 受け入れテスト

### 5.1 自動テスト
```bash
# テスト実行コマンド
npm test -- --testPathPattern="tests/{対象テストファイル}"
npm run lint
npm run build
```

### 5.2 手動確認項目
| 確認ID | 確認内容 | 手順 | 期待結果 |
|--------|---------|------|---------|
| MC-001 | {確認内容} | 1. xxx 2. yyy | {期待結果} |

### 5.3 テストケース
| テストID | テスト名 | 入力 | 期待出力 | 分類 |
|---------|---------|------|---------|------|
| UT-{NNN}-001 | {テスト名} | {入力} | {期待出力} | 正常系/異常系/エッジ |

## 6. コミット方針

### 6.1 コミットメッセージ形式
```
{type}({scope}): {summary}

{body}

Refs: {案件ID}#{タスク番号}
```

### 6.2 許可されるtype
| type | 用途 |
|------|------|
| feat | 新機能 |
| fix | バグ修正 |
| test | テスト追加 |
| refactor | リファクタリング |
| docs | ドキュメント |

### 6.3 コミット粒度
- 1コミット = 1論理的変更
- テストは実装と同じコミットに含める
- 動作確認してからコミット

## 7. 注意事項

### 7.1 技術的制約
- [ ] Node.js API禁止（`fs`, `path`, `process`）
- [ ] GAS API直接参照禁止（Env Interface経由のみ）
- [ ] TypeScript strictモード必須
- [ ] ESLintエラー0件必須

### 7.2 品質基準
- [ ] カバレッジ80%以上
- [ ] JSDocコメント必須（公開API）
- [ ] エラーハンドリング完備

### 7.3 特記事項
{このタスク固有の注意点}

## 8. 完了報告フォーマット

実装完了時、以下の形式で報告:

```markdown
## 実装完了報告

### 変更ファイル
| ファイル | アクション | 行数 |
|---------|----------|------|

### テスト結果
- ユニットテスト: X件パス / X件
- カバレッジ: XX%

### 検証コマンド結果
```bash
npm test
npm run lint
npm run build
```

### 次のアクション
- Codexレビュー依頼
```

---
**発行日時**: YYYY-MM-DD HH:MM
**発行者**: Claude Code
