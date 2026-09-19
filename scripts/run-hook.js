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

// A candidate is usable only if it actually starts. On some PCs a Git Bash
// found first exists on disk but dies at startup (e.g. "Top-level not found"),
// so existence alone is not enough. Results are remembered for this process.
const launchable = new Map();
function usable(p) {
  if (!exists(p) || isWslStub(p)) return false;
  if (launchable.has(p)) return launchable.get(p);
  let ok = false;
  try {
    execFileSync(p, ['-c', 'exit 0'], { timeout: 5000, windowsHide: true, stdio: 'ignore' });
    ok = true;
  } catch {
    ok = false;
  }
  launchable.set(p, ok);
  return ok;
}

function bashFromGit(gitPath) {
  if (!gitPath) return null;
  const bash = path.join(path.dirname(path.dirname(gitPath)), 'bin', 'bash.exe');
  return usable(bash) ? bash : null;
}

function resolveBash() {
  const envCandidates = [
    process.env.CLAUDE_CODE_GIT_BASH_PATH,
    process.env.GROK_BASH,
    process.env.GIT_BASH
  ];
  for (const c of envCandidates) {
    if (usable(c)) return c;
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
    if (usable(c)) return c;
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
    if (usable(candidate)) return candidate;
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

  // Stop the whole tree ourselves before the caller's hook timeout. When Claude Code
  // kills this node process on Windows, bash and its children (e.g. `npm test`) keep
  // running and keep the inherited stdout/stderr open, so the tool call waits for them
  // long after the configured timeout. Fail open on the deadline, like a missing bash.
  const deadlineMs = Number(process.env.SD003_HOOK_DEADLINE_MS) || 100000;
  const watchdog = setTimeout(() => {
    process.stderr.write('run-hook.js: hook exceeded ' + deadlineMs + 'ms and was stopped (not enforced): ' + script + '\n');
    try {
      if (process.platform === 'win32') {
        execFileSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore', windowsHide: true, timeout: 10000 });
      } else {
        child.kill('SIGKILL');
      }
    } catch {
      // ignore: the tree may already be gone
    }
    process.exit(0);
  }, deadlineMs);

  child.on('error', (err) => {
    clearTimeout(watchdog);
    process.stderr.write('run-hook.js: failed to spawn bash: ' + err.message + '\n');
    process.exit(0);
  });
  child.on('exit', (code) => {
    clearTimeout(watchdog);
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
