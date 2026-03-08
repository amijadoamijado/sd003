/**
 * SpreadsheetApp Tier-2 テスト (gas-fakes)
 *
 * gas-fakes による SpreadsheetApp の高忠実度テスト。
 * GA001モック（Tier-1）では再現できない本番相当の動作を検証する。
 *
 * 前提条件:
 * - @mcpher/gas-fakes がインストール済み
 * - GCP認証済み（gas-fakes init + gas-fakes auth）
 * - gasfakes.json が設定済み
 *
 * 未認証時: テストは自動スキップされる
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

import { isGasFakesInstalled, loadGasFakes } from './setup';

const describeIfGasFakes = isGasFakesInstalled() ? describe : describe.skip;

describeIfGasFakes('SpreadsheetApp (gas-fakes Tier-2)', () => {

  beforeAll(async () => {
    await loadGasFakes();
  });

  describe('Spreadsheet operations', () => {
    it('should have SpreadsheetApp available as global', () => {
      expect((globalThis as any).SpreadsheetApp).toBeDefined();
    });

    it('should have create method', () => {
      expect(typeof (globalThis as any).SpreadsheetApp.create).toBe('function');
    });

    it('should create a new spreadsheet', () => {
      const ss = (globalThis as any).SpreadsheetApp.create('Test Spreadsheet');
      expect(ss).toBeDefined();
      expect(ss.getName()).toBe('Test Spreadsheet');
    });
  });

  describe('Sheet operations', () => {
    let ss: any;

    beforeEach(() => {
      ss = (globalThis as any).SpreadsheetApp.create('Sheet Test');
    });

    it('should get sheets from spreadsheet', () => {
      const sheets = ss.getSheets();
      expect(Array.isArray(sheets)).toBe(true);
      expect(sheets.length).toBeGreaterThan(0);
    });

    it('should insert a new sheet', () => {
      const initialCount = ss.getSheets().length;
      ss.insertSheet('New Sheet');
      expect(ss.getSheets().length).toBe(initialCount + 1);
    });

    it('should get sheet by name', () => {
      const sheet = ss.getSheetByName('Sheet1');
      expect(sheet).toBeDefined();
    });
  });

  describe('Range operations', () => {
    let sheet: any;

    beforeEach(() => {
      const ss = (globalThis as any).SpreadsheetApp.create('Range Test');
      sheet = ss.getSheets()[0];
    });

    it('should read and write single cell value', () => {
      const range = sheet.getRange('A1');
      range.setValue('Hello');
      expect(range.getValue()).toBe('Hello');
    });

    it('should read and write range by A1 notation', () => {
      const range = sheet.getRange('A1:B2');
      range.setValues([
        ['A', 'B'],
        ['C', 'D'],
      ]);
      const values = range.getValues();
      expect(values).toEqual([
        ['A', 'B'],
        ['C', 'D'],
      ]);
    });

    it('should handle getRange with row/col/numRows/numCols', () => {
      const range = sheet.getRange(1, 1, 2, 2);
      range.setValues([
        [1, 2],
        [3, 4],
      ]);
      const values = range.getValues();
      expect(values).toEqual([
        [1, 2],
        [3, 4],
      ]);
    });

    it('should handle getValues returning 2D array', () => {
      sheet.getRange('A1').setValue('test');
      const values = sheet.getRange('A1:A1').getValues();
      expect(Array.isArray(values)).toBe(true);
      expect(Array.isArray(values[0])).toBe(true);
    });
  });
});

// gas-fakes 未ロード時のフォールバックテスト
describe('SpreadsheetApp Tier-2 availability', () => {
  it('should report gas-fakes status', () => {
    const hasGasFakes = typeof (globalThis as any).SpreadsheetApp !== 'undefined';
    if (!hasGasFakes) {
      console.warn(
        '[Tier-2] SpreadsheetApp not available. ' +
        'Run "gas-fakes init && gas-fakes auth" to enable Tier-2 tests.'
      );
    }
    expect(typeof hasGasFakes).toBe('boolean');
  });
});
