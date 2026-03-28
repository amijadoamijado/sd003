// src/cli/commands/spec-sync.ts

import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { IdRegistry } from '../../spec-driven/id-registry';
import { TraceabilityEngine, TraceLink } from '../../spec-driven/traceability-engine';

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

      const specFiles = fs.readdirSync(specDirPath).filter(file => file.endsWith('.md'));

      // Pass 1: Register all IDs
      for (const file of specFiles) {
        const filePath = path.join(specDirPath, file);
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const frontMatterMatch = fileContent.match(/^---\n([\s\S]*?)\n---/);

        if (frontMatterMatch) {
          try {
            const frontMatter = yaml.load(frontMatterMatch[1]) as SpecFrontMatter;
            if (frontMatter.id) {
              IdRegistry.registerId(frontMatter.id);
            }
          } catch (error: any) {
            console.error(`Error parsing YAML front matter in ${file}: ${error.message}`);
          }
        }
      }

      // Pass 2: Build traceability links
      for (const file of specFiles) {
        const filePath = path.join(specDirPath, file);
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const frontMatterMatch = fileContent.match(/^---\n([\s\S]*?)\n---/);

        if (frontMatterMatch) {
          try {
            const frontMatter = yaml.load(frontMatterMatch[1]) as SpecFrontMatter;
            if (frontMatter.id && frontMatter.traceability) {
              for (const linkType of ['DESIGN', 'IMPL', 'TEST']) {
                const links = (frontMatter.traceability as any)[linkType] as string[] | undefined;
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
          } catch (error: any) {
            console.error(`Error parsing YAML front matter in ${file} during traceability build: ${error.message}`);
          }
        }
      }

      console.log('✅ Specification synchronization complete.');
      console.log('Registered IDs:', IdRegistry.getAllIds().length);
      console.log('Traceability Links:', TraceabilityEngine.getAllLinks().length);
    });
}
