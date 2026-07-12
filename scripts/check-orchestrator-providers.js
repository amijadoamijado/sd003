#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const configPath = path.resolve(root, process.argv[2] || 'config/orchestrator.providers.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
function resolveExecutable(command) {
  if (process.platform !== 'win32' || path.extname(command)) return { command, prefixArgs: [] };
  for (const directory of (process.env.PATH || '').split(path.delimiter)) {
    const shim = path.join(directory, `${command}.cmd`);
    if (!fs.existsSync(shim)) continue;
    const match = fs.readFileSync(shim, 'utf8').match(/"%dp0%\\([^"\r\n]+\.js)"/i);
    if (match) return { command: process.execPath, prefixArgs: [path.join(directory, match[1])] };
  }
  return { command, prefixArgs: [] };
}
let failed = false;
for (const [name, provider] of Object.entries(config.providers || {})) {
  const executable = resolveExecutable(provider.command);
  const result = spawnSync(executable.command, [...executable.prefixArgs, ...(provider.probeArgs || ['--version'])], { encoding: 'utf8', shell: false, timeout: 10000 });
  const ok = !result.error && result.status === 0;
  const version = String(result.stdout || result.stderr || result.error?.message || '').trim().split(/\r?\n/)[0];
  process.stdout.write(`${ok ? 'OK' : 'NG'} ${name}: ${version}\n`);
  if (!ok) failed = true;
}
process.exitCode = failed ? 1 : 0;
