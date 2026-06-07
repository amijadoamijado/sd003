import { execFileSync } from 'node:child_process';
import path from 'node:path';

// Regression coverage for the deploy content-verification gate.
// Reproduces commit 9f14984 (settings.json shipped with guardrails wired to Stop
// only, leaving PreToolUse empty = guardrails inert) and asserts the verifier
// hard-fails on it. This is a real-production-bug reproduction test (allowed under
// Real Data First / 柱3), NOT a coverage-for-coverage test.

const repoRoot = path.resolve(__dirname, '..', '..');
const verifier = path.join(repoRoot, 'scripts', 'verify-deployment.mjs');
const brokenFixture = path.join(repoRoot, 'tests', 'fixtures', 'deploy-broken-settings');

function runVerifier(targetDir: string): { code: number; out: string } {
  try {
    const out = execFileSync('node', [verifier, targetDir, repoRoot], {
      encoding: 'utf8',
    });
    return { code: 0, out };
  } catch (e) {
    const err = e as { status?: number; stdout?: string; stderr?: string };
    return { code: err.status ?? 1, out: `${err.stdout ?? ''}${err.stderr ?? ''}` };
  }
}

describe('verify-deployment gate', () => {
  it('hard-fails on a Stop-only settings.json (9f14984 reproduction)', () => {
    const { code, out } = runVerifier(brokenFixture);
    expect(code).toBe(1);
    // The empty/missing PreToolUse event must be reported.
    expect(out).toContain('PreToolUse');
    // At least one core guardrail hook must be flagged as not deployed.
    expect(out).toContain('block-edit-write-on-sd.sh');
  });

  it('passes on the SD003 repo itself (healthy wiring)', () => {
    const { code, out } = runVerifier(repoRoot);
    expect(code).toBe(0);
    expect(out).toContain('Content verification PASSED');
  });
});
