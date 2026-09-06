import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const script = path.resolve(__dirname, '../../.codex/check-framework-version.py');

describe('read-only framework version check', () => {
  let fixture: string;
  const originalFiles = new Map<string, string>();

  beforeEach(() => {
    fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'sd003-version-'));
    originalFiles.clear();
  });

  afterEach(() => {
    try {
      for (const [file, content] of originalFiles) {
        expect(fs.readFileSync(file, 'utf8')).toBe(content);
      }
      const files = (directory: string): string[] => fs.readdirSync(directory, { withFileTypes: true })
        .flatMap(entry => entry.isDirectory() ? files(path.join(directory, entry.name)) : [path.join(directory, entry.name)]);
      expect(files(fixture).sort()).toEqual([...originalFiles.keys()].sort());
    } finally {
      fs.rmSync(fixture, { recursive: true, force: true });
    }
  });

  function makeProject(name: string, version: string, shVersion = version): string {
    const root = path.join(fixture, name);
    const directory = path.join(root, '.claude/skills/sd-deploy');
    fs.mkdirSync(directory, { recursive: true });
    for (const [filename, content] of [
      ['deploy.ps1', `\uFEFF$FRAMEWORK_VERSION = "${version}"\r\n`],
      ['deploy.sh', `FRAMEWORK_VERSION="${shVersion}"\n`],
    ]) {
      const file = path.join(directory, filename);
      fs.writeFileSync(file, content);
      originalFiles.set(file, content);
    }
    return root;
  }

  function check(project: string, source?: string, environmentSource = '') {
    const args = [script, '--project', project];
    if (source) args.push('--source', source);
    const run = spawnSync('python', args, {
      encoding: 'utf8', env: { ...process.env, SD003_SOURCE: environmentSource },
    });
    if (run.error) throw run.error;
    expect(run.stderr).toBe('');
    return { code: run.status, result: JSON.parse(run.stdout) };
  }

  it.each([
    ['2.19.1', '2.19.2', 'update_available'],
    ['2.19.2', '2.19.2', 'current'],
    ['2.20.0', '2.19.2', 'ahead'],
    ['2.9.0', '2.10.0', 'update_available'],
  ])('compares %s with %s as %s', (current, latest, status) => {
    const { code, result } = check(makeProject('project', current), makeProject('source', latest));
    expect(code).toBe(0);
    expect(result).toMatchObject({ status, currentVersion: current, latestVersion: latest });
  });

  it('reports unknown when deploy versions disagree', () => {
    const { code, result } = check(makeProject('project', '2.19.1'), makeProject('source', '2.19.2', '2.19.1'));
    expect(code).toBe(2);
    expect(result.status).toBe('unknown');
    expect(result.reason).toContain('disagree');
  });

  it('does not silently replace an explicitly missing source', () => {
    const { code, result } = check(makeProject('project', '2.19.1'), path.join(fixture, 'missing'));
    expect(code).toBe(2);
    expect(result.status).toBe('unknown');
  });

  it('uses explicit source before environment, and environment before sibling', () => {
    const project = makeProject('project', '2.19.1');
    const explicit = makeProject('source', '2.19.2');
    makeProject('sd003', '2.19.1');
    expect(check(project, explicit, path.join(fixture, 'missing')).result.status).toBe('update_available');
    expect(check(project, undefined, explicit).result.status).toBe('update_available');
    expect(check(project).result.status).toBe('current');
  });

  it('accepts the source itself as current', () => {
    const project = makeProject('sd003', '2.19.2');
    expect(check(project).result.status).toBe('current');
  });
});
