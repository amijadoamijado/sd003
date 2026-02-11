// tests/unit/spec-driven/git-detector.test.ts

import { GitDetector } from '../../../src/spec-driven/git-detector';

describe('GitDetector', () => {
  beforeEach(() => {
    GitDetector._reset();
  });

  describe('hasUncommittedChanges', () => {
    it('should return false when no changes', () => {
      expect(GitDetector.hasUncommittedChanges()).toBe(false);
    });

    it('should return true when changed files exist', () => {
      GitDetector._setMockChangedFiles(['file1.ts']);
      expect(GitDetector.hasUncommittedChanges()).toBe(true);
    });

    it('should return true when staged files exist', () => {
      GitDetector._setMockStagedFiles(['file2.ts']);
      expect(GitDetector.hasUncommittedChanges()).toBe(true);
    });

    it('should return true when untracked files exist', () => {
      GitDetector._setMockUntrackedFiles(['file3.ts']);
      expect(GitDetector.hasUncommittedChanges()).toBe(true);
    });
  });

  describe('getChangedFiles', () => {
    it('should return empty array by default', () => {
      expect(GitDetector.getChangedFiles()).toEqual([]);
    });

    it('should return set mock changed files', () => {
      const files = ['file1.ts', 'file2.ts'];
      GitDetector._setMockChangedFiles(files);
      expect(GitDetector.getChangedFiles()).toEqual(files);
    });

    it('should return a copy (not reference)', () => {
      const files = ['file1.ts'];
      GitDetector._setMockChangedFiles(files);
      const returnedFiles = GitDetector.getChangedFiles();
      returnedFiles.push('file2.ts');
      expect(GitDetector.getChangedFiles()).toEqual(['file1.ts']);
    });
  });

  describe('getStagedFiles', () => {
    it('should return empty array by default', () => {
      expect(GitDetector.getStagedFiles()).toEqual([]);
    });

    it('should return set mock staged files', () => {
      const files = ['file1.ts'];
      GitDetector._setMockStagedFiles(files);
      expect(GitDetector.getStagedFiles()).toEqual(files);
    });
  });

  describe('getUntrackedFiles', () => {
    it('should return empty array by default', () => {
      expect(GitDetector.getUntrackedFiles()).toEqual([]);
    });

    it('should return set mock untracked files', () => {
      const files = ['file1.ts'];
      GitDetector._setMockUntrackedFiles(files);
      expect(GitDetector.getUntrackedFiles()).toEqual(files);
    });
  });

  describe('getFileDiff', () => {
    it('should return diff for changed files', () => {
      GitDetector._setMockChangedFiles(['file1.ts']);
      const diff = GitDetector.getFileDiff('file1.ts');
      expect(diff).toContain('--- a/file1.ts');
      expect(diff).toContain('+++ b/file1.ts');
    });

    it('should return diff for staged files', () => {
      GitDetector._setMockStagedFiles(['file2.ts']);
      const diff = GitDetector.getFileDiff('file2.ts');
      expect(diff).toContain('--- a/file2.ts');
      expect(diff).toContain('+++ b/file2.ts');
    });

    it('should return empty string for unknown files', () => {
      expect(GitDetector.getFileDiff('unknown.ts')).toBe('');
    });
  });

  describe('_reset', () => {
    it('should clear all mock data', () => {
      GitDetector._setMockChangedFiles(['f1']);
      GitDetector._setMockStagedFiles(['f2']);
      GitDetector._setMockUntrackedFiles(['f3']);
      
      GitDetector._reset();
      
      expect(GitDetector.hasUncommittedChanges()).toBe(false);
      expect(GitDetector.getChangedFiles()).toEqual([]);
      expect(GitDetector.getStagedFiles()).toEqual([]);
      expect(GitDetector.getUntrackedFiles()).toEqual([]);
    });
  });
});
