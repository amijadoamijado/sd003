// tests/integration/spec-workflow.test.ts

import { runCli } from '../../src/cli';
import * as fs from 'fs';
import * as path from 'path';
import { IdRegistry } from '../../src/spec-driven/id-registry';
import { TraceabilityEngine } from '../../src/spec-driven/traceability-engine';

// Mock process.argv for CLI testing
const mockArgv = (args: string[]) => {
  process.argv = ['node', 'sd002', ...args];
};

describe('Spec-Driven Workflow Integration', () => {
  const kiroDirPath = path.join(process.cwd(), '.kiro');
  const specsDirPath = path.join(kiroDirPath, 'specs');

  beforeEach(() => {
    // Clean up .kiro directory before each test
    if (fs.existsSync(kiroDirPath)) {
      fs.rmSync(kiroDirPath, { recursive: true, force: true });
    }
    fs.mkdirSync(specsDirPath, { recursive: true });

    // Reset registries
    IdRegistry._reset();
    TraceabilityEngine._reset();

    // Suppress console output during CLI execution
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'warn').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});

    // Mock process.exit to prevent it from terminating the test runner
    jest.spyOn(process, 'exit').mockImplementation((code?: any) => {
      throw new Error(`process.exit called with ${code}`);
    });
  });

  afterEach(() => {
    // Restore console output
    jest.restoreAllMocks();
    // Clean up .kiro directory after each test
    if (fs.existsSync(kiroDirPath)) {
      fs.rmSync(kiroDirPath, { recursive: true, force: true });
    }
  });

  it('should create a new specification document', async () => {
    mockArgv(['spec:create', 'My New Requirement']);
    await runCli();

    const files = fs.readdirSync(specsDirPath);
    expect(files.length).toBe(1);
    expect(files[0]).toMatch(/^REQ-001-my-new-requirement\.md$/);

    const filePath = path.join(specsDirPath, files[0]);
    const content = fs.readFileSync(filePath, 'utf8');
    expect(content).toContain('id: REQ-001');
    expect(content).toContain('name: My New Requirement');
    expect(content).toContain('type: REQ');
  });

  it('should validate a valid specification document', async () => {
    // Create a valid spec manually
    const specId = 'REQ-001';
    const specName = 'Valid Spec';
    const specFilePath = path.join(specsDirPath, `${specId}-${specName.toLowerCase().replace(/\s/g, '-')}.md`);
    const validSpecContent = `---
id: ${specId}
name: ${specName}
type: REQ
status: APPROVED
---
# ${specName}
`;
    fs.writeFileSync(specFilePath, validSpecContent);

    mockArgv(['spec:validate']);
    await runCli(); // Should not throw or exit with error
    expect(console.error).not.toHaveBeenCalled();
    expect(console.log).toHaveBeenCalledWith('✅ All specifications validated successfully.');
    expect(process.exit).not.toHaveBeenCalled();
  });

  it('should fail validation for an invalid specification document', async () => {
    // Create an invalid spec manually
    const specId = 'INVALID-ID';
    const specName = 'Invalid Spec';
    const specFilePath = path.join(specsDirPath, `invalid-spec.md`);
    const invalidSpecContent = `---
id: ${specId}
name: ${specName}
type: REQ
status: DRAFT
---
# ${specName}
`;
    fs.writeFileSync(specFilePath, invalidSpecContent);

    mockArgv(['spec:validate']);
    await expect(runCli()).rejects.toThrow('process.exit called with 1');
    expect(console.error).toHaveBeenCalledWith(expect.stringContaining(`❌ invalid-spec.md: Invalid ID format: ${specId}`));
    expect(process.exit).toHaveBeenCalledWith(1);
  });

  it('should synchronize specifications and update traceability', async () => {
    // Create a spec with traceability links
    const reqId = 'REQ-001';
    const designId = 'DESIGN-001';
    const implId = 'IMPL-001';

    const reqSpecPath = path.join(specsDirPath, `${reqId}-req.md`);
    const designSpecPath = path.join(specsDirPath, `${designId}-design.md`);
    const implSpecPath = path.join(specsDirPath, `${implId}-impl.md`);

    fs.writeFileSync(reqSpecPath, `---
id: ${reqId}
name: Req 1
type: REQ
status: DRAFT
traceability:
  DESIGN: [${designId}]
---`);
    fs.writeFileSync(designSpecPath, `---
id: ${designId}
name: Design 1
type: DESIGN
status: DRAFT
traceability:
  IMPL: [${implId}]
---`);
    fs.writeFileSync(implSpecPath, `---
id: ${implId}
name: Impl 1
type: IMPL
status: DRAFT
---`);

    mockArgv(['spec:sync']);
    await runCli();

    expect(console.log).toHaveBeenCalledWith('✅ Specification synchronization complete.');
    expect(IdRegistry.isIdRegistered(reqId)).toBe(true);
    expect(IdRegistry.isIdRegistered(designId)).toBe(true);
    expect(IdRegistry.isIdRegistered(implId)).toBe(true);

    const links = TraceabilityEngine.getAllLinks();
    expect(links.length).toBe(2);
    expect(links).toContainEqual({ sourceId: reqId, targetId: designId, type: 'implements' });
    expect(links).toContainEqual({ sourceId: designId, targetId: implId, type: 'implements' });
  });

  it('should list all specification documents', async () => {
    const specId1 = 'REQ-001';
    const specName1 = 'First Spec';
    const specFilePath1 = path.join(specsDirPath, `${specId1}-first-spec.md`);
    fs.writeFileSync(specFilePath1, `---
id: ${specId1}
name: ${specName1}
type: REQ
status: DRAFT
---`);

    const specId2 = 'DESIGN-001';
    const specName2 = 'Second Spec';
    const specFilePath2 = path.join(specsDirPath, `${specId2}-second-spec.md`);
    fs.writeFileSync(specFilePath2, `---
id: ${specId2}
name: ${specName2}
type: DESIGN
status: APPROVED
---`);

    mockArgv(['spec:list']);
    await runCli();

    expect(console.log).toHaveBeenCalledWith(expect.stringContaining(`ID: ${specId1}`));
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining(`  Name: ${specName1}`));
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining(`  Type: REQ`));
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining(`  Status: DRAFT`));
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining(`ID: ${specId2}`));
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining(`  Name: ${specName2}`));
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining(`  Type: DESIGN`));
    expect(console.log).toHaveBeenCalledWith(expect.stringContaining(`  Status: APPROVED`));
  });
});