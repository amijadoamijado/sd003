/**
 * Local Environment Implementation - SD002 Framework
 *
 * GA001 v1.3.0のLocalEnvを再エクスポート
 * ローカル開発・テスト環境でのGASモック機能を提供
 *
 * @version 2.0.0
 */

// GA001のLocalEnvを直接再エクスポート
export { LocalEnv } from 'ga001-framework';

// GA001のモックサービスも再エクスポート（テストで使用）
export {
  // Spreadsheet
  MockSpreadsheetApp,
  mockSpreadsheetApp,
  MockSpreadsheet,
  MockSheet,
  MockRange,

  // Properties
  MockPropertiesService,
  MockProperties,

  // URL Fetch
  MockUrlFetchApp,
  MockHttpResponse,

  // Utilities
  MockUtilities,
  MockDigestAlgorithm,

  // Other Services
  MockLogger,
  MockLockService,
  MockLock,
  MockSession,
  MockConsole,
  User,

  // Drive
  MockDriveApp,
  MockDriveFile,
  MockDriveFolder,
  MockDriveFileIterator,
  MockDriveFolderIterator,
  MockBlob,
  mockDriveApp,
  DriveApp,

  // Cache
  MockCacheService,
  MockCache,
  mockCacheService,
  CacheService,

  // HTML
  MockHtmlService,
  MockHtmlOutput,
  MockHtmlTemplate,
  mockHtmlService,
  HtmlService,
  XFrameOptionsMode,
  SandboxMode,

  // Gmail
  MockGmailApp,
  MockGmailMessage,
  MockGmailThread,
  MockGmailLabel,
  MockGmailDraft,
  MockGmailAttachment,
  mockGmailApp,
  GmailApp,

  // Script
  MockScriptApp,
  MockTrigger,
  MockTriggerBuilder,
  MockClockTriggerBuilder,
  MockSpreadsheetTriggerBuilder,
  MockMenu,
  mockScriptApp,
  ScriptApp,
  AuthMode,
  EventType,
  TriggerSource,
  Weekday,

  // Test Helpers
  GA001TestSetup,
  GA001TestDataFactory,
  setupGA001Matchers,
  GA001TestMatchers,
  createTestSetup,
  createSimulator,
} from 'ga001-framework';

// GA001タイプエイリアス
export type {
  GA001TestSetupOptions,
  SimulatorOptions,
} from 'ga001-framework';

/**
 * SD002 v1.x互換のLocalEnv
 *
 * @deprecated GA001のLocalEnvを直接使用してください
 *
 * @example
 * ```typescript
 * // 旧形式
 * import { LocalEnvLegacy } from './env/LocalEnv';
 * const env = new LocalEnvLegacy();
 * const sheet = env.spreadsheet.getActiveSheet();
 *
 * // 新形式（推奨）
 * import { LocalEnv } from 'ga001-framework';
 * const env = new LocalEnv();
 * const sheet = env.getSpreadsheetService().getActiveSpreadsheet().getActiveSheet();
 * ```
 */
export { LocalEnv as LocalEnvLegacy } from 'ga001-framework';
