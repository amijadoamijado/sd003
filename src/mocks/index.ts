/**
 * Mock Services Index - SD002 Framework
 *
 * GA001 v1.3.0のモックサービスを再エクスポート
 *
 * @version 2.0.0
 * @deprecated 直接 'ga001-framework' からインポートすることを推奨
 */

// ============================================================================
// GA001 Mock Services - 再エクスポート
// ============================================================================

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

  // GAS Environment Simulator
  GASEnvironmentSimulator,

  // Test Helpers
  GA001TestSetup,
  GA001TestDataFactory,
  setupGA001Matchers,
  GA001TestMatchers,
  createTestSetup,
  createSimulator,
} from 'ga001-framework';

export type {
  GA001TestSetupOptions,
  SimulatorOptions,
} from 'ga001-framework';

// ============================================================================
// SD002 Legacy Aliases - 後方互換性のため
// ============================================================================

// SpreadsheetApp
export { MockSpreadsheetApp as SpreadsheetApp } from 'ga001-framework';

// Logger
export { MockLogger as Logger } from 'ga001-framework';

// PropertiesService
export { MockPropertiesService as PropertiesService } from 'ga001-framework';

// UrlFetchApp
export { MockUrlFetchApp as UrlFetchApp } from 'ga001-framework';

// Utilities
export { MockUtilities as Utilities } from 'ga001-framework';

