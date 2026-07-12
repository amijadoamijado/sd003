import { execFileSync } from 'child_process';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { OrchestratorScenario } from '../../src/orchestrator/types';
import { resolveExecutable, runScenario } from '../../src/orchestrator/runner';

describe('AI-neutral orchestrator E2E', () => {
  let root: string;
  let workspace: string;
  let evidenceDir: string;
  const providerScript = path.resolve(__dirname, '../fixtures/orchestrator/provider.js');

  beforeEach(() => {
    root = fs.mkdtempSync(path.join(os.tmpdir(), 'sd003-orchestrator-'));
    workspace = path.join(root, 'workspace');
    evidenceDir = path.join(root, 'evidence');
    fs.mkdirSync(workspace, { recursive: true });
  });

  afterEach(() => fs.rmSync(root, { recursive: true, force: true }));

  function scenario(overrides: Partial<OrchestratorScenario> = {}): OrchestratorScenario {
    return {
      version: 1,
      id: '20260712-codex-e2e',
      task: 'Create, review, and verify a deterministic deliverable',
      workspace,
      evidenceDir,
      orchestrator: 'codex',
      providers: {
        codex: { command: process.execPath, args: [providerScript, '${stage}', '${workspace}'] },
        agy: { command: process.execPath, args: [providerScript, '${stage}', '${workspace}'] },
        grok: { command: process.execPath, args: [providerScript, '${stage}', '${workspace}'] },
      },
      stages: [
        { id: 'implement', role: 'implementer', provider: 'agy' },
        { id: 'review', role: 'reviewer', provider: 'grok' },
        { id: 'test', role: 'tester', provider: 'codex' },
      ],
      expectedArtifacts: ['artifacts/implement.json', 'artifacts/review.json', 'artifacts/test.json'],
      ...overrides,
    };
  }

  test('Codex orchestrates an isolated real scenario to completion', () => {
    const result = runScenario(scenario(), { runId: 'e2e-run-001', now: () => new Date('2026-07-12T00:00:00Z') });
    expect(result.status).toBe('succeeded');
    expect(result.orchestrator).toBe('codex');
    expect(result.stages.map(stage => stage.status)).toEqual(['succeeded', 'succeeded', 'succeeded']);
    expect(result.artifacts).toHaveLength(3);
    expect(fs.existsSync(path.join(evidenceDir, 'e2e-run-001', 'run.json'))).toBe(true);
  });

  test('a provider failure can never be reported as success', () => {
    const broken = scenario({ providers: { codex: scenario().providers.codex, agy: { command: process.execPath, args: ['-e', 'process.exit(9)'] }, grok: scenario().providers.grok } });
    const result = runScenario(broken, { runId: 'failed-run' });
    expect(result.status).toBe('failed');
    expect(result.stages[0].status).toBe('failed');
    expect(result.stages[1].status).toBe('pending');
  });

  test('provider permission cancellation can never be reported as success', () => {
    // Exact shape observed in run 20260712T012840116Z: the provider's own final response line.
    const markerLine = '2026-07-12T00:00:00Z DEBUG received "session/prompt" response: {"stopReason":"cancelled","_meta":{"cancellationCategory":"PermissionCancelled"}}';
    const cancelled = scenario({
      providers: { codex: { command: process.execPath, args: ['-e', `process.stderr.write(${JSON.stringify(markerLine)});process.exit(0)`] } },
      stages: [{ id: 'review', role: 'reviewer', provider: 'codex' }],
      expectedArtifacts: [],
    });
    const result = runScenario(cancelled, { runId: 'cancelled-run' });
    expect(result.status).toBe('failed');
    expect(result.stages[0].status).toBe('failed');
    expect(result.error).toContain('cancelled by provider permissions');
  });

  test('marker text echoed inside conversation payload lines is not treated as cancellation', () => {
    // sampling_request lines quote conversation content; a stage that merely READS files mentioning
    // PermissionCancelled must not be failed (false positive observed 2026-07-12 during Grok verify).
    const echoLine = `2026-07-12T00:00:00Z  INFO sampling_request{request_id=x model="grok-4.5" ${'y'.repeat(160)}} payload: {"text":"...\\"cancellationCategory\\":\\"PermissionCancelled\\"..."}`;
    const script = `const fs=require('fs');fs.mkdirSync('artifacts',{recursive:true});fs.writeFileSync('artifacts/echo.json','{}');process.stderr.write(${JSON.stringify(echoLine)});`;
    const result = runScenario(scenario({
      providers: { codex: { command: process.execPath, args: ['-e', script] } },
      stages: [{ id: 'review', role: 'reviewer', provider: 'codex' }],
      expectedArtifacts: ['artifacts/echo.json'],
    }), { runId: 'echo-run' });
    expect(result.status).toBe('succeeded');
    expect(result.stages[0].status).toBe('succeeded');
  });

  test('dry-run completes as a successful validation with skipped stages', () => {
    const result = runScenario(scenario(), { runId: 'dry-run', dryRun: true });
    expect(result.status).toBe('succeeded');
    expect(result.stages.every(stage => stage.status === 'skipped')).toBe(true);
  });

  test('prohibited deploy commands are blocked before execution', () => {
    const blocked = scenario({ providers: { ...scenario().providers, agy: { command: 'clasp', args: ['deploy'] } } });
    const result = runScenario(blocked, { runId: 'guard-run' });
    expect(result.status).toBe('failed');
    expect(result.error).toContain('Guard blocked');
  });

  test('missing expected artifacts fail completion', () => {
    const result = runScenario(scenario({ expectedArtifacts: ['artifacts/not-created.json'] }), { runId: 'missing-run' });
    expect(result.status).toBe('failed');
    expect(result.error).toContain('Expected artifact is missing');
  });

  test('provider output larger than the Node default buffer is preserved', () => {
    const script = "const fs=require('fs'),path=require('path');fs.mkdirSync('artifacts',{recursive:true});fs.writeFileSync(path.join('artifacts','large.json'),'{}');process.stdout.write('x'.repeat(2*1024*1024));";
    const result = runScenario(scenario({
      providers: { codex: { command: process.execPath, args: ['-e', script] } },
      stages: [{ id: 'large', role: 'tester', provider: 'codex' }],
      expectedArtifacts: ['artifacts/large.json'],
    }), { runId: 'large-output-run' });
    expect(result.status).toBe('succeeded');
    expect(result.stages[0].stdout).toHaveLength(2 * 1024 * 1024);
  });

  test('Windows executable resolution respects PATH order and prefers exe', () => {
    if (process.platform !== 'win32') return;
    const bin = path.join(root, 'bin');
    fs.mkdirSync(bin);
    fs.writeFileSync(path.join(bin, 'provider.exe'), '');
    fs.writeFileSync(path.join(bin, 'provider.cmd'), '');
    const originalPath = process.env.PATH;
    process.env.PATH = `${bin}${path.delimiter}${originalPath || ''}`;
    try {
      expect(resolveExecutable('provider')).toEqual({ command: path.join(bin, 'provider.exe'), prefixArgs: [] });
    } finally {
      process.env.PATH = originalPath;
    }
  });

  test('dirty Git workspaces are rejected by default', () => {
    execFileSync('git', ['init'], { cwd: workspace });
    execFileSync('git', ['config', 'user.email', 'e2e@example.invalid'], { cwd: workspace });
    execFileSync('git', ['config', 'user.name', 'SD003 E2E'], { cwd: workspace });
    fs.writeFileSync(path.join(workspace, 'sentinel.txt'), 'user change');
    const result = runScenario(scenario(), { runId: 'dirty-run' });
    expect(result.status).toBe('failed');
    expect(result.error).toContain('dirty Git workspace');
    expect(fs.readFileSync(path.join(workspace, 'sentinel.txt'), 'utf8')).toBe('user change');
  });

  test('bypassPermissions is rejected when the repository root is used directly', () => {
    const result = runScenario(scenario({ workspace: path.resolve(__dirname, '../..'), allowDirtyWorkspace: true,
      providers: { codex: { command: process.execPath, args: ['bypassPermissions'] } },
      stages: [{ id: 'review', role: 'reviewer', provider: 'codex' }], expectedArtifacts: [] }), { runId: 'repository-bypass-run' });
    expect(result.status).toBe('failed');
    expect(result.error).toContain('unattendedWorkspaceAck');
  });

  test('bypassPermissions guard is case-insensitive for Windows drive letters and catches joined args', () => {
    if (process.platform !== 'win32') return;
    const repositoryRoot = path.resolve(__dirname, '../..');
    const flipped = /^[a-z]/.test(repositoryRoot)
      ? repositoryRoot[0].toUpperCase() + repositoryRoot.slice(1)
      : repositoryRoot[0].toLowerCase() + repositoryRoot.slice(1);
    const result = runScenario(scenario({ workspace: flipped, allowDirtyWorkspace: true,
      providers: { codex: { command: process.execPath, args: ['--permission-mode=bypassPermissions'] } },
      stages: [{ id: 'review', role: 'reviewer', provider: 'codex' }], expectedArtifacts: [] }), { runId: 'case-bypass-run' });
    expect(result.status).toBe('failed');
    expect(result.error).toContain('unattendedWorkspaceAck');
  });

  test('a dirty real repository subdirectory is rejected', () => {
    const repository = path.join(root, 'repository');
    const subdirectory = path.join(repository, 'nested');
    fs.mkdirSync(subdirectory, { recursive: true });
    execFileSync('git', ['init'], { cwd: repository });
    fs.writeFileSync(path.join(subdirectory, 'sentinel.txt'), 'user change');
    const result = runScenario(scenario({ workspace: subdirectory }), { runId: 'dirty-subdirectory-run' });
    expect(result.status).toBe('failed');
    expect(result.error).toContain('dirty Git workspace');
  });
});
