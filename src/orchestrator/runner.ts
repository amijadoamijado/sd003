import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { OrchestratorScenario, RunManifest, StageDefinition } from './types';

export interface RunOptions { dryRun?: boolean; runId?: string; now?: () => Date; }

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
  if (!fs.existsSync(path.join(workspace, '.git'))) return false;
  const result = spawnSync('git', ['-C', workspace, 'status', '--porcelain'], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error(`Unable to inspect Git workspace: ${result.stderr}`);
  return result.stdout.trim().length > 0;
}

function writeManifest(manifestPath: string, manifest: RunManifest): void {
  fs.mkdirSync(path.dirname(manifestPath), { recursive: true });
  const temporary = `${manifestPath}.tmp`;
  fs.writeFileSync(temporary, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
  fs.renameSync(temporary, manifestPath);
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
    for (const result of manifest.stages) {
      const provider = scenario.providers[result.provider];
      const args = provider.args.map(arg => substitute(arg, scenario, runId, result));
      assertSafeProvider(provider.command, args);
      result.status = 'running'; result.startedAt = now().toISOString(); writeManifest(manifestPath, manifest);
      if (options.dryRun) { result.status = 'skipped'; result.completedAt = now().toISOString(); continue; }
      const execution = spawnSync(provider.command, args, { cwd: workspace, encoding: 'utf8', timeout: provider.timeoutMs ?? 300000, shell: false });
      result.exitCode = execution.status ?? 1; result.stdout = execution.stdout || ''; result.stderr = execution.stderr || execution.error?.message || ''; result.completedAt = now().toISOString();
      if (execution.error || execution.status !== 0) { result.status = 'failed'; throw new Error(`Stage ${result.id} failed with exit code ${result.exitCode}: ${result.stderr}`); }
      result.status = 'succeeded';
    }
    if (!options.dryRun) {
      manifest.artifacts = scenario.expectedArtifacts.map(relative => { const artifact = resolveInside(workspace, relative); if (!fs.existsSync(artifact)) throw new Error(`Expected artifact is missing: ${relative}`); return path.relative(workspace, artifact).replace(/\\/g, '/'); });
      manifest.status = 'succeeded';
    }
  } catch (error) { manifest.status = 'failed'; manifest.error = error instanceof Error ? error.message : String(error); }
  manifest.completedAt = now().toISOString(); writeManifest(manifestPath, manifest); return manifest;
}
