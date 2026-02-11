// src/cli/commands/qa-deploy-safe.ts

import { Command } from 'commander';
import { QualityGate } from '../../spec-driven/quality-gate';

export function registerQaDeploySafeCommand(program: Command): void {
  program
    .command('qa:deploy:safe')
    .description('Execute all quality gates to determine deployment safety')
    .action(async () => {
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
