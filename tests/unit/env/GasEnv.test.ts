// tests/unit/env/GasEnv.test.ts

import { GasEnv } from '../../../src/env/GasEnv';

describe('GasEnv', () => {
  describe('In non-GAS environment', () => {
    it('should throw an error if instantiated outside of a GAS environment', () => {
      // In a Node.js environment, SpreadsheetApp will be undefined
      expect(() => new GasEnv()).toThrow('GasEnv can only be used in Google Apps Script environment');
    });

    it('isAvailable() should return false outside of a GAS environment', () => {
      expect(GasEnv.isAvailable()).toBe(false);
    });
  });

  describe('In simulated GAS environment', () => {
    const mockLogger = {
      log: jest.fn(),
      getLog: jest.fn(() => 'line1\nline2'),
      clear: jest.fn(),
    };

    beforeEach(() => {
      // globalにGAS APIモックを注入
      (global as any).SpreadsheetApp = {
        getActiveSpreadsheet: jest.fn(),
      };
      (global as any).Logger = mockLogger;
      (global as any).PropertiesService = {
        getScriptProperties: jest.fn(),
      };
      (global as any).UrlFetchApp = {
        fetch: jest.fn(),
      };
      (global as any).Utilities = {
        formatDate: jest.fn(),
      };
      (global as any).LockService = {
        getScriptLock: jest.fn(),
      };
      (global as any).CacheService = {
        getScriptCache: jest.fn(),
      };
      (global as any).Session = {
        getActiveUser: jest.fn(),
      };
      (global as any).HtmlService = {
        createHtmlOutput: jest.fn(),
      };
      (global as any).DriveApp = {
        getFileById: jest.fn(),
      };
    });

    afterEach(() => {
      // 全モック削除
      delete (global as any).SpreadsheetApp;
      delete (global as any).Logger;
      delete (global as any).PropertiesService;
      delete (global as any).UrlFetchApp;
      delete (global as any).Utilities;
      delete (global as any).LockService;
      delete (global as any).CacheService;
      delete (global as any).Session;
      delete (global as any).HtmlService;
      delete (global as any).DriveApp;
      jest.clearAllMocks();
    });

    it('should instantiate successfully in GAS environment', () => {
      const env = new GasEnv();
      expect(env).toBeDefined();
    });

    it('getSpreadsheetService() should return SpreadsheetApp', () => {
      const env = new GasEnv();
      expect(env.getSpreadsheetService()).toBe((global as any).SpreadsheetApp);
    });

    it('getLogger() should return logger wrapper', () => {
      const env = new GasEnv();
      const logger = env.getLogger();
      expect(logger).toBeDefined();

      logger.log('test log');
      expect(mockLogger.log).toHaveBeenCalledWith('test log');

      logger.info('test info');
      expect(mockLogger.log).toHaveBeenCalledWith('[INFO] test info');

      logger.warn('test warn');
      expect(mockLogger.log).toHaveBeenCalledWith('[WARN] test warn');

      logger.error('test error');
      expect(mockLogger.log).toHaveBeenCalledWith('[ERROR] test error');

      const logs = logger.getLogs();
      expect(logs).toHaveLength(2);
      expect(logs[0].message).toBe('line1');
      expect(logs[1].message).toBe('line2');

      logger.clear();
      expect(mockLogger.clear).toHaveBeenCalled();
    });

    it('getPropertiesService() should return PropertiesService', () => {
      const env = new GasEnv();
      expect(env.getPropertiesService()).toBe((global as any).PropertiesService);
    });

    it('getHttpClient() should return UrlFetchApp', () => {
      const env = new GasEnv();
      expect(env.getHttpClient()).toBe((global as any).UrlFetchApp);
    });

    it('getUtilities() should return Utilities', () => {
      const env = new GasEnv();
      expect(env.getUtilities()).toBe((global as any).Utilities);
    });

    it('getLockService() should return LockService', () => {
      const env = new GasEnv();
      expect(env.getLockService()).toBe((global as any).LockService);
    });

    it('getCacheService() should return CacheService', () => {
      const env = new GasEnv();
      expect(env.getCacheService()).toBe((global as any).CacheService);
    });

    it('getSession() should return Session', () => {
      const env = new GasEnv();
      expect(env.getSession()).toBe((global as any).Session);
    });

    it('getHtmlService() should return HtmlService', () => {
      const env = new GasEnv();
      expect(env.getHtmlService()).toBe((global as any).HtmlService);
    });

    it('getDriveService() should return DriveApp', () => {
      const env = new GasEnv();
      expect(env.getDriveService()).toBe((global as any).DriveApp);
    });

    it('isAvailable() should return true in GAS environment', () => {
      expect(GasEnv.isAvailable()).toBe(true);
    });
  });
});