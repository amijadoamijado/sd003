/**
 * GAS Environment Implementation - SD002 Framework
 *
 * Google Apps Script本番環境での実装
 * GA001 v1.3.0のIEnvインターフェースを実装
 *
 * @version 2.0.0
 */

import type {
  IEnv,
  ISpreadsheetService,
  ILogger,
  IPropertiesService,
  IHttpClient,
  IUtilities,
  ILockService,
  ICacheService,
  ISession,
  IHtmlService,
  IDriveService,
} from 'ga001-framework';

/**
 * GasEnv: Google Apps Script本番環境実装
 *
 * 実際のGAS APIをIEnvインターフェースでラップし、
 * ビジネスロジックとの互換性を提供
 *
 * @example
 * ```typescript
 * // GAS環境でのみ動作
 * const env = new GasEnv();
 * const sheet = env.getSpreadsheetService().getActiveSpreadsheet().getActiveSheet();
 * sheet.appendRow(['Production', '456']);
 * ```
 */
export class GasEnv implements IEnv {
  /**
   * GasEnv constructor
   *
   * GAS環境が利用可能かチェックして初期化
   *
   * @throws {Error} GAS環境でない場合
   */
  constructor() {
    if (typeof SpreadsheetApp === 'undefined') {
      throw new Error('GasEnv can only be used in Google Apps Script environment');
    }
  }

  /**
   * Get spreadsheet service
   */
  getSpreadsheetService(): ISpreadsheetService {
    return SpreadsheetApp as unknown as ISpreadsheetService;
  }

  /**
   * Get logger instance
   */
  getLogger(): ILogger {
    return {
      log: (message: any) => Logger.log(message),
      info: (message: any) => Logger.log(`[INFO] ${message}`),
      warn: (message: any) => Logger.log(`[WARN] ${message}`),
      error: (message: any) => Logger.log(`[ERROR] ${message}`),
      getLogs: () => {
        const log = Logger.getLog();
        return log.split('\n').filter(Boolean).map((line: string) => ({
          level: 'log',
          message: line,
          timestamp: new Date(),
        }));
      },
      clear: () => Logger.clear(),
    };
  }

  /**
   * Get properties service
   */
  getPropertiesService(): IPropertiesService {
    return PropertiesService as unknown as IPropertiesService;
  }

  /**
   * Get HTTP client
   */
  getHttpClient(): IHttpClient {
    return UrlFetchApp as unknown as IHttpClient;
  }

  /**
   * Get utilities service
   */
  getUtilities(): IUtilities {
    return Utilities as unknown as IUtilities;
  }

  /**
   * Get lock service
   */
  getLockService(): ILockService {
    return LockService as unknown as ILockService;
  }

  /**
   * Get cache service
   */
  getCacheService(): ICacheService {
    return CacheService as unknown as ICacheService;
  }

  /**
   * Get session
   */
  getSession(): ISession {
    return Session as unknown as ISession;
  }

  /**
   * Get HTML service
   */
  getHtmlService(): IHtmlService {
    return HtmlService as unknown as IHtmlService;
  }

  /**
   * Get drive service
   */
  getDriveService(): IDriveService {
    return DriveApp as unknown as IDriveService;
  }

  /**
   * Check if GAS environment is available
   *
   * @returns GAS環境で動作可能な場合true
   */
  public static isAvailable(): boolean {
    return typeof SpreadsheetApp !== 'undefined';
  }
}

// GAS環境グローバル型宣言
declare const SpreadsheetApp: any;
declare const Logger: any;
declare const PropertiesService: any;
declare const UrlFetchApp: any;
declare const Utilities: any;
declare const LockService: any;
declare const CacheService: any;
declare const Session: any;
declare const HtmlService: any;
declare const DriveApp: any;
