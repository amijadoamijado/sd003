/**
 * gas-fakes Jest Setup
 *
 * Tier-2 テスト環境のセットアップファイル。
 * @mcpher/gas-fakes をインポートし、GASグローバル変数を注入する。
 *
 * ロード戦略:
 * - require.resolve() でパッケージの存在を同期的に確認（ESM互換）
 * - テストファイルの describeIfGasFakes() はこの結果を参照して describe/skip を決定
 * - 実際のグローバル注入は beforeAll 内で import() を使用（ESMパッケージ対応）
 *
 * 注意:
 * - gas-fakes は ESM モジュール（"type": "module"）→ require() は使用不可
 * - Node.js >= 20.11.0 が必要
 * - PropertiesService/CacheService はローカルファイルで動作（GCP不要）
 * - SpreadsheetApp/DriveApp は GCP認証が必要な場合がある
 */

// Phase 1: パッケージの存在を同期的に確認（require.resolve はESMパッケージでも動作）
// テストファイルのモジュール評価時に describeIfGasFakes() がこのフラグを参照する
let gasFakesAvailable = false;

try {
  require.resolve('@mcpher/gas-fakes');
  gasFakesAvailable = true;
} catch {
  // パッケージ未インストール - Tier-2テストはスキップされる
}

if (!gasFakesAvailable) {
  console.warn(
    '[gas-fakes setup] @mcpher/gas-fakes not found. Tier-2 tests will be skipped.'
  );
  console.warn(
    '[gas-fakes setup] Run "npm install @mcpher/gas-fakes" to enable.'
  );
}

// Phase 2: ESMパッケージを動的インポートでロード（beforeAll で実行）
// setupFiles はテストフレームワーク初期化前に実行されるため、
// beforeAll はここでは使えない。代わりにグローバルにフック関数を登録し、
// テストファイル側から呼び出す。
let gasFakesLoaded = false;

/**
 * gas-fakes をロード済みかを返す（実際のグローバル注入完了後に true）
 */
export function isGasFakesLoaded(): boolean {
  return gasFakesLoaded;
}

/**
 * gas-fakes パッケージが利用可能か（インストール済みか）を返す
 * テストファイルの describeIfGasFakes() がモジュール評価時に使用
 */
export function isGasFakesAvailable(): boolean {
  return gasFakesAvailable;
}

/**
 * gas-fakes の動的インポートを実行（ESM互換）
 * テストファイルの beforeAll から呼び出す
 */
export async function loadGasFakes(): Promise<boolean> {
  if (gasFakesLoaded) return true;
  if (!gasFakesAvailable) return false;

  try {
    // @ts-expect-error -- @mcpher/gas-fakes has no type declarations
    await import('@mcpher/gas-fakes');
    gasFakesLoaded = true;
    return true;
  } catch (error) {
    console.warn(
      '[gas-fakes setup] Failed to load @mcpher/gas-fakes:',
      (error as Error).message
    );
    return false;
  }
}
