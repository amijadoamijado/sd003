import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { OrchestratorScenario, RunManifest, StageDefinition } from './types';

export interface RunOptions { dryRun?: boolean; runId?: string; now?: () => Date; }

export function resolveExecutable(command: string): { command: string; prefixArgs: string[] } {
  if (process.platform !== 'win32' || path.extname(command)) return { command, prefixArgs: [] };
  for (const directory of (process.env.PATH || '').split(path.delimiter)) {
    const executable = path.join(directory, `${command}.exe`);
    if (fs.existsSync(executable)) return { command: executable, prefixArgs: [] };
    const shim = path.join(directory, `${command}.cmd`);
    if (!fs.existsSync(shim)) continue;
    const match = fs.readFileSync(shim, 'utf8').match(/"%dp0%\\([^"\r\n]+\.js)"/i);
    if (match) return { command: process.execPath, prefixArgs: [path.join(directory, match[1])] };
  }
  return { command, prefixArgs: [] };
}

function resolveInside(root: string, relative: string): string {
  const resolvedRoot = path.resolve(root);
  const resolved = path.resolve(resolvedRoot, relative);
  if (resolved !== resolvedRoot && !resolved.startsWith(resolvedRoot + path.sep)) throw new Error(`Path escapes workspace: ${relative}`);
  return resolved;
}

function substitute(value: string, scenario: OrchestratorScenario, runId: string, stage: StageDefinition): string {
  const variables: Record<string, string> = { workspace: path.resolve(scenario.workspace), evidenceDir: path.resolve(scenario.evidenceDir), runId, task: scenario.task, stage: stage.id, role: stage.role };
  return value.replace(/\$\{(workspace|evidenceDir|runId|task|stage|role)\}/g, (_match, key: string) => variables[key]);
}

function assertSafeProvider(command: string, args: string[]): void {
  const invocation = [command, ...args].join(' ').toLowerCase();
  if (/\bclasp\s+(deploy|undeploy)\b/.test(invocation)) throw new Error('Guard blocked prohibited clasp deployment command');
  if (/\bgit\s+add\s+-a\b/.test(invocation)) throw new Error('Guard blocked repository-wide staging');
}

