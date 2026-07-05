// src/cli/commands/qa-coverage.ts

import { Command } from 'commander';
import { execFileSync } from 'child_process';

export function registerQaCoverageCommand(program: Command): void {
  program
    .command('qa:coverage')
    .description('Run the test suite with coverage collection (npm run test:coverage)')
    .action(async () => {
      // Guard against a nested test run (see qa-test.ts for the same rationale).
      if (process.env.JEST_WORKER_ID !== undefined) {
        console.log('qa:coverage: skipped (running inside a Jest worker; avoids a nested test run).');
        return;
      }

      console.log('Collecting test coverage...');
      const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
      try {
        // shell: true is required on Windows — npm resolves to a .cmd shim, which
        // execFileSync cannot spawn directly without a shell (fails with EINVAL).
        execFileSync(npm, ['run', 'test:coverage'], { cwd: process.cwd(), stdio: 'inherit', shell: true });
        console.log('✅ Coverage collection complete.');
      } catch {
        console.error('❌ Coverage collection failed.');
        process.exit(1);
      }
    });
}
