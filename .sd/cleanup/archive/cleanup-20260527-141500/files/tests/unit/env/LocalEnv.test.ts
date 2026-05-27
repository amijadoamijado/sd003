// tests/unit/env/LocalEnv.test.ts

import { LocalEnv } from '../../../src/env/LocalEnv';
import {
  mockSpreadsheetApp,
  MockLogger,
  MockPropertiesService,
  MockUrlFetchApp,
  MockUtilities,
  DriveApp,
} from '../../../src/mocks';

describe('LocalEnv', () => {
  let env: LocalEnv;

  beforeEach(() => {
    // Reset all mock services before each test
    mockSpreadsheetApp.reset();
    MockLogger.reset();
    MockPropertiesService.reset();
    MockUrlFetchApp.reset();
    DriveApp.reset();
    // Ensure active spreadsheet has a default sheet after reset
    mockSpreadsheetApp.getActiveSpreadsheet().insertSheet('Sheet1');
    env = new LocalEnv();
  });

  it('should correctly instantiate all mock services', () => {
    expect(env.getSpreadsheetService()).toBeDefined();
    expect(env.getLogger()).toBeDefined();
    expect(env.getPropertiesService()).toBeDefined();
    expect(env.getHttpClient()).toBeDefined();
    expect(env.getDriveService()).toBeDefined();
    expect(env.getUtilities()).toBeDefined();
  });

  it('should provide access to SpreadsheetApp mock methods', () => {
    const spreadsheet = env.getSpreadsheetService().getActiveSpreadsheet();
    expect(spreadsheet.getName()).toBe('Mock Spreadsheet');
    expect(spreadsheet.getSheets().length).toBe(1);
  });

  it('should provide access to Logger mock methods', () => {
    env.getLogger().log('Test log');
    expect(MockLogger.getLogs()).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining('Test log') }),
      ])
    );
    env.getLogger().error('Test error');
    expect(MockLogger.getLogs()).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining('Test error') }),
      ])
    );
  });

  it('should provide access to PropertiesService mock methods', () => {
    env.getPropertiesService().getScriptProperties().setProperty('testKey', 'testValue');
    expect(env.getPropertiesService().getScriptProperties().getProperty('testKey')).toBe('testValue');
    expect(env.getPropertiesService().getScriptProperties().getProperties()).toEqual(
      expect.objectContaining({ testKey: 'testValue' })
    );
  });

  it('should provide access to UrlFetchApp mock methods', () => {
    MockUrlFetchApp.setMockResponse('http://example.com', 'Mock Response');
    const response = env.getHttpClient().fetch('http://example.com');
    expect(response.getContentText()).toBe('Mock Response');
  });

  it('should provide access to DriveApp mock methods', () => {
    const file = env.getDriveService().createFile('test.txt', 'hello');
    expect(file.getName()).toBe('test.txt');
    expect(env.getDriveService().getFileById(file.getId()).getBlob().getDataAsString()).toBe('hello');
  });

  it('should provide access to Utilities mock methods', () => {
    const uuid = MockUtilities.getUuid();
    expect(uuid).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
    const encoded = env.getUtilities().base64Encode('test');
    expect(encoded).toBe('dGVzdA==');
  });

  it('should reset all mock services when reset() is called', () => {
    env.getSpreadsheetService().create('temp');
    env.getLogger().log('some log');
    env.getPropertiesService().getScriptProperties().setProperty('key', 'value');
    env.getDriveService().createFile('file.txt', 'content');
    MockUrlFetchApp.setMockResponse('http://reset.com', 'reset content');

    env.reset();

    // Verify SpreadsheetApp reset
    expect(mockSpreadsheetApp.getActiveSpreadsheet().getName()).toBe('Mock Spreadsheet');

    // Verify Logger reset
    expect(MockLogger.getLogs()).toEqual([]);

    // Verify PropertiesService reset
    expect(MockPropertiesService.getScriptProperties().getProperty('key')).toBeNull();

    // Verify UrlFetchApp reset (throws when no mock response configured)
    expect(() => env.getHttpClient().fetch('http://reset.com')).toThrow();
  });
});
