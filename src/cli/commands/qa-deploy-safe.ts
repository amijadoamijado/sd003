// src/cli/commands/qa-deploy-safe.ts

import { Command } from 'commander';
import { execFileSync } from 'child_process';
import { QualityGate, QualityGateResult } from '../../spec-driven/quality-gate';

const MAX_DETAIL_LENGTH = 4000;

function truncate(text: string): string {
  return text.length > MAX_DETAIL_LENGTH ? `...${text.slice(-MAX_DETAIL_LENGTH)}` : text;
}

/**
 * Builds a real quality-gate check that runs `command args` as a child process.
 * PASSED/FAILED is determined solely by the process exit code — this replaces the
 * previous mock gates, which returned PASSED unconditionally regardless of project
 * state (Real Data First — `.claude/rules/global/real-data-first.md`).
 */
function runCheckGate(gateName: string, command: string, args: string[]): () => Promise<QualityGateResult> {
  return async (): Promise<QualityGateResult> => {
    try {
      const output = execFileSync(command, args, {
        cwd: process.cwd(),
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'pipe'],
        // Required on Windows: npx/npm resolve to a .cmd shim, and Node's execFileSync
        // cannot spawn .cmd files directly without a shell (fails with EINVAL).
        shell: true,
      });
      return {
        gate: gateName,
        status: 'PASSED',
        message: `${gateName} passed (${command} ${args.join(' ')}).`,
        details: truncate(output),
      };
    } catch (error: unknown) {
      const err = error as { stdout?: string; stderr?: string; message?: string };
      const output = `${err.stdout ?? ''}${err.stderr ?? ''}`.trim() || err.message || String(error);
      return {
        gate: gateName,
        status: 'FAILED',
        message: `${gateName} failed (${command} ${args.join(' ')}).`,
        details: truncate(output),
      };
    }
  };
}

/**
 * A gate with no real check wired up yet. Reports FAILED (never PASSED/SKIPPED) so it
 * can never emit a false green — see finding CRIT-honesty #6.
 */
function notImplementedGate(gateName: string): () => Promise<QualityGateResult> {
  return async (): Promise<QualityGateResult> => ({
    gate: gateName,
    status: 'FAILED',
    message: `${gateName}: NOT IMPLEMENTED — no real check exists yet, so this gate cannot report PASSED.`,
  });
}

/**
 * Overwrites the placeholder mock gates (registered by importing `quality-gate.ts`)
 * with real, honest checks for the production `qa:deploy:safe` command.
 *
 * Guarded against running inside a Jest worker: this command is exercised by
 * `tests/integration/quality-gate-integration.test.ts` via `runCli()`, which registers
 * its own controlled mock gates in `beforeEach`. Wiring real gates there would spawn a
 * nested `npm test`/tsc/eslint child process from inside the already-running test run.
 */
function wireRealGatesUnlessUnderTest(): void {
  if (process.env.JEST_WORKER_ID !== undefined) {
    return;
  }

  const npx = process.platform === 'win32' ? 'npx.cmd' : 'npx';

  QualityGate.registerGate('SyntaxValidation', runCheckGate('SyntaxValidation', npx, ['tsc', '--noEmit']));
  QualityGate.registerGate('TypeValidation', runCheckGate('TypeValidation', npx, ['tsc', '--noEmit']));
  QualityGate.registerGate('LintValidation', runCheckGate('LintValidation', npx, ['eslint', 'src/**/*.ts']));
  QualityGate.registerGate('TestValidation', runCheckGate('TestValidation', npx, ['jest', '--ci']));
  QualityGate.registerGate('SecurityValidation', notImplementedGate('SecurityValidation'));
  QualityGate.registerGate('PerformanceValidation', notImplementedGate('PerformanceValidation'));
  QualityGate.registerGate('DocumentValidation', notImplementedGate('DocumentValidation'));
  QualityGate.registerGate('IntegrationValidation', notImplementedGate('IntegrationValidation'));
}

export function registerQaDeploySafeCommand(program: Command): void {
  program
    .command('qa:deploy:safe')
    .description('Execute all quality gates to determine deployment safety')
    .action(async () => {
      wireRealGatesUnlessUnderTest();
      console.log('Running deployment safety checks...');
      const results = await QualityGate.executeAllGates();

      console.log('\n--- Quality Gate Results ---');
      results.forEach(result => {
        const statusIcon = result.status === 'PASSED' ? '✅' : result.status === 'FAILED' ? '❌' : '⚠️';
        console.log(`${statusIcon} ${result.gate}: ${result.message || result.status}`);
      });

      if (QualityGate.allGatesPassed(results)) {
        console.log('\n✅ All quality gates passed. Deployment is considered safe.');
      } else {
        console.error('\n❌ Some quality gates failed. Deployment is NOT safe.');
        process.exit(1);
      }
    });
}
