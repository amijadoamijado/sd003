// src/cli/commands/spec-list.ts

import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';
import { extractFrontMatter, findSpecMarkdownFiles } from '../../spec-driven/spec-file-utils';

interface SpecFrontMatter {
  id: string;
  name: string;
  type: string;
  status: string;
}

export function registerSpecListCommand(program: Command): void {
  program
    .command('spec:list')
    .description('List all specification documents in .sd/specs/')
    .action(async () => {
      console.log('Listing specifications...');
      const specDirPath = path.join(process.cwd(), '.sd', 'specs');

      if (!fs.existsSync(specDirPath)) {
        console.warn(`Specification directory not found: ${specDirPath}`);
        console.log('No specifications to list.');
        return;
      }

      const specFiles = findSpecMarkdownFiles(specDirPath);

      if (specFiles.length === 0) {
        console.log('No specification documents found.');
        return;
      }

      console.log('\n--- Specifications ---');
      specFiles.forEach(filePath => {
        const relFile = path.relative(specDirPath, filePath).split(path.sep).join('/');
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const frontMatterText = extractFrontMatter(fileContent);

        if (frontMatterText !== null) {
          try {
            const frontMatter = yaml.load(frontMatterText) as SpecFrontMatter;
            console.log(`ID: ${frontMatter.id || 'N/A'}`);
            console.log(`  Name: ${frontMatter.name || 'N/A'}`);
            console.log(`  Type: ${frontMatter.type || 'N/A'}`);
            console.log(`  Status: ${frontMatter.status || 'N/A'}`);
            console.log(`  File: ${relFile}`);
            console.log('--------------------');
          } catch (error: unknown) {
            const message = error instanceof Error ? error.message : String(error);
            console.error(`Error parsing YAML front matter in ${relFile}: ${message}`);
          }
        } else {
          console.log(`File: ${relFile} (Missing front matter)`);
          console.log('--------------------');
        }
      });
    });
}