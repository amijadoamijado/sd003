// src/spec-driven/git-detector.ts

/**
 * Mock implementation of a Git change detector.
 * In a real scenario, this would interact with the local Git repository
 * to detect changes, diffs, and other repository states.
 */
export class GitDetector {
  private static mockChangedFiles: string[] = [];
  private static mockStagedFiles: string[] = [];
  private static mockUntrackedFiles: string[] = [];

  /**
   * Simulates checking if there are any uncommitted changes in the repository.
   * @returns True if there are mock uncommitted changes, false otherwise.
   */
  static hasUncommittedChanges(): boolean {
    return (
      GitDetector.mockChangedFiles.length > 0 ||
      GitDetector.mockStagedFiles.length > 0 ||
      GitDetector.mockUntrackedFiles.length > 0
    );
  }

  /**
   * Simulates getting a list of changed files (modified but not staged).
   * @returns An array of mock changed file paths.
   */
  static getChangedFiles(): string[] {
    return [...GitDetector.mockChangedFiles];
  }

  /**
   * Simulates getting a list of staged files.
   * @returns An array of mock staged file paths.
   */
  static getStagedFiles(): string[] {
    return [...GitDetector.mockStagedFiles];
  }

  /**
   * Simulates getting a list of untracked files.
   * @returns An array of mock untracked file paths.
   */
  static getUntrackedFiles(): string[] {
    return [...GitDetector.mockUntrackedFiles];
  }

  /**
   * Simulates getting the diff for a specific file.
   * @param filePath The path of the file to get the diff for.
   * @returns A mock diff string.
   */
  static getFileDiff(filePath: string): string {
    if (GitDetector.mockChangedFiles.includes(filePath) || GitDetector.mockStagedFiles.includes(filePath)) {
      return "--- a/" + filePath + "\n+++ b/" + filePath + "\n@@ -1,3 +1,4 @@\n-old line\n+new line\n";
    }
    return '';
  }

  /**
   * Sets mock changed files for testing.
   * @param files An array of file paths to set as mock changed.
   */
  static _setMockChangedFiles(files: string[]): void {
    GitDetector.mockChangedFiles = files;
  }

  /**
   * Sets mock staged files for testing.
   * @param files An array of file paths to set as mock staged.
   */
  static _setMockStagedFiles(files: string[]): void {
    GitDetector.mockStagedFiles = files;
  }

  /**
   * Sets mock untracked files for testing.
   * @param files An array of file paths to set as mock untracked.
   */
  static _setMockUntrackedFiles(files: string[]): void {
    GitDetector.mockUntrackedFiles = files;
  }

  /**
   * Resets the mock state for testing purposes.
   */
  static _reset(): void {
    GitDetector.mockChangedFiles = [];
    GitDetector.mockStagedFiles = [];
    GitDetector.mockUntrackedFiles = [];
  }
}
