// src/cli/commands/spec-create.ts

import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { IdRegistry } from '../../spec-driven/id-registry';
import { extractFrontMatter, findSpecMarkdownFiles } from '../../spec-driven/spec-file-utils';

interface MinimalFrontMatter {
  id?: string;
}

/**
 * Seeds the (per-process, in-memory) IdRegistry with every ID already present on disk.
 * Without this, IdRegistry.generateId('REQ') always starts back at REQ-001 on every new
 * CLI invocation (a fresh process each time), reissuing an ID that already exists and
 * silently colliding with an existing spec.
 */
function seedIdRegistryFromDisk(specDirPath: string): void {
  if (!fs.existsSync(specDirPath)) {
    return;
  }
  for (const filePath of findSpecMarkdownFiles(specDirPath)) {
    try {
      const fileContent = fs.readFileSync(filePath, 'utf8');
      const frontMatterText = extractFrontMatter(fileContent);
      if (frontMatterText === null) {
        continue;
      }
      const frontMatter = yaml.load(frontMatterText) as MinimalFrontMatter;
      if (frontMatter && frontMatter.id) {
        IdRegistry.registerId(frontMatter.id);
      }
    } catch {
      // Unparsable front matter is reported by `spec:validate`; ID seeding just skips it.
    }
  }
}

/**
 * Sanitizes a free-form spec name into a filesystem- and Windows-safe slug.
 * Characters invalid in Windows filenames (`:/\?*"<>|`) previously passed straight
 * through into the generated filename, causing EINVAL/ENOENT writes.
 */
function sanitizeForFilename(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[:/\\?*"<>|]/g, '-')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export function registerSpecCreateCommand(program: Command): void {
  program
    .command('spec:create <name>')
    .description('Create a new specification document')
    .action(async (name: string) => {
      try {
        const specDirPath = path.join(process.cwd(), '.sd', 'specs');

        if (!fs.existsSync(specDirPath)) {
          fs.mkdirSync(specDirPath, { recursive: true });
        }

        // Seed IDs already on disk so generateId() never reissues an existing ID.
        seedIdRegistryFromDisk(specDirPath);

        const specId = IdRegistry.generateId('REQ'); // Assuming new specs are requirements
        const slug = sanitizeForFilename(name);
        const specFileName = `${specId}-${slug}.md`;
        const specFilePath = path.join(specDirPath, specFileName);

        if (fs.existsSync(specFilePath)) {
          // Never silently overwrite an existing spec (file-overwrite prohibition).
          throw new Error(`Refusing to overwrite existing specification: ${specFilePath}`);
        }

        // YAML-safe serialization of `name` (js-yaml only quotes when the value actually
        // needs it, e.g. contains ": ", so simple names remain unquoted as before).
        const frontMatterYaml = yaml
          .dump({ id: specId, name, type: 'REQ', status: 'DRAFT' })
          .replace(/\n+$/, '');

        const template = `---
${frontMatterYaml}
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
      } catch (error: unknown) {
        const message = error instanceof Error ? error.message : String(error);
        console.error(`Error creating specification: ${message}`);
        process.exit(1);
      }
    });
}