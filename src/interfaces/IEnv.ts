/**
 * Environment Interface Pattern - SD002 Framework
 *
 * GA001 v1.3.0のインターフェースを再エクスポート
 * ビジネスロジックをGAS APIから完全分離するための統一インターフェース
 *
 * @version 2.0.0
 * @see https://github.com/anthropics/ga001-framework
 */

// ============================================================================
// GA001 Core Interfaces - 再エクスポート
// ============================================================================

export {
  // Main Environment Interface
  IEnv,

  // Spreadsheet Service
  ISpreadsheetService,
  ISpreadsheet,
  ISheet,
  IRange,

  // Logger
  ILogger,

  // Properties Service
  IPropertiesService,
  IProperties,

  // HTTP Client (UrlFetchApp)
  IHttpClient,
  IHttpResponse,
  IHttpRequestOptions,

  // Utilities
  IUtilities,
  DigestAlgorithm,
  Blob,

  // Lock Service
  ILockService,
  ILock,

  // Cache Service
  ICacheService,
  ICache,

  // Session
  ISession,
  IUser,

  // HTML Service
  IHtmlService,
  IHtmlOutput,
  IHtmlTemplate,

  // Drive Service
  IDriveService,
  IDriveFile,
  IDriveFolder,
  IDriveFileIterator,
  IDriveFolderIterator,

  // Helper Types
  IResult,
  IAsyncResult,
  EnvType,
  IEnvConfig,
} from 'ga001-framework';

