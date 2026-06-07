#!/usr/bin/env node
// SD003 deploy-time content verification (smoke test gate).
//
// WHY: deploy.ps1/deploy.sh Phase 6 only checks file COUNT and EXISTENCE, so a
// generated settings.json that exists but is mis-wired (e.g. commit 9f14984 shipped
// guardrails wired to Stop only, leaving PreToolUse empty = guardrails inert) passed
// silently. This verifier checks the CONTENT of the delivered framework and exits
// non-zero so deploy can hard-fail instead of shipping broken config.
//
// Single source of truth (no PS1/sh logic duplication): both deploy scripts call this.
// Uses only Node built-ins -> runs before `npm install`.
//
// Usage: node scripts/verify-deployment.mjs <targetDir> [sourceDir]
//   targetDir : the project SD003 was deployed into
//   sourceDir : the SD003 repo root (defaults to this script's parent's parent)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const targetDir = process.argv[2];
const sourceDir = process.argv[3] || path.resolve(__dirname, '..');

if (!targetDir) {
  console.error('Usage: node verify-deployment.mjs <targetDir> [sourceDir]');
  process.exit(2);
}

// Deprecated tokens that must not survive into a deployed target.
// Override with SD003_DEPRECATED_TOKENS="tok1,tok2". Kept minimal to avoid false
// positives that would erode trust in the gate.
const DEPRECATED_TOKENS = (process.env.SD003_DEPRECATED_TOKENS || '.kiro')
  .split(',')
  .map((t) => t.trim())
  .filter(Boolean);

const failures = [];
const notes = [];

function pass(id, detail) {
  console.log(`  [PASS] ${id}: ${detail}`);
}
function fail(id, detail) {
  console.log(`  [FAIL] ${id}: ${detail}`);
  failures.push(`${id}: ${detail}`);
}
function skip(id, detail) {
  console.log(`  [SKIP] ${id}: ${detail}`);
  notes.push(`${id}: ${detail}`);
}

function readText(p) {
  try {
    return fs.readFileSync(p, 'utf8');
  } catch {
    return null;
  }
}
function readJson(p) {
  const t = readText(p);
  if (t === null) return { ok: false, missing: true };
  try {
    // SD003 convention is UTF-8 with BOM; strip a leading BOM before parsing so
    // a convention-compliant file is not flagged as invalid JSON (false positive).
    return { ok: true, value: JSON.parse(t.replace(/^﻿/, '')) };
  } catch (e) {
    return { ok: false, error: e.message };
  }
}
function listFiles(dir, predicate) {
  const out = [];
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return out;
  }
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...listFiles(full, predicate));
    else if (!predicate || predicate(full)) out.push(full);
  }
  return out;
}

// Collect every `command` string anywhere under a settings.hooks object.
function collectCommands(hooksObj) {
  const cmds = [];
  const walk = (node) => {
    if (Array.isArray(node)) node.forEach(walk);
    else if (node && typeof node === 'object') {
      for (const [k, v] of Object.entries(node)) {
        if (k === 'command' && typeof v === 'string') cmds.push(v);
        else walk(v);
      }
    }
  };
  walk(hooksObj);
  return cmds;
}

// Extract hook script basenames (foo.sh / bar.ps1) referenced in commands.
function hookNamesFrom(hooksObj) {
  const names = new Set();
  const re = /hooks[\\/]+([A-Za-z0-9._-]+\.(?:sh|ps1))/g;
  for (const cmd of collectCommands(hooksObj)) {
    let m;
    while ((m = re.exec(cmd)) !== null) names.add(m[1]);
  }
  return names;
}

console.log('=== Content Verification (verify-deployment.mjs) ===');
console.log(`  target: ${targetDir}`);
console.log(`  source: ${sourceDir}`);

// ---- C1: settings.json valid + guardrail hooks wired (expected derived from template)
const templatePath = path.join(
  sourceDir,
  '.claude',
  'skills',
  'sd-deploy',
  'templates',
  'settings.json.template'
);
const targetSettingsPath = path.join(targetDir, '.claude', 'settings.json');

const tpl = readJson(templatePath);
const dep = readJson(targetSettingsPath);

let deployedHooks = null;
if (!tpl.ok) {
  fail('C1', `source template unreadable/invalid: ${templatePath} (${tpl.error || 'missing'})`);
} else if (!dep.ok) {
  fail('C1', `deployed settings.json unreadable/invalid: ${targetSettingsPath} (${dep.error || 'missing'})`);
} else {
  const tplHooks = tpl.value.hooks || {};
  const depHooks = dep.value.hooks || {};
  deployedHooks = depHooks;

  // 1a: required events present and non-empty (catches Stop-only class directly)
  const requiredEvents = ['PreToolUse', 'PostToolUse', 'Stop', 'SessionStart'];
  const emptyEvents = requiredEvents.filter(
    (ev) => !Array.isArray(depHooks[ev]) || depHooks[ev].length === 0
  );
  if (emptyEvents.length) {
    fail('C1', `deployed settings.json missing/empty events: ${emptyEvents.join(', ')}`);
  } else {
    pass('C1', `events present: ${requiredEvents.join(', ')}`);
  }

  // 1b: every hook wired in the template is also wired in the deployed file
  const expected = hookNamesFrom(tplHooks);
  const deployed = hookNamesFrom(depHooks);
  const missing = [...expected].filter((n) => !deployed.has(n));
  if (missing.length) {
    fail('C1', `hooks wired in template but NOT deployed: ${missing.join(', ')}`);
  } else {
    pass('C1', `all ${expected.size} template hooks wired in deployment`);
  }
}

