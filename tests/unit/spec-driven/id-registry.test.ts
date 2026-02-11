// tests/unit/spec-driven/id-registry.test.ts

import { IdRegistry } from '../../../src/spec-driven/id-registry';

describe('IdRegistry', () => {
  beforeEach(() => {
    IdRegistry._reset(); // Reset the registry before each test
  });

  it('should generate unique IDs for each type', () => {
    const reqId1 = IdRegistry.generateId('REQ');
    const reqId2 = IdRegistry.generateId('REQ');
    const designId1 = IdRegistry.generateId('DESIGN');

    expect(reqId1).toMatch(/^REQ-\d{3}$/);
    expect(reqId2).toMatch(/^REQ-\d{3}$/);
    expect(designId1).toMatch(/^DESIGN-\d{3}$/);
    expect(reqId1).not.toBe(reqId2);
    expect(reqId1).not.toBe(designId1);
  });

  it('should validate correct ID formats', () => {
    expect(IdRegistry.isValidId('REQ-001')).toBe(true);
    expect(IdRegistry.isValidId('DESIGN-123')).toBe(true);
    expect(IdRegistry.isValidId('IMPL-000')).toBe(true);
    expect(IdRegistry.isValidId('TEST-999')).toBe(true);
  });

  it('should invalidate incorrect ID formats', () => {
    expect(IdRegistry.isValidId('REQ-1')).toBe(false); // Not 3 digits
    expect(IdRegistry.isValidId('REQ-0001')).toBe(false); // Too many digits
    expect(IdRegistry.isValidId('REQ_001')).toBe(false); // Wrong separator
    expect(IdRegistry.isValidId('UNKNOWN-001')).toBe(false); // Invalid type
    expect(IdRegistry.isValidId('001-REQ')).toBe(false); // Wrong order
    expect(IdRegistry.isValidId('REQ-ABC')).toBe(false); // Non-numeric part
  });

  it('should register and check for registered IDs', () => {
    const id = 'REQ-001';
    expect(IdRegistry.isIdRegistered(id)).toBe(false);
    expect(IdRegistry.registerId(id)).toBe(true);
    expect(IdRegistry.isIdRegistered(id)).toBe(true);
  });

  it('should not register duplicate IDs', () => {
    const id = 'REQ-001';
    IdRegistry.registerId(id);
    expect(IdRegistry.registerId(id)).toBe(false); // Should return false for duplicate
  });

  it('should update internal counter when registering an ID with a higher number', () => {
    IdRegistry.registerId('REQ-005');
    const newId = IdRegistry.generateId('REQ');
    expect(newId).toBe('REQ-006'); // Counter should have advanced past 005
  });

  it('should retrieve all registered IDs', () => {
    IdRegistry.registerId('REQ-001');
    IdRegistry.registerId('DESIGN-001');
    IdRegistry.registerId('REQ-002');
    const allIds = IdRegistry.getAllIds();
    expect(allIds).toEqual(['DESIGN-001', 'REQ-001', 'REQ-002']); // Should be sorted
  });

  it('should search for IDs by type or partial string', () => {
    IdRegistry.registerId('REQ-001');
    IdRegistry.registerId('DESIGN-001');
    IdRegistry.registerId('REQ-002');
    IdRegistry.registerId('IMPL-001');

    expect(IdRegistry.searchIds('REQ')).toEqual(['REQ-001', 'REQ-002']);
    expect(IdRegistry.searchIds('001')).toEqual(['DESIGN-001', 'IMPL-001', 'REQ-001']); // Sorted
    expect(IdRegistry.searchIds('IMPL')).toEqual(['IMPL-001']);
    expect(IdRegistry.searchIds('NONEXISTENT')).toEqual([]);
  });

  it('should reset the registry', () => {
    IdRegistry.generateId('REQ');
    IdRegistry.registerId('DESIGN-001');
    expect(IdRegistry.getAllIds().length).toBeGreaterThan(0);

    IdRegistry._reset();
    expect(IdRegistry.getAllIds().length).toBe(0);
    const newReqId = IdRegistry.generateId('REQ');
    expect(newReqId).toBe('REQ-001'); // Counter should be reset
  });
});