function isDirtyGitWorkspace(workspace: string): boolean {
  const probe = spawnSync('git', ['-C', workspace, 'rev-parse', '--is-inside-work-tree'], { encoding: 'utf8' });
  if (probe.status !== 0) return false;
  const result = spawnSync('git', ['-C', workspace, 'status', '--porcelain', '--', '.'], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error(`Unable to inspect Git workspace: ${result.stderr}`);
  return result.stdout.trim().length > 0;
}

function writeManifest(manifestPath: string, manifest: RunManifest): void {
  fs.mkdirSync(path.dirname(manifestPath), { recursive: true });
  const temporary = `${manifestPath}.tmp`;
  fs.writeFileSync(temporary, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  fs.renameSync(temporary, manifestPath);
}

function gitCommonDir(workspace: string): string | undefined {
  const result = spawnSync('git', ['-C', workspace, 'rev-parse', '--git-common-dir'], { encoding: 'utf8' });
  return result.status === 0 ? path.resolve(workspace, result.stdout.trim()) : undefined;
}

function isRepositoryWorkspace(workspace: string): boolean {
  const repositoryRoot = path.resolve(__dirname, '..', '..');
  if (workspace === repositoryRoot || workspace.startsWith(repositoryRoot + path.sep)) return true;
  const repositoryCommonDir = gitCommonDir(repositoryRoot);
  return repositoryCommonDir !== undefined && gitCommonDir(workspace) === repositoryCommonDir;
}

function hasProviderCancellation(output: string, patterns?: string[]): boolean {
  return (patterns ?? ['cancellationCategory["\\\\:=\\s]+PermissionCancelled']).some(pattern => new RegExp(pattern, 'i').test(output));
}

export function loadScenario(file: string): OrchestratorScenario {
  const scenario = JSON.parse(fs.readFileSync(file, 'utf8')) as OrchestratorScenario;
  if (scenario.version !== 1 || !scenario.id || !scenario.orchestrator || !Array.isArray(scenario.stages)) throw new Error('Invalid orchestrator scenario');
  if (!scenario.providers[scenario.orchestrator]) throw new Error(`Unknown orchestrator provider: ${scenario.orchestrator}`);
  for (const stage of scenario.stages) if (!scenario.providers[stage.provider]) throw new Error(`Unknown provider for stage ${stage.id}: ${stage.provider}`);
  return scenario;
}

export function runScenario(scenario: OrchestratorScenario, options: RunOptions = {}): RunManifest {
  const now = options.now ?? (() => new Date());
  const runId = options.runId ?? `${now().toISOString().replace(/[-:.]/g, '')}-${scenario.id}`;
  const workspace = path.resolve(scenario.workspace);
  const manifestPath = path.join(path.resolve(scenario.evidenceDir), runId, 'run.json');
  fs.mkdirSync(workspace, { recursive: true });
  const manifest: RunManifest = { contractVersion: 1, runId, scenarioId: scenario.id, task: scenario.task, orchestrator: scenario.orchestrator, workspace, status: 'running', startedAt: now().toISOString(), stages: scenario.stages.map(stage => ({ ...stage, status: 'pending' })), artifacts: [] };
  try {
    if (!scenario.allowDirtyWorkspace && isDirtyGitWorkspace(workspace)) throw new Error('Guard blocked dirty Git workspace');
    const hasBypassPermissions = scenario.stages.some(stage => scenario.providers[stage.provider].args
      .map(arg => substitute(arg, scenario, runId, stage))
      .some(arg => arg === 'bypassPermissions' || arg === '--dangerously-skip-permissions'));
    if (hasBypassPermissions && isRepositoryWorkspace(workspace) && !scenario.unattendedWorkspaceAck) throw new Error('Guard blocked bypassPermissions in repository workspace without unattendedWorkspaceAck');
    for (const result of manifest.stages) {
      const provider = scenario.providers[result.provider];
      const args = provider.args.map(arg => substitute(arg, scenario, runId, result));
      assertSafeProvider(provider.command, args);
      result.status = 'running'; result.startedAt = now().toISOString(); writeManifest(manifestPath, manifest);
      if (options.dryRun) { result.status = 'skipped'; result.completedAt = now().toISOString(); continue; }
      const executable = resolveExecutable(provider.command);
      const execution = spawnSync(executable.command, [...executable.prefixArgs, ...args], {
        cwd: workspace,
        encoding: 'utf8',
        timeout: provider.timeoutMs ?? 300000,
        maxBuffer: 16 * 1024 * 1024,
        shell: false,
      });
      result.exitCode = execution.status ?? 1; result.stdout = execution.stdout || ''; result.stderr = execution.stderr || execution.error?.message || ''; result.completedAt = now().toISOString();
      if (execution.error || execution.status !== 0) { result.status = 'failed'; throw new Error(`Stage ${result.id} failed with exit code ${result.exitCode}: ${result.stderr}`); }
      if (hasProviderCancellation(`${result.stdout}\n${result.stderr}`, provider.cancellationPatterns)) { result.status = 'failed'; throw new Error(`Stage ${result.id} was cancelled by provider permissions`); }
      for (const relative of result.expectedArtifacts ?? []) {
        if (!fs.existsSync(resolveInside(workspace, relative))) { result.status = 'failed'; throw new Error(`Stage ${result.id} expected artifact is missing: ${relative}`); }
      }
      result.status = 'succeeded';
    }
    if (options.dryRun) {
      manifest.status = 'succeeded';
    } else {
      manifest.artifacts = scenario.expectedArtifacts.map(relative => { const artifact = resolveInside(workspace, relative); if (!fs.existsSync(artifact)) throw new Error(`Expected artifact is missing: ${relative}`); return path.relative(workspace, artifact).replace(/\\/g, '/'); });
      manifest.status = 'succeeded';
    }
  } catch (error) { manifest.status = 'failed'; manifest.error = error instanceof Error ? error.message : String(error); }
  manifest.completedAt = now().toISOString(); writeManifest(manifestPath, manifest); return manifest;
}
