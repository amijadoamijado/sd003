// tests/integration/env-integration.test.ts

import { LocalEnv } from '../../src/env/LocalEnv';
import { GasEnv } from '../../src/env/GasEnv';
import { IEnv } from '../../src/interfaces/IEnv';
import { mockSpreadsheetApp, MockLogger } from '../../src/mocks';

// A simple business logic function that uses the IEnv interface
function processData(env: IEnv, data: string[][]): string {
  const spreadsheet = env.getSpreadsheetService().getActiveSpreadsheet();
  const sheet = spreadsheet.getActiveSheet();
  env.getLogger().log(`Processing data in spreadsheet: ${spreadsheet.getName()}, sheet: ${sheet.getName()}`);

  data.forEach(row => {
    sheet.appendRow(row);
  });

  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();
  env.getLogger().log(`Last row: ${lastRow}, Last column: ${lastCol}`);

  const range = sheet.getRange(1, 1, lastRow, lastCol);
  return JSON.stringify(range.getValues());
}

describe('Environment Integration', () => {
  beforeEach(() => {
    // Reset mocks for LocalEnv
    mockSpreadsheetApp.reset();
    MockLogger.reset();
    // Ensure active spreadsheet has a default sheet after reset
    mockSpreadsheetApp.getActiveSpreadsheet().insertSheet('Sheet1');
  });

  it('should allow business logic to run with LocalEnv', () => {
    const localEnv = new LocalEnv();
    const testData = [['Header1', 'Header2'], ['Data1', 'Data2']];

    const result = processData(localEnv, testData);

    expect(result).toBe(JSON.stringify([['Header1', 'Header2'], ['Data1', 'Data2']]));
    expect(localEnv.getSpreadsheetService().getActiveSpreadsheet().getActiveSheet().getLastRow()).toBe(2);
    expect(localEnv.getSpreadsheetService().getActiveSpreadsheet().getActiveSheet().getLastColumn()).toBe(2);

    const logs = MockLogger.getLogs();
    expect(logs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining('Processing data in spreadsheet: Mock Spreadsheet, sheet: Sheet1') }),
      ])
    );
    expect(logs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining('Last row: 2, Last column: 2') }),
      ])
    );
  });

  it('should ensure GasEnv throws error when used in local environment', () => {
    expect(() => new GasEnv()).toThrow('GasEnv can only be used in Google Apps Script environment');
  });
});
