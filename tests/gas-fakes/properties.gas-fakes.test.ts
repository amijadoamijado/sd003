/**
 * PropertiesService Tier-2 テスト (gas-fakes)
 *
 * gas-fakes による PropertiesService の高忠実度テスト。
 * PropertiesService はローカルファイルストレージで動作するため、
 * GCP認証なしでもテスト可能（STORE_TYPE=FILE）。
 *
 * 前提条件:
 * - @mcpher/gas-fakes がインストール済み
 * - gasfakes.json で STORE_TYPE=FILE を設定（デフォルト）
 *
 * 未ロード時: テストは自動スキップされる
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

import { isGasFakesAvailable, loadGasFakes } from './setup';

const describeIfGasFakes = isGasFakesAvailable() ? describe : describe.skip;

describeIfGasFakes('PropertiesService (gas-fakes Tier-2)', () => {

  beforeAll(async () => {
    await loadGasFakes();
  });

  describe('ScriptProperties', () => {
    let props: any;

    beforeEach(() => {
      props = (globalThis as any).PropertiesService.getScriptProperties();
    });

    afterEach(() => {
      // クリーンアップ: テスト用プロパティを削除
      try {
        props.deleteProperty('test-key');
        props.deleteProperty('key1');
        props.deleteProperty('key2');
      } catch {
        // ignore cleanup errors
      }
    });

    it('should set and get a property', () => {
      props.setProperty('test-key', 'test-value');
      expect(props.getProperty('test-key')).toBe('test-value');
    });

    it('should return null for non-existent property', () => {
      expect(props.getProperty('non-existent-key-xyz')).toBeNull();
    });

    it('should delete a property', () => {
      props.setProperty('test-key', 'to-delete');
      props.deleteProperty('test-key');
      expect(props.getProperty('test-key')).toBeNull();
    });

    it('should set and get multiple properties', () => {
      props.setProperties({
        'key1': 'value1',
        'key2': 'value2',
      });
      const allProps = props.getProperties();
      expect(allProps['key1']).toBe('value1');
      expect(allProps['key2']).toBe('value2');
    });

    it('should overwrite existing property', () => {
      props.setProperty('test-key', 'original');
      props.setProperty('test-key', 'updated');
      expect(props.getProperty('test-key')).toBe('updated');
    });
  });

  describe('UserProperties', () => {
    it('should have getUserProperties method', () => {
      expect(typeof (globalThis as any).PropertiesService.getUserProperties).toBe('function');
    });

    it('should set and get a user property', () => {
      const userProps = (globalThis as any).PropertiesService.getUserProperties();
      userProps.setProperty('user-test', 'user-value');
      expect(userProps.getProperty('user-test')).toBe('user-value');
      userProps.deleteProperty('user-test');
    });
  });

  describe('DocumentProperties', () => {
    it('should have getDocumentProperties method', () => {
      expect(typeof (globalThis as any).PropertiesService.getDocumentProperties).toBe('function');
    });
  });
});

// gas-fakes 未ロード時のフォールバックテスト
describe('PropertiesService Tier-2 availability', () => {
  it('should report gas-fakes status', () => {
    const hasGasFakes = typeof (globalThis as any).PropertiesService !== 'undefined';
    if (!hasGasFakes) {
      console.warn(
        '[Tier-2] PropertiesService not available. ' +
        'Run "gas-fakes init" to enable Tier-2 tests (GCP auth not required for FILE store).'
      );
    }
    expect(true).toBe(true);
  });
});
