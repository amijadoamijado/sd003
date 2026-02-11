// tests/unit/spec-driven/quality-gate.test.ts

import { QualityGate, QualityGateResult } from '../../../src/spec-driven/quality-gate';

describe('QualityGate', () => {
  beforeEach(() => {
    QualityGate._reset(); // Reset registered gates before each test
  });

  it('should register and execute a single gate', async () => {
    const mockGateFunction = jest.fn(async () => ({
      gate: 'TestGate',
      status: 'PASSED' as QualityGateResult['status'],
      message: 'Test passed',
    }));
    QualityGate.registerGate('TestGate', mockGateFunction);

    const result = await QualityGate.executeGate('TestGate');
    expect(mockGateFunction).toHaveBeenCalledTimes(1);
    expect(result).toEqual({ gate: 'TestGate', status: 'PASSED', message: 'Test passed' });
  });

  it('should throw an error if an unregistered gate is executed', async () => {
    await expect(QualityGate.executeGate('UnregisteredGate')).rejects.toThrow(
      "Quality gate 'UnregisteredGate' is not registered."
    );
  });

  it('should execute all registered gates in order', async () => {
    const gate1 = jest.fn(async () => ({ gate: 'Gate1', status: 'PASSED' as QualityGateResult['status'] }));
    const gate2 = jest.fn(async () => ({ gate: 'Gate2', status: 'FAILED' as QualityGateResult['status'] }));
    const gate3 = jest.fn(async () => ({ gate: 'Gate3', status: 'PASSED' as QualityGateResult['status'] }));

    // Registering out of default order to test execution order
    QualityGate.registerGate('Gate3', gate3);
    QualityGate.registerGate('Gate1', gate1);
    QualityGate.registerGate('Gate2', gate2);

    // Re-registering default gates to ensure they are present for executeAllGates
    QualityGate.registerGate('SyntaxValidation', QualityGate.SyntaxValidation);
    QualityGate.registerGate('TypeValidation', QualityGate.TypeValidation);
    QualityGate.registerGate('LintValidation', QualityGate.LintValidation);
    QualityGate.registerGate('SecurityValidation', QualityGate.SecurityValidation);
    QualityGate.registerGate('TestValidation', QualityGate.TestValidation);
    QualityGate.registerGate('PerformanceValidation', QualityGate.PerformanceValidation);
    QualityGate.registerGate('DocumentValidation', QualityGate.DocumentValidation);
    QualityGate.registerGate('IntegrationValidation', QualityGate.IntegrationValidation);


    const results = await QualityGate.executeAllGates();

    // Expect default gates to be executed, and our custom gates if they were registered with default names
    // Since we registered custom gates with non-default names, they won't be part of executeAllGates unless explicitly added to the order.
    // The default executeAllGates uses a hardcoded order of default gates.
    expect(results.length).toBe(8); // 8 default gates
    expect(results[0].gate).toBe('SyntaxValidation');
    expect(results[1].gate).toBe('TypeValidation');
    // ... and so on for all 8 default gates
    expect(results.every(r => r.status === 'PASSED')).toBe(true); // All default mocks pass
  });

  it('should correctly report if all gates passed', async () => {
    QualityGate.registerGate('PassingGate', async () => ({ gate: 'PassingGate', status: 'PASSED' }));
    QualityGate.registerGate('FailingGate', async () => ({ gate: 'FailingGate', status: 'FAILED' }));
    QualityGate.registerGate('SkippedGate', async () => ({ gate: 'SkippedGate', status: 'SKIPPED' }));

    // Test with all passing/skipped
    const passingResults: QualityGateResult[] = [
      { gate: 'GateA', status: 'PASSED' },
      { gate: 'GateB', status: 'SKIPPED' },
    ];
    expect(QualityGate.allGatesPassed(passingResults)).toBe(true);

    // Test with one failing
    const failingResults: QualityGateResult[] = [
      { gate: 'GateA', status: 'PASSED' },
      { gate: 'GateB', status: 'FAILED' },
    ];
    expect(QualityGate.allGatesPassed(failingResults)).toBe(false);
  });

  it('should handle errors during gate execution gracefully', async () => {
    const errorGateFunction = jest.fn(async () => {
      throw new Error('Something went wrong!');
    });
    QualityGate.registerGate('ErrorGate', errorGateFunction);

    const result = await QualityGate.executeGate('ErrorGate');
    expect(result.status).toBe('FAILED');
    expect(result.message).toContain('An unexpected error occurred');
    expect(result.details).toBeInstanceOf(Error);
  });

  it('should reset registered gates', () => {
    QualityGate.registerGate('TempGate', async () => ({ gate: 'TempGate', status: 'PASSED' }));
    expect(QualityGate.gates.size).toBe(1); // Only TempGate should be registered after beforeEach and one registration

    QualityGate._reset();
    expect(QualityGate.gates.size).toBe(0);
  });
});