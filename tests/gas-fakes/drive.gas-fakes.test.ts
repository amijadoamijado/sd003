/**
 * DriveApp Tier-2 テスト (gas-fakes)
 *
 * gas-fakes による DriveApp の高忠実度テスト。
 * GA001モック（Tier-1）では再現できない実際のファイル操作を検証する。
 *
 * 前提条件:
 * - @mcpher/gas-fakes がインストール済み
 * - GCP認証済み（gas-fakes init + gas-fakes auth）
 * - Drive API が有効化済み（gas-fakes enable --edrive）
 *
 * 未認証時: テストは自動スキップされる
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

import { isGasFakesInstalled, loadGasFakes } from './setup';

const describeIfGasFakes = isGasFakesInstalled() ? describe : describe.skip;

describeIfGasFakes('DriveApp (gas-fakes Tier-2)', () => {

  beforeAll(async () => {
    await loadGasFakes();
  });

  describe('File operations', () => {
    it('should have DriveApp available as global', () => {
      expect((globalThis as any).DriveApp).toBeDefined();
    });

    it('should have createFile method', () => {
      expect(typeof (globalThis as any).DriveApp.createFile).toBe('function');
    });

    it('should create a text file', () => {
      const file = (globalThis as any).DriveApp.createFile(
        'test-gas-fakes.txt',
        'Hello from gas-fakes test',
        'text/plain'
      );
      expect(file).toBeDefined();
      expect(file.getName()).toBe('test-gas-fakes.txt');
      // Cleanup
      file.setTrashed(true);
    });

    it('should get file by ID', () => {
      const file = (globalThis as any).DriveApp.createFile(
        'get-by-id-test.txt',
        'content',
        'text/plain'
      );
      const fileId = file.getId();
      const retrieved = (globalThis as any).DriveApp.getFileById(fileId);
      expect(retrieved.getName()).toBe('get-by-id-test.txt');
      // Cleanup
      file.setTrashed(true);
    });

    it('should get file content as string', () => {
      const content = 'test content for blob';
      const file = (globalThis as any).DriveApp.createFile(
        'blob-test.txt',
        content,
        'text/plain'
      );
      const blob = file.getBlob();
      expect(blob.getDataAsString()).toBe(content);
      // Cleanup
      file.setTrashed(true);
    });
  });

  describe('Folder operations', () => {
    it('should have createFolder method', () => {
      expect(typeof (globalThis as any).DriveApp.createFolder).toBe('function');
    });

    it('should create a folder', () => {
      const folder = (globalThis as any).DriveApp.createFolder('gas-fakes-test-folder');
      expect(folder).toBeDefined();
      expect(folder.getName()).toBe('gas-fakes-test-folder');
      // Cleanup
      folder.setTrashed(true);
    });

    it('should get root folder', () => {
      const root = (globalThis as any).DriveApp.getRootFolder();
      expect(root).toBeDefined();
      expect(typeof root.getName).toBe('function');
    });
  });
});

// gas-fakes 未ロード時のフォールバックテスト
describe('DriveApp Tier-2 availability', () => {
  it('should report gas-fakes status', () => {
    const hasGasFakes = typeof (globalThis as any).DriveApp !== 'undefined';
    if (!hasGasFakes) {
      console.warn(
        '[Tier-2] DriveApp not available. ' +
        'Run "gas-fakes init && gas-fakes auth && gas-fakes enable --edrive" to enable Tier-2 tests.'
      );
    }
    expect(true).toBe(true);
  });
});
