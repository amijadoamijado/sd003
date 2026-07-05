// src/cli/commands/spec-sync.ts

import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { IdRegistry } from '../../spec-driven/id-registry';
import { TraceabilityEngine, TraceLink } from '../../spec-driven/traceability-engine';
import { extractFrontMatter, findSpecMarkdownFiles } from '../../spec-driven/spec-file-utils';

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

export function registerSpecSyncCommand(program: Command): void {
  program
    .command('spec:sync')
    .description('Synchronize specification documents and update traceability')
    .action(async () => {
      console.log('Starting specification synchronization...');
      const specDirPath = path.join(process.cwd(), '.sd', 'specs');

      if (!fs.existsSync(specDirPath)) {
        console.warn(`Specification directory not found: ${specDirPath}`);
        console.log('Synchronization skipped.');
        return;
      }

      // Reset registries before synchronization
      IdRegistry._reset();
      TraceabilityEngine._reset();

      const specFiles = findSpecMarkdownFiles(specDirPath);

      // Pass 1: Register all IDs
      for (const filePath of specFiles) {
        const relFile = path.relative(specDirPath, filePath).split(path.sep).join('/');
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const frontMatterText = extractFrontMatter(fileContent);

        if (frontMatterText !== null) {
          try {
            const frontMatter = yaml.load(frontMatterText) as SpecFrontMatter;
            if (frontMatter.id) {
              IdRegistry.registerId(frontMatter.id);
            }
          } catch (error: unknown) {
            const message = error instanceof Error ? error.message : String(error);
            console.error(`Error parsing YAML front matter in ${relFile}: ${message}`);
          }
        }
      }

      // Pass 2: Build traceability links
      for (const filePath of specFiles) {
        const relFile = path.relative(specDirPath, filePath).split(path.sep).join('/');
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const frontMatterText = extractFrontMatter(fileContent);

        if (frontMatterText !== null) {
          try {
            const frontMatter = yaml.load(frontMatterText) as SpecFrontMatter;
            if (frontMatter.id && frontMatter.traceability) {
              for (const linkType of ['DESIGN', 'IMPL', 'TEST'] as const) {
                const links = frontMatter.traceability[linkType];
                if (links) {
                  let actualLinkType: TraceLink['type'] = 'relatesTo';
                  if (linkType === 'DESIGN' || linkType === 'IMPL') {
                    actualLinkType = 'implements';
                  } else if (linkType === 'TEST') {
                    actualLinkType = 'tests';
                  }
                  for (const targetId of links) {
                    TraceabilityEngine.addLink(frontMatter.id, targetId, actualLinkType);
                  }
                }
              }
            }
          } catch (error: unknown) {
            const message = error instanceof Error ? error.message : String(error);
            console.error(`Error parsing YAML front matter in ${relFile} during traceability build: ${message}`);
          }
        }
      }

      console.log('✅ Specification synchronization complete.');
      console.log('Registered IDs:', IdRegistry.getAllIds().length);
      console.log('Traceability Links:', TraceabilityEngine.getAllLinks().length);
    });
}
