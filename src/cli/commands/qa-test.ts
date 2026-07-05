// src/cli/commands/qa-test.ts

import { Command } from 'commander';
import { execFileSync } from 'child_process';

export function registerQaTestCommand(program: Command): void {
  program
    .command('qa:test')
    .description('Execute the project test suite (npm test)')
    .action(async () => {
      // Guard against a nested test run: this command is reachable from `runCli()` in
      // integration tests, and spawning `npm test` from inside an already-running Jest
      // worker would recursively invoke the test runner.
      if (process.env.JEST_WORKER_ID !== undefined) {
        console.log('qa:test: skipped (running inside a Jest worker; avoids a nested test run).');
        return;
      }

      console.log('Executing project tests...');
      const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
      try {
        // shell: true is required on Windows — npm resolves to a .cmd shim, which
        // execFileSync cannot spawn directly without a shell (fails with EINVAL).
        execFileSync(npm, ['test'], { cwd: process.cwd(), stdio: 'inherit', shell: true });
        console.log('✅ Tests passed.');
      } catch {
        console.error('❌ Tests failed.');
        process.exit(1);
      }
    });
}
