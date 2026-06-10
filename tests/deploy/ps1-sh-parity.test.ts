import fs from 'node:fs';
import path from 'node:path';

// Parity guard for the dual-implementation deploy scripts (deploy.ps1 / deploy.sh).
// Real production bug class being fixed here: the two scripts drift silently —
// deploy.sh shipped a settings.json skip-if-exists branch (fixed in 952ef66) and
// a CLAUDE.md skip-if-SD003 branch + missing materials/html (fixed 2026-06-10).
// These assertions extract behavior-defining constants from both scripts and
// fail when they drift again. Real-bug regression test, not coverage filler.

const repoRoot = path.resolve(__dirname, '..', '..');
const ps1 = fs.readFileSync(
  path.join(repoRoot, '.claude', 'skills', 'sd-deploy', 'deploy.ps1'),
  'utf8'
);
const sh = fs.readFileSync(
  path.join(repoRoot, '.claude', 'skills', 'sd-deploy', 'deploy.sh'),
  'utf8'
);

function extract(re: RegExp, text: string, label: string): string {
  const m = text.match(re);
  if (!m) throw new Error(`${label}: pattern not found: ${re}`);
  return m[1];
}

describe('deploy.ps1 / deploy.sh parity', () => {
  it('should declare the same SD003_VERSION in both scripts', () => {
    const ps1Version = extract(/\$SD003_VERSION\s*=\s*"([\d.]+)"/, ps1, 'deploy.ps1');
    const shVersion = extract(/^SD003_VERSION="([\d.]+)"/m, sh, 'deploy.sh');
    expect(shVersion).toBe(ps1Version);
  });

  it('should declare the same FRAMEWORK_VERSION in both scripts', () => {
    const ps1Version = extract(/\$FRAMEWORK_VERSION\s*=\s*"([\d.]+)"/, ps1, 'deploy.ps1');
    const shVersion = extract(/^FRAMEWORK_VERSION="([\d.]+)"/m, sh, 'deploy.sh');
    expect(shVersion).toBe(ps1Version);
  });

  it('should create the same materials/* directories in both scripts', () => {
    const ps1Dirs = [...ps1.matchAll(/"(materials\/[a-z]+)"/g)].map((m) => m[1]).sort();
    const shDirs = [...sh.matchAll(/"(materials\/[a-z]+)"/g)].map((m) => m[1]).sort();
    // materials/html omission in deploy.sh was a real drift found 2026-06-10.
    expect(ps1Dirs).toContain('materials/html');
    expect(shDirs).toEqual(ps1Dirs);
  });

  it('should wire the Phase 6b content-verification gate in both scripts', () => {
    expect(ps1).toMatch(/verify-deployment\.mjs/);
    expect(sh).toMatch(/verify-deployment\.mjs/);
  });

  it('should not preserve an outdated SD003-based CLAUDE.md (952ef66 bug class)', () => {
    // A skip-if-already-SD003 branch leaves stale framework wiring un-upgraded.
    // Bespoke files must be protected via .sd003-keep, never via content sniffing.
    expect(sh).not.toMatch(/grep -q "SD003".*CLAUDE\.md|CLAUDE\.md.*grep -q "SD003"/);
    expect(ps1).not.toMatch(/Select-String.*"SD003".*CLAUDE\.md/);
  });
});
