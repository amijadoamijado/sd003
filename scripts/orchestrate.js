#!/usr/bin/env node

// Cross-platform npm entrypoint. npm on some Windows installations does not
// forward arguments through compound package scripts reliably.
const { spawnSync } = require('child_process');
const path = require('path');

const root = path.resolve(__dirname, '..');
function normalizeArgs(args) {
  if (args.includes('--scenario') || args.includes('-s')) return args;
  const scenarioIndex = args.findIndex(arg => !arg.startsWith('-') && arg.toLowerCase().endsWith('.json'));
  if (scenarioIndex < 0) return args;
  return [...args.slice(0, scenarioIndex), '--scenario', args[scenarioIndex], ...args.slice(scenarioIndex + 1)];
}

const tsc = path.join(root, 'node_modules', 'typescript', 'bin', 'tsc');
const build = spawnSync(process.execPath, [tsc], { cwd: root, stdio: 'inherit', shell: false });
if (build.status !== 0) process.exit(build.status || 1);

const cli = path.join(root, 'dist', 'cli', 'index.js');
const run = spawnSync(process.execPath, [cli, 'orchestrate', ...normalizeArgs(process.argv.slice(2))], { cwd: root, stdio: 'inherit', shell: false });
process.exit(run.status || 0);

module.exports = { normalizeArgs };
