// src/cli/commands/spec-list.ts

import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'js-yaml';

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

      const specFiles = fs.readdirSync(specDirPath).filter(file => file.endsWith('.md'));

      if (specFiles.length === 0) {
        console.log('No specification documents found.');
        return;
      }

      console.log('\n--- Specifications ---');
      specFiles.forEach(file => {
        const filePath = path.join(specDirPath, file);
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const frontMatterMatch = fileContent.match(/^---\n([\s\S]*?)\n---/);

        if (frontMatterMatch) {
          try {
            const frontMatter = yaml.load(frontMatterMatch[1]) as SpecFrontMatter;
            console.log(`ID: ${frontMatter.id || 'N/A'}`);
            console.log(`  Name: ${frontMatter.name || 'N/A'}`);
            console.log(`  Type: ${frontMatter.type || 'N/A'}`);
            console.log(`  Status: ${frontMatter.status || 'N/A'}`);
            console.log(`  File: ${file}`);
            console.log('--------------------');
          } catch (error: any) {
            console.error(`Error parsing YAML front matter in ${file}: ${error.message}`);
          }
        } else {
          console.log(`File: ${file} (Missing front matter)`);
          console.log('--------------------');
        }
      });
    });
}