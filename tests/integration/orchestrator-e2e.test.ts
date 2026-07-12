import { execFileSync } from 'child_process';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { OrchestratorScenario } from '../../src/orchestrator/types';
import { runScenario } from '../../src/orchestrator/runner';

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
});
