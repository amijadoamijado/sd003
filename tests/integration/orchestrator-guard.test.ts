import { spawnSync } from 'child_process';
import path from 'path';

const guard = path.resolve(__dirname, '../../scripts/orchestrator-guard.js');

function checkPayload(payload: object): { decision?: string; reason?: string } {
  const result = spawnSync(process.execPath, [guard], {
    input: JSON.stringify(payload),
    encoding: 'utf8',
  });
  expect(result.status).toBe(0);
  if (!result.stdout) return {};
  const output = JSON.parse(result.stdout) as { hookSpecificOutput: { permissionDecision: string; permissionDecisionReason: string } };
  return { decision: output.hookSpecificOutput.permissionDecision, reason: output.hookSpecificOutput.permissionDecisionReason };
}

function check(command: string): { decision?: string; reason?: string } {
  return checkPayload({ tool_name: 'shell_command', tool_input: { command } });
}

describe('shared orchestrator hook guard', () => {
  test.each([
    'clasp undeploy abc',
    'clasp deploy',
    'git add -A',
    'git add --all',
    'git reset --hard',
    'git -C D:\\project reset --hard',
    'git clean -fd',
    'git stash push',
    'Remove-Item -Recurse .sd',
    'Move-Item .sd backup',
    'cmd /c rd /s /q .sd',
  ])('blocks %s', command => expect(check(command).decision).toBe('deny'));

  test.each([
    'clasp push',
    'clasp deployments',
    'git add -- src/example.ts',
    'git status --short',
  ])('allows %s', command => expect(check(command).decision).toBeUndefined());

  test('allows patch text that only documents prohibited shell commands', () => {
    const patch = [
      '*** Begin Patch',
      '*** Add File: docs/example.md',
      '+Never run clasp undeploy or git reset --hard.',
      '*** End Patch',
    ].join('\n');
    expect(
      checkPayload({ tool_name: 'apply_patch', tool_input: { command: patch } }).decision,
    ).toBeUndefined();
  });

  test('blocks a structurally destructive patch against .sd', () => {
    const patch = [
      '*** Begin Patch',
      '*** Delete File: D:\\project\\.sd\\specs\\sample\\spec.md',
      '*** End Patch',
    ].join('\n');
    expect(
      checkPayload({ tool_name: 'apply_patch', tool_input: { command: patch } }).decision,
    ).toBe('deny');
  });
});
