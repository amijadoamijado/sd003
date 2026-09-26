#!/usr/bin/env node
// realign-settings.mjs - bring a KEPT .claude/settings.json up to the framework template
// without losing what the project added on its own.
//
// Why: projects list .claude/settings.json in .sd003-keep because bd init (and similar
// tools) add their own hooks to it. Keeping it froze the framework wiring as well, so
// every upgrade left retired hooks registered and new hooks unregistered, and the fix
// was a hand edit of settings.json - which Claude Code's auto mode refuses as
// self-modification (er001 2026-09-26: two permission round trips per upgrade).
//
// Merge rule (deterministic, no guessing):
//   - hooks: start from the template. From the target, keep every hook command that is
//     NOT framework-owned and append it to the same event (same matcher group when one
//     exists). Framework-owned = references scripts/run-hook.js, scripts/orchestrator-guard.js,
//     a hook file shipped in <source>/.claude/hooks/, or a retired framework hook.
//   - env: target keys kept, template keys win.
//   - permissions: allow/deny/ask are unions (template first); other keys from target.
//   - any other top-level key: target value kept, template value used when target lacks it.
//
// Usage: node realign-settings.mjs <target> <source> [--dry-run] [--backup-dir <dir>]
// Exit: 0 = done (changed or already aligned), 1 = error (target left untouched).

import fs from 'node:fs';
import path from 'node:path';

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const bIdx = args.indexOf('--backup-dir');
const backupDir = bIdx >= 0 ? args[bIdx + 1] : null;
const [target, source] = args.filter((a, i) => !a.startsWith('--') && (bIdx < 0 || i !== bIdx + 1));

if (!target || !source) {
  console.error('usage: node realign-settings.mjs <target> <source> [--dry-run] [--backup-dir <dir>]');
  process.exit(1);
}

const RETIRED_HOOKS = [
  'workflow-gate.sh', 'workflow-state-tracker.sh',
  'sd002-stop-hook.sh', 'sd002-stop-hook.ps1', 'sd002-stop-hook-endgame.sh', 'sd002-stop-hook-endgame.ps1',
];

const readJson = (p) => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));

const settingsPath = path.join(target, '.claude', 'settings.json');
const templatePath = path.join(source, '.claude', 'skills', 'sd-deploy', 'templates', 'settings.json.template');

let current, template;
try {
  template = readJson(templatePath);
} catch (e) {
  console.error(`  [realign] template unreadable: ${templatePath} (${e.message})`);
  process.exit(1);
}
if (!fs.existsSync(settingsPath)) {
  console.log('  [realign] target has no .claude/settings.json - nothing to merge (deploy writes the template)');
  process.exit(0);
}
try {
  current = readJson(settingsPath);
} catch (e) {
  console.error(`  [realign] target settings.json is not valid JSON, left untouched: ${e.message}`);
  process.exit(1);
}

let sourceHooks = [];
try {
  sourceHooks = fs.readdirSync(path.join(source, '.claude', 'hooks'));
} catch { /* no hooks dir: only launcher/retired rules apply */ }
const frameworkHookFiles = new Set([...sourceHooks, ...RETIRED_HOOKS]);

function isFrameworkOwned(command) {
  if (/scripts\/(run-hook|orchestrator-guard)\.js/.test(command)) return true;
  const m = command.match(/\.claude\/hooks\/([^"'\s]+)/);
  return Boolean(m && frameworkHookFiles.has(m[1]));
}

const templateHooksText = JSON.stringify(template.hooks ?? {});
const merged = structuredClone(template);
const kept = [];
const dropped = [];

for (const [event, groups] of Object.entries(current.hooks ?? {})) {
  for (const group of groups ?? []) {
    for (const hook of group.hooks ?? []) {
      const cmd = hook.command ?? '';
      if (isFrameworkOwned(cmd)) {
        // Report only hooks the template no longer wires anywhere (= retired);
        // the rest are simply replaced by the template's current wiring.
        const script = cmd.match(/\.claude\/hooks\/([^"'\s]+)/)?.[1];
        if (script && !templateHooksText.includes(`/.claude/hooks/${script}`)) dropped.push(`${event}: ${cmd}`);
        continue;
      }
      merged.hooks ??= {};
      merged.hooks[event] ??= [];
      const already = merged.hooks[event].some((g) => (g.hooks ?? []).some((h) => h.command === cmd));
      if (already) continue;
      const matcher = group.matcher;
      let dest = merged.hooks[event].find((g) => g.matcher === matcher && g.__fromTarget);
      if (!dest) {
        dest = matcher === undefined ? { hooks: [] } : { hooks: [], matcher };
        Object.defineProperty(dest, '__fromTarget', { value: true, enumerable: false });
        merged.hooks[event].push(dest);
      }
      dest.hooks.push(hook);
      kept.push(`${event}: ${cmd}`);
    }
  }
}

merged.env = { ...(current.env ?? {}), ...(template.env ?? {}) };
if (current.permissions || template.permissions) {
  const perms = { ...(current.permissions ?? {}) };
  for (const key of ['allow', 'deny', 'ask']) {
    const union = [...new Set([...(template.permissions?.[key] ?? []), ...(current.permissions?.[key] ?? [])])];
    if (union.length) perms[key] = union;
  }
  merged.permissions = perms;
}
for (const [key, value] of Object.entries(current)) {
  if (!['hooks', 'env', 'permissions'].includes(key)) merged[key] = value;
}

const out = JSON.stringify(merged, null, 2) + '\n';
const before = fs.readFileSync(settingsPath, 'utf8').replace(/^﻿/, '').replace(/\r\n/g, '\n');
const changed = out !== before;

for (const k of kept) console.log(`  [realign] keep project hook   ${k}`);
for (const d of dropped) console.log(`  [realign] drop retired hook   ${d}`);
if (!changed) {
  console.log('  [realign] .claude/settings.json already matches template + project hooks');
  process.exit(0);
}
if (dryRun) {
  console.log('  [realign] WOULD rewrite .claude/settings.json (template wiring + project hooks above)');
  process.exit(0);
}
if (backupDir) {
  const dest = path.join(backupDir, '.claude', 'settings.json');
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(settingsPath, dest);
  console.log(`  [realign] previous settings.json backed up to ${dest}`);
}
fs.writeFileSync(settingsPath, out, 'utf8');
console.log('  [realign] REWROTE .claude/settings.json (template wiring + project hooks above)');
