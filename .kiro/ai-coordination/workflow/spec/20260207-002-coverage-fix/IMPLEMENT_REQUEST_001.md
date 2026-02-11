# IMPLEMENT_REQUEST_001

## 案件情報
- **案件ID**: 20260207-002-coverage-fix
- **発行日**: 2026-02-07
- **発行者**: Claude Code
- **実装担当**: Gemini CLI
- **優先度**: P2（通常）

---

## 概要

テストカバレッジ改善と軽微な問題修正（4件）。現在branches 60.24%、functions 28.5%で閾値80%を下回っている。

---

## 実装タスク（4件）

### Task 1: GasEnv.tsのテスト拡充

**ファイル**: `tests/unit/env/GasEnv.test.ts`
**目的**: GasEnv.tsのカバレッジ改善（現在 statements 18%）

**現在のテスト（2件のみ）**:
- constructor が GAS環境外で throw する
- isAvailable() が false を返す

**追加すべきテスト**:
GAS環境をシミュレートするために、globalにモックを注入してから GasEnv を instantiate し、各メソッドが動作することを検証する。

```typescript
// テスト方針
describe('GasEnv in simulated GAS environment', () => {
  beforeEach(() => {
    // globalにGAS APIモックを注入
    (global as any).SpreadsheetApp = { /* mock */ };
    (global as any).Logger = { log: jest.fn(), getLog: jest.fn(() => ''), clear: jest.fn() };
    (global as any).PropertiesService = { /* mock */ };
    (global as any).UrlFetchApp = { /* mock */ };
    (global as any).Utilities = { /* mock */ };
    (global as any).LockService = { /* mock */ };
    (global as any).CacheService = { /* mock */ };
    (global as any).Session = { /* mock */ };
    (global as any).HtmlService = { /* mock */ };
    (global as any).DriveApp = { /* mock */ };
  });
  afterEach(() => {
    // 全モック削除
    delete (global as any).SpreadsheetApp;
    // ... 他も同様
  });

  it('should instantiate successfully in GAS environment', () => {
    const env = new GasEnv();
    expect(env).toBeDefined();
  });

  it('getSpreadsheetService() should return SpreadsheetApp', () => { ... });
  it('getLogger() should return logger wrapper', () => { ... });
  it('getLogger().log() should call Logger.log()', () => { ... });
  it('getLogger().getLogs() should parse log string', () => { ... });
  it('getPropertiesService() should return PropertiesService', () => { ... });
  it('getHttpClient() should return UrlFetchApp', () => { ... });
  it('getUtilities() should return Utilities', () => { ... });
  it('getLockService() should return LockService', () => { ... });
  it('getCacheService() should return CacheService', () => { ... });
  it('getSession() should return Session', () => { ... });
  it('getHtmlService() should return HtmlService', () => { ... });
  it('getDriveService() should return DriveApp', () => { ... });
  it('isAvailable() should return true in GAS environment', () => { ... });
});
```

**重要な注意**:
- `getLogger()` は単純な `as unknown as` ではなく、独自のラッパーオブジェクトを返す（lines 63-77）
- `getLogger().getLogs()` は `Logger.getLog()` の文字列を `\n` で分割して `{level, message, timestamp}` 配列に変換する
- これらのラッパー動作をテストすること

---

### Task 2: git-detector.tsのテスト作成

**ファイル**: `tests/unit/spec-driven/git-detector.test.ts`（新規作成）
**目的**: git-detector.tsのカバレッジ（現在 0%）

**対象クラス**: `GitDetector`（src/spec-driven/git-detector.ts）
- static クラス、全メソッドstatic
- テスト用の `_setMock*` メソッドと `_reset()` あり

**テストすべきメソッド**:

```typescript
import { GitDetector } from '../../../src/spec-driven/git-detector';

describe('GitDetector', () => {
  beforeEach(() => {
    GitDetector._reset();
  });

  describe('hasUncommittedChanges', () => {
    it('should return false when no changes', () => { ... });
    it('should return true when changed files exist', () => { ... });
    it('should return true when staged files exist', () => { ... });
    it('should return true when untracked files exist', () => { ... });
  });

  describe('getChangedFiles', () => {
    it('should return empty array by default', () => { ... });
    it('should return set mock changed files', () => { ... });
    it('should return a copy (not reference)', () => { ... });
  });

  describe('getStagedFiles', () => { /* 同様 */ });
  describe('getUntrackedFiles', () => { /* 同様 */ });

  describe('getFileDiff', () => {
    it('should return diff for changed files', () => { ... });
    it('should return diff for staged files', () => { ... });
    it('should return empty string for unknown files', () => { ... });
  });

  describe('_reset', () => {
    it('should clear all mock data', () => { ... });
  });
});
```

---

### Task 3: formatDate環境依存の修正（SD002側対応不要の場合はスキップ可）

**問題**: `MockUtilities.formatDate(date, 'UTC', 'yyyyMMdd')` がWindows環境で `2/7/2026` のような形式を返す。GAS本番では `20260207` を返すべき。

**調査ポイント**:
- この問題は `ga001-framework` 側のMockUtilities実装の問題
- SD002側で対応できるのはテスト側の検証パターンのみ
- **もし ga001-framework を修正できる場合**: `formatDate` でGAS形式の `yyyy`, `MM`, `dd` 等を正しくパースする
- **SD002側だけの対応**: テストで日付パターンを柔軟にマッチさせる（既に対応済み）

**判断**: ga001-framework側の修正が必要な場合、このタスクはスキップしてISSUEとして記録のみ。SD002側は対応済み。

---

### Task 4: nulファイルの削除

**ファイル**: プロジェクトルートの `nul`（60バイト、文字化けコンテンツ）
**原因**: Windows環境で `NUL` デバイスへのリダイレクトが誤ってファイル作成された
**対応**: 削除するだけ

```bash
rm D:/claudecode/sd002/nul
```

**注意**: `.gitignore` に `nul` を追加して再発防止を推奨。

---

## 技術的制約

1. **TypeScript strict mode** 必須
2. **ESLint エラー0件** を維持
3. **既存テスト42件を壊さない**
4. テスト内での `any` 使用は `global` モック注入時のみ許可
5. `console.log` 禁止（Logger経由のみ）

## 検証手順

```bash
# 1. TypeScript ビルドチェック
npx tsc --noEmit

# 2. テスト全パス確認
npx jest --no-coverage

# 3. カバレッジ確認
npx jest --coverage

# 4. ESLint
npx eslint "src/**/*.ts"

# 5. git commit
```

## 想定成果物

| # | ファイル | 操作 |
|---|---------|------|
| 1 | `tests/unit/env/GasEnv.test.ts` | 編集（テスト追加） |
| 2 | `tests/unit/spec-driven/git-detector.test.ts` | 新規作成 |
| 3 | `nul` | 削除 |
| 4 | `.gitignore` | 編集（nul追加、任意） |
