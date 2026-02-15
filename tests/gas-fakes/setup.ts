/**
 * gas-fakes Jest Setup
 *
 * Tier-2 テスト環境のセットアップファイル。
 * @mcpher/gas-fakes をインポートし、GASグローバル変数を注入する。
 *
 * 重要: gas-fakes のインポートはモジュール初期化時（トップレベル）で行う。
 * テストファイルの describeIfGasFakes() がモジュール評価時に
 * globalThis.DriveApp 等の存在を確認するため、beforeAll では遅い。
 *
 * 注意:
 * - gas-fakes は ESM モジュール（"type": "module"）
 * - Node.js >= 20.11.0 が必要
 * - PropertiesService/CacheService はローカルファイルで動作（GCP不要）
 * - SpreadsheetApp/DriveApp は GCP認証が必要な場合がある
 *
 * 使用方法:
 *   npx jest --testPathPattern=tests/gas-fakes/ --setupFilesAfterSetup=./tests/gas-fakes/setup.ts
 */

// gas-fakes のグローバル変数注入をモジュール初期化時に実行
// テストファイルが評価される前にグローバルが存在する必要がある
let gasFakesLoaded = false;

try {
  // synchronous require for CJS compatibility at module init time
  require('@mcpher/gas-fakes');
  gasFakesLoaded = true;
} catch {
  console.warn(
    '[gas-fakes setup] Failed to load @mcpher/gas-fakes at module init.'
  );
  console.warn(
    '[gas-fakes setup] Tier-2 tests will be skipped. Run "gas-fakes init" to configure.'
  );
}

/** gas-fakes が正常にロードされたかを返す */
export function isGasFakesLoaded(): boolean {
  return gasFakesLoaded;
}