// ---- C2: every hook referenced by deployed settings.json exists on disk
if (deployedHooks) {
  const referenced = hookNamesFrom(deployedHooks);
  const hooksDir = path.join(targetDir, '.claude', 'hooks');
  const dangling = [...referenced].filter((n) => !fs.existsSync(path.join(hooksDir, n)));
  if (dangling.length) {
    fail('C2', `settings.json references hook files not present in .claude/hooks/: ${dangling.join(', ')}`);
  } else {
    pass('C2', `all ${referenced.size} referenced hook files exist`);
  }
} else {
  skip('C2', 'no parseable deployed settings.json (see C1)');
}

// ---- C3: no unsubstituted template variables {{...}} in generated files
const generatedFiles = [
  'CLAUDE.md',
  'antigravity.md',
  '.claude/settings.json',
  '.sd/ids/registry.json',
  '.sd/ai-coordination/handoff/handoff-log.json',
  '.sessions/session-current.md',
  '.sessions/TIMELINE.md',
];
{
  const offenders = [];
  let scanned = 0;
  for (const rel of generatedFiles) {
    const t = readText(path.join(targetDir, rel));
    if (t === null) continue; // existence is Phase 6's job
    scanned++;
    if (/\{\{|\}\}/.test(t)) offenders.push(rel);
  }
  if (offenders.length) fail('C3', `unsubstituted {{...}} template vars in: ${offenders.join(', ')}`);
  else pass('C3', `no template-var leftovers (${scanned} generated files scanned)`);
}

// ---- C4: no deprecated tokens in deployed commands / settings / CLAUDE.md
{
  const scanTargets = [
    ...listFiles(path.join(targetDir, '.claude', 'commands'), (f) => f.endsWith('.md')),
    path.join(targetDir, '.claude', 'settings.json'),
    path.join(targetDir, 'CLAUDE.md'),
  ];
  const offenders = [];
  let scanned = 0;
  for (const f of scanTargets) {
    const t = readText(f);
    if (t === null) continue;
    scanned++;
    for (const tok of DEPRECATED_TOKENS) {
      if (t.includes(tok)) offenders.push(`${path.relative(targetDir, f)} -> "${tok}"`);
    }
  }
  if (offenders.length) fail('C4', `deprecated tokens found: ${offenders.join('; ')}`);
  else pass('C4', `no deprecated tokens [${DEPRECATED_TOKENS.join(', ')}] (${scanned} files)`);
}

// ---- C5: no mojibake (U+FFFD replacement char) in hook scripts + settings.json
{
  const scanTargets = [
    ...listFiles(path.join(targetDir, '.claude', 'hooks'), (f) => f.endsWith('.sh')),
    path.join(targetDir, '.claude', 'settings.json'),
  ];
  const offenders = [];
  let scanned = 0;
  for (const f of scanTargets) {
    const t = readText(f);
    if (t === null) continue;
    scanned++;
    if (t.includes('�')) offenders.push(path.relative(targetDir, f));
  }
  if (offenders.length) fail('C5', `mojibake (U+FFFD) detected in: ${offenders.join(', ')}`);
  else pass('C5', `no mojibake markers (${scanned} files)`);
}

// ---- C6: generated JSON files parse
{
  const jsonFiles = [
    '.sd/ids/registry.json',
    '.sd/ai-coordination/handoff/handoff-log.json',
  ];
  const bad = [];
  let scanned = 0;
  for (const rel of jsonFiles) {
    const p = path.join(targetDir, rel);
    if (!fs.existsSync(p)) continue; // existence is Phase 6's job
    scanned++;
    const r = readJson(p);
    if (!r.ok) bad.push(`${rel} (${r.error})`);
  }
  if (bad.length) fail('C6', `invalid JSON: ${bad.join(', ')}`);
  else pass('C6', `generated JSON valid (${scanned} files)`);
}

console.log('');
if (failures.length) {
  console.log(`Content verification FAILED (${failures.length} issue(s)):`);
  for (const f of failures) console.log(`  - ${f}`);
  process.exit(1);
}
console.log('Content verification PASSED' + (notes.length ? ` (${notes.length} skipped)` : ''));
process.exit(0);
