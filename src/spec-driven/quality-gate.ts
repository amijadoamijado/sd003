// src/spec-driven/quality-gate.ts

/**
 * Represents the result of a single quality gate check.
 */
export interface QualityGateResult {
  gate: string;
  status: 'PASSED' | 'FAILED' | 'SKIPPED';
  message?: string;
  details?: any;
}

/**
 * Manages an 8-stage quality gate system for SD002.
 * Each gate performs a specific validation to ensure code quality and compliance.
 */
export class QualityGate {
  public static gates: Map<string, (options?: any) => Promise<QualityGateResult>> = new Map();

  /**
   * Registers a quality gate function.
   * @param gateName The unique name of the gate (e.g., 'SyntaxValidation').
   * @param checkFunction The asynchronous function that performs the gate check.
   */
  static registerGate(gateName: string, checkFunction: (options?: any) => Promise<QualityGateResult>): void {
    if (QualityGate.gates.has(gateName)) {
      console.warn(`Quality gate '${gateName}' is already registered and will be overwritten.`);
    }
    QualityGate.gates.set(gateName, checkFunction);
  }

  /**
   * Executes a specific quality gate.
   * @param gateName The name of the gate to execute.
   * @param options Optional parameters for the gate check.
   * @returns The result of the quality gate check.
   * @throws If the specified gate is not registered.
   */
  static async executeGate(gateName: string, options?: any): Promise<QualityGateResult> {
    const checkFunction = QualityGate.gates.get(gateName);
    if (!checkFunction) {
      throw new Error(`Quality gate '${gateName}' is not registered.`);
    }
    try {
      return await checkFunction(options);
    } catch (error: any) {
      return {
        gate: gateName,
        status: 'FAILED',
        message: `An unexpected error occurred during gate execution: ${error.message}`,
        details: error,
      };
    }
  }

  /**
   * Executes all registered quality gates in a predefined order.
   * @param options Optional parameters to pass to all gate checks.
   * @returns An array of results for all executed quality gates.
   */
  static async executeAllGates(options?: any): Promise<QualityGateResult[]> {
    const results: QualityGateResult[] = [];
    const gateOrder: string[] = [
      'SyntaxValidation',
      'TypeValidation',
      'LintValidation',
      'SecurityValidation',
      'TestValidation',
      'PerformanceValidation',
      'DocumentValidation',
      'IntegrationValidation',
    ];

    for (const gateName of gateOrder) {
      if (QualityGate.gates.has(gateName)) {
        const result = await QualityGate.executeGate(gateName, options);
        results.push(result);
        if (result.status === 'FAILED') {
          console.error(`Quality gate '${gateName}' FAILED: ${result.message || 'No specific message provided.'}`);
          // Optionally stop on first failure, or continue to collect all failures
          // For now, we'll continue to collect all results.
        }
      } else {
        results.push({
          gate: gateName,
          status: 'SKIPPED',
          message: `Gate '${gateName}' is not registered.`,
        });
      }
    }
    return results;
  }

  /**
   * Checks if all executed gates have passed.
   * @param results An array of QualityGateResult objects.
   * @returns True if all gates passed, false otherwise.
   */
  static allGatesPassed(results: QualityGateResult[]): boolean {
    return results.every(result => result.status === 'PASSED' || result.status === 'SKIPPED');
  }

  /**
   * Resets the registered gates for testing purposes.
   */
  static _reset(): void {
    QualityGate.gates.clear();
  }

  // --- Pre-defined Quality Gate Implementations (Placeholders) ---

  /**
   * Placeholder for Syntax Validation Gate.
   */
  static async SyntaxValidation(): Promise<QualityGateResult> {
    // In a real scenario, this would invoke a TypeScript compiler check or similar.
    return { gate: 'SyntaxValidation', status: 'PASSED', message: 'Syntax check passed (mock).' };
  }

  /**
   * Placeholder for Type Validation Gate.
   */
  static async TypeValidation(): Promise<QualityGateResult> {
    // In a real scenario, this would involve running `tsc --noEmit`.
    return { gate: 'TypeValidation', status: 'PASSED', message: 'Type check passed (mock).' };
  }

  /**
   * Placeholder for Lint Validation Gate.
   */
  static async LintValidation(): Promise<QualityGateResult> {
    // In a real scenario, this would involve running ESLint.
    return { gate: 'LintValidation', status: 'PASSED', message: 'Lint check passed (mock).' };
  }

  /**
   * Placeholder for Security Validation Gate.
   */
  static async SecurityValidation(): Promise<QualityGateResult> {
    // In a real scenario, this would involve security scanning tools.
    return { gate: 'SecurityValidation', status: 'PASSED', message: 'Security check passed (mock).' };
  }

  /**
   * Placeholder for Test Validation Gate.
   */
  static async TestValidation(): Promise<QualityGateResult> {
    // In a real scenario, this would involve running unit/integration tests and checking coverage.
    return { gate: 'TestValidation', status: 'PASSED', message: 'Tests passed and coverage met (mock).' };
  }

  /**
   * Placeholder for Performance Validation Gate.
   */
  static async PerformanceValidation(): Promise<QualityGateResult> {
    // In a real scenario, this would involve performance profiling.
    return { gate: 'PerformanceValidation', status: 'PASSED', message: 'Performance metrics within limits (mock).' };
  }

  /**
   * Placeholder for Document Validation Gate.
   */
  static async DocumentValidation(): Promise<QualityGateResult> {
    // In a real scenario, this would involve checking documentation completeness and accuracy.
    return { gate: 'DocumentValidation', status: 'PASSED', message: 'Documentation check passed (mock).' };
  }

  /**
   * Placeholder for Integration Validation Gate.
   */
  static async IntegrationValidation(): Promise<QualityGateResult> {
    // In a real scenario, this would involve running E2E tests or deployment rehearsals.
    return { gate: 'IntegrationValidation', status: 'PASSED', message: 'Integration tests passed (mock).' };
  }
}

// Register the default gates
QualityGate.registerGate('SyntaxValidation', QualityGate.SyntaxValidation);
QualityGate.registerGate('TypeValidation', QualityGate.TypeValidation);
QualityGate.registerGate('LintValidation', QualityGate.LintValidation);
QualityGate.registerGate('SecurityValidation', QualityGate.SecurityValidation);
QualityGate.registerGate('TestValidation', QualityGate.TestValidation);
QualityGate.registerGate('PerformanceValidation', QualityGate.PerformanceValidation);
QualityGate.registerGate('DocumentValidation', QualityGate.DocumentValidation);
QualityGate.registerGate('IntegrationValidation', QualityGate.IntegrationValidation);