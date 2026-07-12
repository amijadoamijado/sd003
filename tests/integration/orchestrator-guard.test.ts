import { spawnSync } from 'child_process';
import path from 'path';

const guard = path.resolve(__dirname, '../../scripts/orchestrator-guard.js');

function check(command: string): { decision?: string; reason?: string } {
  const result = spawnSync(process.execPath, [guard], {
    input: JSON.stringify({ tool_input: { command } }),
    encoding: 'utf8',
  });
  expect(result.status).toBe(0);
  if (!result.stdout) return {};
  const output = JSON.parse(result.stdout) as { hookSpecificOutput: { permissionDecision: string; permissionDecisionReason: string } };
  return { decision: output.hookSpecificOutput.permissionDecision, reason: output.hookSpecificOutput.permissionDecisionReason };
}

describe('shared orchestrator hook guard', () => {
  test.each([
    'clasp undeploy abc',
    'clasp deploy',
    'git add -A',
    'git reset --hard',
    'git clean -fd',
    'Remove-Item -Recurse .sd',
  ])('blocks %s', command => expect(check(command).decision).toBe('deny'));

  test.each([
    'clasp push',
    'clasp deployments',
    'git add -- src/example.ts',
    'git status --short',
  ])('allows %s', command => expect(check(command).decision).toBeUndefined());
});
