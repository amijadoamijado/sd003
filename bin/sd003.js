#!/usr/bin/env node

// This file is the main entry point for the sd003 CLI.
// It delegates to the CLI controller.
const { runCli } = require('../dist/cli/index.js');

runCli().catch((error) => {
  console.error('CLI Error:', error.message);
  process.exit(1);
});