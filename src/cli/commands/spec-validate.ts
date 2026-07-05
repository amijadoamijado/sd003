// src/cli/commands/spec-validate.ts

import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml'; // You might need to install this: npm install js-yaml
import { IdRegistry } from '../../spec-driven/id-registry';
import { extractFrontMatter, findSpecMarkdownFiles } from '../../spec-driven/spec-file-utils';
// TraceabilityEngine reserved for future use

interface SpecFrontMatter {
  id: string;
  name: string;
  type: string;
  status: string;
  traceability?: {
    DESIGN?: string[];
    IMPL?: string[];
    TEST?: string[];
  };
}

export function registerSpecValidateCommand(program: Command): void {
  program
    .command('spec:validate')
    .description('Validate all specification documents in .sd/specs/')
    .action(async () => {
      console.log('Starting specification validation...');
      const specDirPath = path.join(process.cwd(), '.sd', 'specs');

      if (!fs.existsSync(specDirPath)) {
        console.warn(`Specification directory not found: ${specDirPath}`);
        console.log('Validation skipped.');
        return;
      }

      const specFiles = findSpecMarkdownFiles(specDirPath);
      let allValid = true;

      // First pass: Register all IDs and collect basic info
      const specs: { filePath: string; frontMatter: SpecFrontMatter; content: string }[] = [];
      for (const filePath of specFiles) {
        const relFile = path.relative(specDirPath, filePath).split(path.sep).join('/');
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const frontMatterText = extractFrontMatter(fileContent);

        if (frontMatterText === null) {
          console.error(`❌ ${relFile}: Missing YAML front matter.`);
          allValid = false;
          continue;
        }

        try {
          const frontMatter = yaml.load(frontMatterText) as SpecFrontMatter;
          if (!frontMatter.id || !frontMatter.name || !frontMatter.type || !frontMatter.status) {
            console.error(`❌ ${relFile}: Incomplete front matter. Required: id, name, type, status.`);
            allValid = false;
            continue;
          }

          if (!IdRegistry.isValidId(frontMatter.id)) {
            console.error(`❌ ${relFile}: Invalid ID format: ${frontMatter.id}`);
            allValid = false;
          } else if (!IdRegistry.registerId(frontMatter.id)) {
            console.error(`❌ ${relFile}: Duplicate ID found: ${frontMatter.id}`);
            allValid = false;
          }
          specs.push({ filePath, frontMatter, content: fileContent });
        } catch (error: unknown) {
          const message = error instanceof Error ? error.message : String(error);
          console.error(`❌ ${relFile}: Invalid YAML front matter: ${message}`);
          allValid = false;
        }
      }

      // Second pass: Validate traceability links
      for (const spec of specs) {
        const { filePath, frontMatter } = spec;
        const relFile = path.relative(specDirPath, filePath).split(path.sep).join('/');
        if (frontMatter.traceability) {
          for (const linkType of ['DESIGN', 'IMPL', 'TEST'] as const) {
            const links = frontMatter.traceability[linkType];
            if (links) {
              for (const targetId of links) {
                if (!IdRegistry.isIdRegistered(targetId)) {
                  console.error(`❌ ${relFile}: Traceability link to unregistered ID '${targetId}' (${linkType}).`);
                  allValid = false;
                } else {
                  // Optionally add to traceability engine for matrix generation later
                  // TraceabilityEngine.addLink(frontMatter.id, targetId, linkType.toLowerCase() as any);
                }
              }
            }
          }
        }
      }

      if (allValid) {
        console.log('✅ All specifications validated successfully.');
      } else {
        console.error('❌ Some specifications failed validation.');
        process.exit(1);
      }
    });
}
