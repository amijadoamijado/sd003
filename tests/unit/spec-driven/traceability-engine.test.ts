// tests/unit/spec-driven/traceability-engine.test.ts

import { IdRegistry } from '../../../src/spec-driven/id-registry';
import { TraceabilityEngine } from '../../../src/spec-driven/traceability-engine';

describe('TraceabilityEngine', () => {
  beforeEach(() => {
    IdRegistry._reset();
    TraceabilityEngine._reset();

    // Register some IDs for testing
    IdRegistry.registerId('REQ-001');
    IdRegistry.registerId('REQ-002');
    IdRegistry.registerId('DESIGN-001');
    IdRegistry.registerId('DESIGN-002');
    IdRegistry.registerId('IMPL-001');
    IdRegistry.registerId('IMPL-002');
    IdRegistry.registerId('TEST-001');
    IdRegistry.registerId('TEST-002');
  });

  it('should add a traceability link between registered IDs', () => {
    expect(TraceabilityEngine.addLink('REQ-001', 'DESIGN-001', 'implements')).toBe(true);
    const links = TraceabilityEngine.getAllLinks();
    expect(links.length).toBe(1);
    expect(links[0]).toEqual({ sourceId: 'REQ-001', targetId: 'DESIGN-001', type: 'implements' });
  });

  it('should not add a link if source ID is not registered', () => {
    expect(TraceabilityEngine.addLink('REQ-999', 'DESIGN-001', 'implements')).toBe(false);
    expect(TraceabilityEngine.getAllLinks().length).toBe(0);
  });

  it('should not add a link if target ID is not registered', () => {
    expect(TraceabilityEngine.addLink('REQ-001', 'DESIGN-999', 'implements')).toBe(false);
    expect(TraceabilityEngine.getAllLinks().length).toBe(0);
  });

  it('should retrieve all added links', () => {
    TraceabilityEngine.addLink('REQ-001', 'DESIGN-001', 'implements');
    TraceabilityEngine.addLink('DESIGN-001', 'IMPL-001', 'implements');
    const links = TraceabilityEngine.getAllLinks();
    expect(links.length).toBe(2);
    expect(links).toEqual([
      { sourceId: 'REQ-001', targetId: 'DESIGN-001', type: 'implements' },
      { sourceId: 'DESIGN-001', targetId: 'IMPL-001', type: 'implements' },
    ]);
  });

  it('should generate a traceability matrix between specified types', () => {
    TraceabilityEngine.addLink('REQ-001', 'DESIGN-001', 'implements');
    TraceabilityEngine.addLink('REQ-001', 'DESIGN-002', 'implements');
    TraceabilityEngine.addLink('REQ-002', 'DESIGN-001', 'implements');
    TraceabilityEngine.addLink('DESIGN-001', 'IMPL-001', 'implements'); // Should not appear in REQ-DESIGN matrix

    const matrix = TraceabilityEngine.generateTraceabilityMatrix('REQ', 'DESIGN');
    expect(matrix.get('REQ-001')).toEqual(['DESIGN-001', 'DESIGN-002']);
    expect(matrix.get('REQ-002')).toEqual(['DESIGN-001']);
    expect(matrix.get('REQ-003')).toBeUndefined(); // Unregistered REQ
  });

  it('should analyze coverage for a given ID type', () => {
    TraceabilityEngine.addLink('REQ-001', 'DESIGN-001', 'implements');
    TraceabilityEngine.addLink('DESIGN-001', 'IMPL-001', 'implements');
    TraceabilityEngine.addLink('IMPL-001', 'TEST-001', 'tests');

    const reqCoverage = TraceabilityEngine.analyzeCoverage('REQ');
    expect(reqCoverage.covered).toEqual(['REQ-001']);
    expect(reqCoverage.uncovered).toEqual(['REQ-002']);

    const designCoverage = TraceabilityEngine.analyzeCoverage('DESIGN');
    expect(designCoverage.covered).toEqual(['DESIGN-001']);
    expect(designCoverage.uncovered).toEqual(['DESIGN-002']);

    const testCoverage = TraceabilityEngine.analyzeCoverage('TEST');
    expect(testCoverage.covered).toEqual(['TEST-001']);
    expect(testCoverage.uncovered).toEqual(['TEST-002']);
  });

  it('should reset the traceability engine', () => {
    TraceabilityEngine.addLink('REQ-001', 'DESIGN-001', 'implements');
    expect(TraceabilityEngine.getAllLinks().length).toBe(1);

    TraceabilityEngine._reset();
    expect(TraceabilityEngine.getAllLinks().length).toBe(0);
  });
});