---
description: テスト基準（tests/配下適用）
paths:
  - "tests/**/*"
  - "**/*.test.ts"
  - "**/*.spec.ts"
---

# テスト基準

## カバレッジ要件
- ユニット: 80%以上
- 統合: 70%以上
- E2E: 主要フロー100%

## テスト構造
```typescript
describe('対象', () => {
  beforeEach(() => { /* セットアップ */ });

  describe('メソッド', () => {
    it('should 期待動作 when 条件', () => {
      // Arrange → Act → Assert
    });
  });
});
```

## 必須テストケース
- 正常系: 標準入力
- 異常系: エラーケース
- エッジ: 境界値、null/undefined

## GASテスト - 3層テスト戦略

| Tier | ツール | ディレクトリ | 速度 | 忠実度 | GCP認証 |
|------|--------|------------|------|--------|---------|
| Tier-1 | ローカルモック（GA001依存なし） | `tests/unit/`, `tests/integration/` | < 1s | 低 | 不要 |
| Tier-2 | @mcpher/gas-fakes | `tests/gas-fakes/` | < 30s | 中-高 | 一部必要 |
| Tier-3 | Antigravity E2E | 本番環境 | 分単位 | 最高 | 必要 |

### Tier-1: ローカルモック（ユニット）
- `tests/setup/gas-globals.ts` のローカルモックで疑似GAS環境
- GA001フレームワーク非依存（段階的排除方針）
- Core ビジネスロジックの高速検証

### Tier-2: gas-fakes（統合）
- `@mcpher/gas-fakes` による高忠実度GAS APIエミュレーション
- PropertiesService/CacheService はローカルファイルで動作（GCP不要）
- SpreadsheetApp/DriveApp は GCP認証が必要
- 実行: `npm run test:gas-fakes`
- gas-fakesセットアップ: `gas-fakes init && gas-fakes auth`

### Tier-3: Antigravity E2E（本番）
- 本番/ステージング環境でのUI確認
- **必ず `/workflow:test` で TEST_REQUEST を作成し、Antigravityに委譲する**
- Antigravity がブラウザベースで実行（Google認証済みブラウザ使用）
- Claude Codeが直接Playwrightを実行してはならない（GAS Web AppはGoogle認証が必要なため）
- ローカルWeb Appのテストには `webapp-testing` スキルを使用可（Anthropic公式）

### Tier選択基準
| テスト対象 | 推奨Tier | 実行者 |
|-----------|---------|--------|
| Core ビジネスロジック | Tier-1 | Claude Code |
| GAS API統合（Properties, Cache） | Tier-2 | Claude Code |
| GAS API統合（Sheets, Drive） | Tier-2（GCP認証時）/ Tier-3 | Claude Code / Antigravity |
| UI・フロー確認 | Tier-3 | **Antigravity**（`/workflow:test`） |
| ローカルWeb App | `webapp-testing` スキル | Claude Code |

## ⛔ テストの絶対原則

**テストの目的は「本番環境のエラーを発見し修正すること」であり、それ以外の目的でテストを書いてはならない。**

### テストとは何か
- 本番環境で実際に動くコードが正しく動作するかを検証する行為
- エラーやバグを発見し、修正につなげるための手段
- 本番データ・本番API・本番環境に対して実行されるべきもの

### テストとは何でないか
- カバレッジ数値を上げるための作業ではない
- 「テストを書いた」という実績を作るための作業ではない
- AIが「テスト完了」と報告するための儀式ではない

## ⛔ 禁止事項（違反即停止）

| # | 禁止事項 | 理由 |
|---|---------|------|
| 1 | **テストのためのテスト** | 本番のエラー発見に寄与しない |
| 2 | **モックデータでの検証** | 本番データの「汚さ」を再現できない |
| 3 | **フォールバック付きテスト**（失敗時にスキップ/デフォルト値で通過） | エラーを隠蔽する |
| 4 | **「こう動くはず」と仮定したテスト** | 実際の動作を確認していない |
| 5 | **数値達成のためだけのテスト** | 品質向上に寄与しない |
| 6 | **実装を読まずに書くテスト** | バグを検出できない |
| 7 | **空データ・ダミーデータでの検証** | 何も検証していない（oc001事故の原因） |
| 8 | **エラーを握りつぶす try-catch 付きテスト** | テスト失敗を隠す |
| 9 | **条件分岐で常にパスするテスト** | `if (env) skip` 等でテストが実行されない |

### 正しいテストの基準
- **本番環境のエラーを発見できるか？** — これが唯一の基準
- 本番データ（またはそのコピー）を使って検証する
- テストが失敗したら、それは修正すべきバグの発見である
- 80%未達でもエラーを発見できるテストを優先する

### 違反例
```typescript
// ❌ NG: テストのためのテスト（何も検証していない）
it('should work', () => {
  expect(true).toBe(true);
});

// ❌ NG: モックで本番を偽装（本番で壊れる）
it('should process data', () => {
  const mockData = { headers: [], rows: [] }; // 空のダミー
  expect(process(mockData)).toBeDefined();
});

// ❌ NG: フォールバックでエラー隠蔽
it('should handle API', () => {
  try {
    const result = callAPI();
    expect(result).toBeDefined();
  } catch {
    expect(true).toBe(true); // エラーを握りつぶし
  }
});

// ✅ OK: 本番データでエラーを発見するテスト
it('should parse actual spreadsheet headers', () => {
  const realData = getProductionDataCopy();
  const result = parseHeaders(realData);
  expect(result).toEqual(['日付', '品名', '数量', '単価']);
});
```

## 自動検証（Enforcement）

以下のルールは `npm run test:validate-data` で自動検証される:

| Rule | 検出対象 | 重要度 |
|------|---------|-------|
| VTD-001 | テストデータに空配列 `[]` | error |
| VTD-002 | 全値が空/デフォルトのオブジェクト | error |
| VTD-003 | `toBeDefined()` のみのアサーション | warning |
| VTD-004 | `expect(true).toBe(true)` パターン | error |
| VTD-005 | 値チェックなしのテストファイル | warning |

### 実行タイミング
- Ralph Loop停止判定時（自動） - stop hookがテスト成功前にvalidation実行
- Codexレビュー時（レビュー観点6で手動確認）
- `npm run test:validate-data`（任意実行）

### 違反例（自動検出される）
```typescript
// VTD-001: 空配列 → error
const testData = { headers: [], rows: [] };

// VTD-004: トートロジー → error
expect(true).toBe(true);

// VTD-003: toBeDefined()のみ → warning
expect(result).toBeDefined(); // これが唯一のアサーション
```
