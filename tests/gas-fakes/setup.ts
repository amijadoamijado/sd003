/**
 * gas-fakes Jest Setup
 *
 * Tier-2 テスト環境のセットアップファイル。
 * @mcpher/gas-fakes をインポートし、GASグローバル変数を注入する。
 *
 * ロード戦略:
 * - loadGasFakes() が唯一の可用性判定（実際の import() 成否で決定）
 * - require.resolve() はインストール有無の事前スクリーニングのみ（最適化）
 * - テストファイルは beforeAll で loadGasFakes() を呼び、戻り値で
 *   各テストの実行/スキップを制御する
 *
 * 注意:
 * - gas-fakes は ESM モジュール（"type": "module"）→ require() は使用不可
 * - require.resolve() はインストール確認のみ（ロード可能性は保証しない）
 * - Node.js >= 20.11.0 が必要
 * - PropertiesService/CacheService はローカルファイルで動作（GCP不要）
 * - SpreadsheetApp/DriveApp は GCP認証が必要な場合がある
 */

// 事前スクリーニング: パッケージ未インストール時は import() を試みない（最適化）
let gasFakesMayExist = false;

try {
  require.resolve('@mcpher/gas-fakes');
  gasFakesMayExist = true;
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
 * gas-fakes をロード済みかを返す（実際のグローバル注入完了後に true）
 */
export function isGasFakesLoaded(): boolean {
  return gasFakesLoaded;
}

/**
 * gas-fakes の動的インポートを実行し、成否を返す。
 * これが Tier-2 テスト可用性の唯一の判定基準。
 * テストファイルの beforeAll から呼び出し、戻り値で各テストをガードする。
 */
export async function loadGasFakes(): Promise<boolean> {
  if (gasFakesLoaded) return true;
  if (!gasFakesMayExist) return false;

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
