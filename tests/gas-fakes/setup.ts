/**
 * gas-fakes Jest Setup
 *
 * Tier-2 テスト環境のセットアップファイル。
 * @mcpher/gas-fakes をインポートし、GASグローバル変数を注入する。
 *
 * ロード戦略（2層ゲート）:
 * - Layer 1 (sync): require.resolve() でインストール有無を判定
 *   → 未インストール時は describe.skip でスイートごとスキップ
 * - Layer 2 (async): loadGasFakes() で実際の import() を実行
 *   → インストール済みなのにロード失敗 = ランタイム異常 → throw で suite を fail
 *
 * テストの見え方:
 * - 未インストール → "skipped" (describe.skip)
 * - インストール済み＋ロード成功 → テスト実行
 * - インストール済み＋ロード失敗 → beforeAll throw → suite "failed"
 *
 * 注意:
 * - gas-fakes は ESM モジュール（"type": "module"）→ require() は使用不可
 * - require.resolve() はインストール確認のみ（ロード可能性は保証しない）
 * - Node.js >= 20.11.0 が必要
 * - PropertiesService/CacheService はローカルファイルで動作（GCP不要）
 * - SpreadsheetApp/DriveApp は GCP認証が必要な場合がある
 */

// Layer 1: パッケージのインストール有無を同期判定
// テストファイルが describe / describe.skip を決定するために使用
let gasFakesInstalled = false;

try {
  require.resolve('@mcpher/gas-fakes');
  gasFakesInstalled = true;
} catch {
  console.warn(
    '[gas-fakes setup] @mcpher/gas-fakes not found. Tier-2 tests will be skipped.'
  );
  console.warn(
    '[gas-fakes setup] Run "npm install @mcpher/gas-fakes" to enable.'
  );
}

let gasFakesLoaded = false;

/**
 * パッケージがインストール済みかを返す（require.resolve ベース）。
 * テストファイルのモジュール評価時に describe / describe.skip を選択するために使用。
 */
export function isGasFakesInstalled(): boolean {
  return gasFakesInstalled;
}

/**
 * Layer 2: gas-fakes の動的インポートを実行する。
 * - 未インストール時: 何もせず return（describe.skip 済みのため到達しない想定）
 * - インストール済み＋ロード成功: グローバル注入完了
 * - インストール済み＋ロード失敗: throw → beforeAll が失敗し suite 全体が fail
 */
export async function loadGasFakes(): Promise<void> {
  if (gasFakesLoaded) return;
  if (!gasFakesInstalled) return;

  // @ts-expect-error -- @mcpher/gas-fakes has no type declarations
  await import('@mcpher/gas-fakes');
  gasFakesLoaded = true;
}
