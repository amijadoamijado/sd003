#!/usr/bin/env node

/**
 * Sync custom Codex prompts from Claude commands.
 *
 * Source:
 *   .claude/commands/ (all markdown files, recursive)
 *
 * Destination:
 *   ~/.codex/prompts/
 *   (override with CODEX_PROMPTS_DIR)
 *
 * Naming rules:
 * - Keep original relative path (e.g. kiro/spec-init.md)
 * - Add flat alias for nested files (e.g. kiro-spec-init.md)
 * - If a flat alias conflicts with an existing command, keep the first one
 */

import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const projectRoot = path.resolve(__dirname, '..');
const sourceRoot = path.join(projectRoot, '.claude', 'commands');
const targetRootInput = process.env.CODEX_PROMPTS_DIR?.trim();
const targetRoot = targetRootInput
  ? path.resolve(projectRoot, targetRootInput)
  : path.join(os.homedir(), '.codex', 'prompts');
const manifestPath = path.join(targetRoot, '.sync-manifest.json');

function toPosixPath(filePath) {
  return filePath.split(path.sep).join('/');
}

async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function listMarkdownFiles(rootDir, currentDir = rootDir) {
  const entries = await fs.readdir(currentDir, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const fullPath = path.join(currentDir, entry.name);
    if (entry.isDirectory()) {
      files.push(...await listMarkdownFiles(rootDir, fullPath));
      continue;
    }

    if (!entry.isFile() || !entry.name.endsWith('.md')) {
      continue;
    }

    files.push(toPosixPath(path.relative(rootDir, fullPath)));
  }

  return files.sort((a, b) => a.localeCompare(b));
}

async function pruneEmptyDirs(dirPath, stopDir) {
  const entries = await fs.readdir(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isDirectory()) {
      continue;
    }
    await pruneEmptyDirs(path.join(dirPath, entry.name), stopDir);
  }

  if (path.resolve(dirPath) === path.resolve(stopDir)) {
    return;
  }

  const remaining = await fs.readdir(dirPath);
  if (remaining.length === 0) {
    await fs.rmdir(dirPath);
  }
}

function addAlias(map, alias, source, collisions) {
  const existing = map.get(alias);
  if (!existing) {
    map.set(alias, source);
    return;
  }

  if (existing !== source) {
    collisions.push({
      alias,
      keptSource: existing,
      skippedSource: source
    });
  }
}

async function main() {
  if (!(await pathExists(sourceRoot))) {
    console.error(`Missing source directory: ${sourceRoot}`);
    process.exitCode = 1;
    return;
  }

  await fs.mkdir(targetRoot, { recursive: true });

  const sourceFiles = await listMarkdownFiles(sourceRoot);
  const promptMap = new Map();
  const collisions = [];

  for (const sourceRel of sourceFiles) {
    addAlias(promptMap, sourceRel, sourceRel, collisions);

    if (!sourceRel.includes('/')) {
      continue;
    }

    const flatAlias = sourceRel.replace(/\//g, '-');
    addAlias(promptMap, flatAlias, sourceRel, collisions);
  }

  let previousManifest = null;
  if (await pathExists(manifestPath)) {
    try {
      previousManifest = JSON.parse(await fs.readFile(manifestPath, 'utf8'));
    } catch {
      previousManifest = null;
    }
  }

  const previousFiles = Array.isArray(previousManifest?.files) ? previousManifest.files : [];
  const nextFiles = [...promptMap.keys()].sort((a, b) => a.localeCompare(b));

  // Remove stale generated prompts from previous sync runs only.
  const nextSet = new Set(nextFiles);
  for (const staleRel of previousFiles) {
    if (nextSet.has(staleRel)) {
      continue;
    }
    const stalePath = path.join(targetRoot, staleRel);
    if (await pathExists(stalePath)) {
      await fs.unlink(stalePath);
    }
  }

  let writeCount = 0;
  for (const [promptRel, sourceRel] of promptMap) {
    const sourcePath = path.join(sourceRoot, ...sourceRel.split('/'));
    const promptPath = path.join(targetRoot, ...promptRel.split('/'));
    await fs.mkdir(path.dirname(promptPath), { recursive: true });

    const content = await fs.readFile(sourcePath, 'utf8');
    const prevContent = await fs.readFile(promptPath, 'utf8').catch(() => null);

    if (prevContent === content) {
      continue;
    }

    await fs.writeFile(promptPath, content, 'utf8');
    writeCount += 1;
  }

  await pruneEmptyDirs(targetRoot, targetRoot);

  const manifest = {
    version: 1,
    generatedAt: new Date().toISOString(),
    sourceRoot: '.claude/commands',
    targetRoot,
    files: nextFiles,
    collisions
  };

  await fs.writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');

  console.log(`[sync-codex-prompts] source files: ${sourceFiles.length}`);
  console.log(`[sync-codex-prompts] target dir: ${targetRoot}`);
  console.log(`[sync-codex-prompts] generated prompts: ${nextFiles.length}`);
  console.log(`[sync-codex-prompts] files updated: ${writeCount}`);
  if (collisions.length > 0) {
    console.log(`[sync-codex-prompts] skipped flat aliases due to conflicts: ${collisions.length}`);
  }
}

main().catch((error) => {
  console.error('[sync-codex-prompts] failed:', error);
  process.exitCode = 1;
});
