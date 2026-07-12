import path from 'path';
import { Command } from 'commander';
import { loadScenario, runScenario } from '../../orchestrator/runner';
export function registerOrchestrateCommand(program: Command): void {
  program.command('orchestrate').description('Run an AI-neutral orchestration scenario').requiredOption('-s, --scenario <file>', 'scenario JSON file').option('--dry-run', 'validate without running providers').action((options: { scenario: string; dryRun?: boolean }) => {
    const manifest = runScenario(loadScenario(path.resolve(options.scenario)), { dryRun: Boolean(options.dryRun) });
    console.log(JSON.stringify(manifest, null, 2));
    if (manifest.status !== 'succeeded' && !options.dryRun) process.exitCode = 1;
  });
}
