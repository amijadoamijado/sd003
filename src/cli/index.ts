// src/cli/index.ts

import { Command } from 'commander';
import { registerSpecCreateCommand } from './commands/spec-create';
import { registerSpecValidateCommand } from './commands/spec-validate';
import { registerSpecSyncCommand } from './commands/spec-sync';
import { registerSpecListCommand } from './commands/spec-list';
import { registerQaTestCommand } from './commands/qa-test';
import { registerQaDeploySafeCommand } from './commands/qa-deploy-safe';
import { registerQaCoverageCommand } from './commands/qa-coverage';

const program = new Command();

program
  .version('1.0.0')
  .description('SD002 CLI - Spec-Driven Development Framework for GAS');

// Register commands
registerSpecCreateCommand(program);
registerSpecValidateCommand(program);
registerSpecSyncCommand(program);
registerSpecListCommand(program);
registerQaTestCommand(program);
registerQaDeploySafeCommand(program);
registerQaCoverageCommand(program);

// Define global options if any
// program.option('-v, --verbose', 'enable verbose logging');

// Parse arguments and execute commands
export async function runCli(): Promise<void> {
  await program.parseAsync(process.argv);

  if (!process.argv.slice(2).length) {
    program.outputHelp();
  }
}

// If this file is run directly (e.g., via `node dist/cli/index.js`), execute the CLI.
// This is common in Node.js CLI applications.
if (require.main === module) {
  runCli().catch(error => {
    console.error('CLI Error:', error.message);
    process.exit(1);
  });
}