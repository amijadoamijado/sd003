// tests/integration/quality-gate-integration.test.ts

import { runCli } from '../../src/cli';
import { QualityGate } from '../../src/spec-driven/quality-gate';

// Mock process.argv for CLI testing
const mockArgv = (args: string[]) => {
  process.argv = ['node', 'sd002', ...args];
};

describe('Quality Gate Integration', () => {
  let consoleLogSpy: jest.SpyInstance;
  let consoleErrorSpy: jest.SpyInstance;
  let processExitSpy: jest.SpyInstance;

  beforeEach(() => {
    QualityGate._reset(); // Ensure gates are reset
    // Re-register default gates as they are cleared by _reset()
    QualityGate.registerGate('SyntaxValidation', QualityGate.SyntaxValidation);
    QualityGate.registerGate('TypeValidation', QualityGate.TypeValidation);
    QualityGate.registerGate('LintValidation', QualityGate.LintValidation);
    QualityGate.registerGate('SecurityValidation', QualityGate.SecurityValidation);
    QualityGate.registerGate('TestValidation', QualityGate.TestValidation);
    QualityGate.registerGate('PerformanceValidation', QualityGate.PerformanceValidation);
    QualityGate.registerGate('DocumentValidation', QualityGate.DocumentValidation);
    QualityGate.registerGate('IntegrationValidation', QualityGate.IntegrationValidation);

    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    processExitSpy = jest.spyOn(process, 'exit').mockImplementation((code?: any) => {
      throw new Error(`process.exit called with ${code}`);
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should pass qa:deploy:safe if all gates pass', async () => {
    // All default mock gates pass by default
    mockArgv(['qa:deploy:safe']);
    await runCli();

    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('✅ All quality gates passed. Deployment is considered safe.'));
    expect(consoleErrorSpy).not.toHaveBeenCalled();
    expect(processExitSpy).not.toHaveBeenCalled();
  });

  it('should fail qa:deploy:safe if any gate fails', async () => {
    // Register a failing gate
    QualityGate.registerGate('FailingGate', async () => ({
      gate: 'FailingGate',
      status: 'FAILED',
      message: 'This gate intentionally failed.',
    }));

    // Temporarily override one of the default gates to fail
    QualityGate.registerGate('SyntaxValidation', async () => ({
      gate: 'SyntaxValidation',
      status: 'FAILED',
      message: 'Syntax error detected.',
    }));

    mockArgv(['qa:deploy:safe']);
    await expect(runCli()).rejects.toThrow('process.exit called with 1');

    expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('❌ Some quality gates failed. Deployment is NOT safe.'));
    expect(consoleErrorSpy).toHaveBeenCalledWith(expect.stringContaining('Syntax error detected.'));
    expect(processExitSpy).toHaveBeenCalledWith(1);
  });
});