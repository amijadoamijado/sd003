#!/usr/bin/env node

/**
 * SD003 Framework - Postinstall Script
 *
 * インストール後の初期化処理
 */

import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';

console.log('SD003 Framework - Postinstall');
console.log('==============================\n');

// .kiro ディレクトリ構造の作成
const kiroStructure = [
  '.kiro',
  '.kiro/specs',
  '.kiro/settings',
  '.kiro/traceability',
  '.kiro/ids',
  '.kiro/backups'
];

console.log('Creating .kiro directory structure...');
kiroStructure.forEach(dir => {
  const dirPath = path.join(process.cwd(), dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`  ✓ Created: ${dir}`);
  } else {
    console.log(`  - Exists: ${dir}`);
  }
});

console.log('\nSyncing Codex prompts from Claude commands...');
try {
  const syncScriptPath = path.join(process.cwd(), 'scripts', 'sync-codex-prompts.js');
  execFileSync(process.execPath, [syncScriptPath], { stdio: 'inherit' });
} catch (error) {
  console.warn('  ⚠ Failed to sync Codex prompts. You can run: npm run sync:codex-prompts');
}

console.log('\n✅ SD003 Framework installation complete!');
console.log('\nNext steps:');
console.log('  1. npm run build    - Build TypeScript');
console.log('  2. npm test         - Run tests');
console.log('  3. npm run dev      - Start development mode');
console.log('\nDocumentation:');
console.log('  - README.md              - Quick start guide');
console.log('  - CLAUDE.md              - Project guidelines');
console.log('  - docs/architecture.md   - Architecture design');
console.log('  - docs/integration-guide.md - Integration guide');
console.log('\n');
