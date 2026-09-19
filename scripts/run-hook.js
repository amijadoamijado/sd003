#!/usr/bin/env node
// Run a Claude-format hook script with a real bash.
// On Windows, PATH "bash" is often C:\Windows\System32\bash.exe (WSL stub).
// That stub exits 1 when WSL is not installed, so Grok/Claude hooks fail open
// and the TUI shows pre_tool_use errors. This launcher never uses that stub.
//
// Usage: node scripts/run-hook.js <script> [args...]
'use strict';

const { spawn, execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const script = process.argv[2];
const extraArgs = process.argv.slice(3);

if (!script) {
  process.stderr.write('run-hook.js: missing hook script path\n');
  process.exit(1);
}

function exists(p) {
  try {
    return Boolean(p) && fs.existsSync(p);
  } catch {
    return false;
  }
}

function isWslStub(p) {
  const n = String(p || '').replace(/\\/g, '/').toLowerCase();
  return n.endsWith('/system32/bash.exe') || n.endsWith('/syswow64/bash.exe');
}

function bashFromGit(gitPath) {
  if (!gitPath) return null;
  const bash = path.join(path.dirname(path.dirname(gitPath)), 'bin', 'bash.exe');
  return exists(bash) && !isWslStub(bash) ? bash : null;
}

function resolveBash() {
  const envCandidates = [
    process.env.CLAUDE_CODE_GIT_BASH_PATH,
    process.env.GROK_BASH,
    process.env.GIT_BASH
  ];
  for (const c of envCandidates) {
    if (exists(c) && !isWslStub(c)) return c;
  }

  if (process.platform !== 'win32') return 'bash';

  const pf = process.env.ProgramFiles || 'C:\\Program Files';
  const pf86 = process.env['ProgramFiles(x86)'] || 'C:\\Program Files (x86)';
  const local = process.env.LOCALAPPDATA || '';
  const winCandidates = [
    path.join(pf, 'Git', 'bin', 'bash.exe'),
    path.join('D:\\Program Files', 'Git', 'bin', 'bash.exe'),
    path.join(pf86, 'Git', 'bin', 'bash.exe'),
    path.join(local, 'Programs', 'Git', 'bin', 'bash.exe')
  ];
  for (const c of winCandidates) {
    if (exists(c) && !isWslStub(c)) return c;
  }

  try {
    const out = execFileSync('where.exe', ['git'], {
      encoding: 'utf8',
      timeout: 2000,
      windowsHide: true
    });
    for (const line of out.split(/\r?\n/)) {
      const found = bashFromGit(line.trim());
      if (found) return found;
    }
  } catch {
    // ignore: PATH may not have git.exe
  }

  const dirs = String(process.env.PATH || '').split(path.delimiter);
  for (const dir of dirs) {
    const candidate = path.join(dir, 'bash.exe');
    if (exists(candidate) && !isWslStub(candidate)) return candidate;
  }
  return null;
}

function toClaudePayload(raw) {
  let data;
  try {
    data = JSON.parse(raw || '{}');
  } catch {
    return raw;
  }
  if (!data || typeof data !== 'object' || Array.isArray(data)) return raw;

  const toolInput = data.tool_input || data.toolInput || data.input;
  const toolName = data.tool_name || data.toolName || data.name;
  const sessionId = data.session_id || data.sessionId;
  if (toolInput != null && data.tool_input == null) data.tool_input = toolInput;
  if (toolName != null && data.tool_name == null) data.tool_name = toolName;
  if (sessionId != null && data.session_id == null) data.session_id = sessionId;
  if (data.tool_input && typeof data.tool_input === 'object' && !Array.isArray(data.tool_input)) {
    if (data.tool_input.file_path == null && data.tool_input.filePath != null) {
      data.tool_input.file_path = data.tool_input.filePath;
    }
  }
  return JSON.stringify(data);
}

function run(payload) {
  const bash = resolveBash();
  if (!bash) {
    process.stderr.write(
      'run-hook.js: Git Bash not found (skipped Windows WSL stub). Hook not run: ' + script + '\n'
    );
    process.exit(0);
  }

  const child = spawn(bash, [script, ...extraArgs], {
    stdio: ['pipe', 'inherit', 'inherit'],
    windowsHide: true,
    env: process.env
  });
  child.on('error', (err) => {
    process.stderr.write('run-hook.js: failed to spawn bash: ' + err.message + '\n');
    process.exit(0);
  });
  child.on('exit', (code) => {
    process.exit(code == null ? 0 : code);
  });
  child.stdin.write(payload);
  child.stdin.end();
}

let input = '';
let started = false;
function start(payload) {
  if (started) return;
  started = true;
  run(payload);
}

process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => {
  input += chunk;
});
process.stdin.on('end', () => {
  start(toClaudePayload(input));
});
if (process.stdin.isTTY) {
  start(toClaudePayload('{}'));
}
