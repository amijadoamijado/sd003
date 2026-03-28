// src/cli/commands/spec-create.ts

import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import { IdRegistry } from '../../spec-driven/id-registry';

export function registerSpecCreateCommand(program: Command): void {
  program
    .command('spec:create <name>')
    .description('Create a new specification document')
    .action(async (name: string) => {
      try {
        const specId = IdRegistry.generateId('REQ'); // Assuming new specs are requirements
        const specFileName = `${specId}-${name.toLowerCase().replace(/\s/g, '-')}.md`;
        const specDirPath = path.join(process.cwd(), '.sd', 'specs');
        const specFilePath = path.join(specDirPath, specFileName);

        if (!fs.existsSync(specDirPath)) {
          fs.mkdirSync(specDirPath, { recursive: true });
        }

        const template = `---
id: ${specId}
name: ${name}
type: REQ
status: DRAFT
---

# ${name}

## 1. Overview
[Brief description of the requirement]

## 2. Functional Requirements
### REQ-001: [Requirement Title]
- Description: [Detailed description of the requirement]
- Priority: HIGH/MEDIUM/LOW
- Status: DRAFT/APPROVED/IMPLEMENTED/TESTED
- Traceability:
    - DESIGN: []
    - IMPL: []
    - TEST: []

## 3. Non-Functional Requirements
[e.g., Performance, Security, Usability]

## 4. Acceptance Criteria
[List of criteria to be met for this requirement to be considered complete]

## 5. Notes
[Any additional notes or considerations]
`;

        fs.writeFileSync(specFilePath, template);
        console.log(`Successfully created new specification: ${specFilePath}`);
        console.log(`Generated ID: ${specId}`);
      } catch (error: any) {
        console.error(`Error creating specification: ${error.message}`);
        process.exit(1);
      }
    });
}