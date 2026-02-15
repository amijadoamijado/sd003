/**
 * gas-fakes Jest Setup
 *
 * Tier-2 テスト環境のセットアップファイル。
 * @mcpher/gas-fakes をインポートし、GASグローバル変数を注入する。
 *
 * 注意:
 * - gas-fakes は ESM モジュール（"type": "module"）
 * - Node.js >= 20.11.0 が必要
 * - PropertiesService/CacheService はローカルファイルで動作（GCP不要）
 * - SpreadsheetApp/DriveApp は GCP認証が必要な場合がある
 *
 * 使用方法:
 *   npx jest --testPathPattern=tests/gas-fakes/
 *
 * GCP認証付き（フルTier-2テスト）:
 *   1. gas-fakes init でセットアップ
 *   2. gas-fakes auth で認証
 *   3. npx jest --testPathPattern=tests/gas-fakes/
 */

// gas-fakes のグローバル変数注入を試行
// ESM/CJS互換性のため動的インポートを使用
let gasFakesLoaded = false;

beforeAll(async () => {
  try {
    await import('@mcpher/gas-fakes');
    gasFakesLoaded = true;
  } catch (error) {
    console.warn(
      '[gas-fakes setup] Failed to load @mcpher/gas-fakes:',
      (error as Error).message
    );
    console.warn(
      '[gas-fakes setup] Tier-2 tests will be skipped. Run "gas-fakes init" to configure.'
    );
  }
});

/** gas-fakes が正常にロードされたかを返す */
export function isGasFakesLoaded(): boolean {
  return gasFakesLoaded;
}
