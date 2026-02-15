import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const projectRoot = path.resolve(__dirname, '..');
const claudeCommandsDir = path.join(projectRoot, '.claude', 'commands');
const claudeSkillsDir = path.join(projectRoot, '.claude', 'skills');
const geminiCommandsDir = path.join(projectRoot, '.gemini', 'commands');
const geminiSkillsDir = path.join(projectRoot, '.gemini', 'skills');

async function ensureDir(dir) {
  await fs.mkdir(dir, { recursive: true });
}

async function listFiles(dir, ext = '') {
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    let files = [];
    for (const entry of entries) {
      const res = path.resolve(dir, entry.name);
      if (entry.isDirectory()) {
        files = [...files, ...(await listFiles(res, ext))];
      } else if (!ext || entry.name.endsWith(ext)) {
        files.push(res);
      }
    }
    return files;
  } catch (e) {
    return [];
  }
}

async function syncCommands() {
  console.log('Syncing commands...');
  await ensureDir(geminiCommandsDir);
  const mdFiles = await listFiles(claudeCommandsDir, '.md');

  for (const mdFile of mdFiles) {
    const relPath = path.relative(claudeCommandsDir, mdFile);
    // Port to toml name, handling subdirectories
    const tomlName = relPath.replace(/[\\\/]/g, '-').replace(/\.md$/, '.toml');
    const tomlPath = path.join(geminiCommandsDir, tomlName);

    const content = await fs.readFile(mdFile, 'utf8').then(s => s.replace(/\r\n/g, '\n'));
    // Regex for frontmatter, allowing for optional markers before it
    const frontmatterMatch = content.match(/(?:^|[\s\S]*?\n)---\n([\s\S]*?)\n---(?:\n|$)/);
    let description = 'No description';
    let body = content;

    if (frontmatterMatch) {
      const frontmatter = frontmatterMatch[1];
      const descMatch = frontmatter.match(/description:\s*(.*)/);
      if (descMatch) {
        description = descMatch[1].trim().replace(/^"|"$/g, '');
      }
      // Remove everything up to and including the closing --- of the frontmatter
      body = content.substring(frontmatterMatch.index + frontmatterMatch[0].length).trim();
    }

    // Escape backslashes and double quotes for TOML basic string
    const escapedBody = body.replace(/\\/g, '\\\\').replace(/"/g, '\\"');

    const finalTomlContent = `description = ${JSON.stringify(description)}
prompt = """
${escapedBody}
"""
`;

    await fs.writeFile(tomlPath, finalTomlContent, 'utf8');
    console.log(`  Synced: ${relPath} -> ${tomlName}`);
  }
}

async function syncSkills() {
  console.log('Syncing skills...');
  await ensureDir(geminiSkillsDir);
  
  if (!(await fs.access(claudeSkillsDir).then(() => true).catch(() => false))) {
    console.log('  No Claude skills found.');
    return;
  }

  const skills = await fs.readdir(claudeSkillsDir, { withFileTypes: true });
  for (const skillEntry of skills) {
    if (skillEntry.isDirectory()) {
      const skillName = skillEntry.name;
      const sourceSkillDir = path.join(claudeSkillsDir, skillName);
      const targetSkillDir = path.join(geminiSkillsDir, skillName);
      
      const skillMdPath = path.join(sourceSkillDir, 'SKILL.md');
      try {
        await fs.access(skillMdPath);
        await ensureDir(targetSkillDir);
        
        // Copy all files in the skill directory
        const entries = await fs.readdir(sourceSkillDir, { withFileTypes: true });
        for (const entry of entries) {
          const src = path.join(sourceSkillDir, entry.name);
          const dest = path.join(targetSkillDir, entry.name);
          if (entry.isDirectory()) {
            await fs.cp(src, dest, { recursive: true });
          } else {
            await fs.copyFile(src, dest);
          }
        }
        
        console.log(`  Synced skill: ${skillName}`);
      } catch (e) {
        // SKILL.md doesn't exist, skip
      }
    }
  }
}

async function main() {
  await syncCommands();
  await syncSkills();
  console.log('Done!');
}

main().catch(console.error);
