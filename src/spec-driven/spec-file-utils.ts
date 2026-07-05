// src/spec-driven/spec-file-utils.ts

import * as fs from 'fs';
import * as path from 'path';

/**
 * Strips a leading UTF-8 BOM (U+FEFF) from file content, if present.
 *
 * SD003's own file standard is "UTF-8 with BOM + CRLF" (see CLAUDE.md), so any
 * front-matter parser in this codebase must tolerate a BOM at the start of the file.
 */
export function stripBom(content: string): string {
  return content.charCodeAt(0) === 0xfeff ? content.slice(1) : content;
}

/**
 * YAML front-matter delimiter pattern, tolerant of CRLF (`\r\n`) line endings.
 * Always apply {@link stripBom} to the raw file content before matching.
 */
export const FRONT_MATTER_PATTERN = /^---\r?\n([\s\S]*?)\r?\n---/;

/**
 * Extracts the raw YAML front-matter text from raw file content.
 * Tolerant of a leading UTF-8 BOM and of CRLF line endings.
 *
 * @returns The raw YAML text (without the `---` delimiters), or `null` if no
 * front matter block was found.
 */
export function extractFrontMatter(rawContent: string): string | null {
  const content = stripBom(rawContent);
  const match = content.match(FRONT_MATTER_PATTERN);
  return match ? match[1] : null;
}

/**
 * Recursively finds all `.md` files under `rootDir`.
 *
 * The canonical spec layout is `.sd/specs/{feature}/spec.md` (and sibling
 * requirements.md/tasks.md), so a flat, non-recursive `readdirSync` misses every
 * rule-compliant spec. This walks all subdirectories, skipping `history/` archive
 * folders (superseded/archived spec versions, see `.claude/rules/specs/spec-versioning.md`)
 * so they are not treated as live specs (which would otherwise trigger false
 * duplicate-ID / stale-traceability errors).
 *
 * @returns Full absolute paths (not just basenames), sorted for deterministic output.
 */
export function findSpecMarkdownFiles(rootDir: string): string[] {
  const results: string[] = [];

  function walk(dir: string): void {
    let entries: fs.Dirent[];
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }

    for (const entry of entries) {
      if (entry.isDirectory()) {
        if (entry.name === 'history') {
          continue; // archived spec versions are not live specs
        }
        walk(path.join(dir, entry.name));
      } else if (entry.isFile() && entry.name.toLowerCase().endsWith('.md')) {
        results.push(path.join(dir, entry.name));
      }
    }
  }

  walk(rootDir);
  return results.sort();
}
