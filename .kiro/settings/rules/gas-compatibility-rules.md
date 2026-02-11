# GAS Compatibility Rules

## GAS Environment Constraints
- ❌ **FORBIDDEN**: Node.js-specific modules (`fs`, `path`, `process`, `crypto`, `http`)
- ❌ **FORBIDDEN**: ES6 module syntax in GAS runtime code
- ❌ **FORBIDDEN**: Async/await in some GAS contexts (check compatibility)
- ❌ **FORBIDDEN**: Global scope pollution
- ✅ **REQUIRED**: Use Env Interface Pattern for all GAS API access

## Env Interface Pattern
- ✅ **REQUIRED**: All business logic must depend on `IEnv` interface
- ✅ **REQUIRED**: Never directly reference `SpreadsheetApp`, `DriveApp`, etc.
- ✅ **REQUIRED**: Use `LocalEnv` for local development
- ✅ **REQUIRED**: Use `GasEnv` for GAS runtime
- ✅ **REQUIRED**: Ensure 100% compatibility between `LocalEnv` and `GasEnv`

## Code Example (Correct)
\`\`\`typescript
// ✅ CORRECT: Using IEnv interface
export function processData(env: IEnv, data: string[]): void {
  const sheet = env.spreadsheet.getActiveSheet();
  const logger = env.logger;
  // Business logic that works in both environments
}
\`\`\`

## Code Example (Incorrect)
\`\`\`typescript
// ❌ WRONG: Direct GAS API access
export function processData(data: string[]): void {
  const sheet = SpreadsheetApp.getActiveSheet(); // Breaks in local env
  Logger.log("Processing"); // Not mockable
}
\`\`\`

## Pre-Deployment Checklist
- [ ] No Node.js-specific modules used
- [ ] All GAS API access through `IEnv` interface
- [ ] All code tested in `LocalEnv` environment
- [ ] All quality gates passed
- [ ] E2E tests simulate GAS environment
- [ ] No direct global scope access
- [ ] Compatible with GAS 6-minute execution limit
- [ ] Memory usage within GAS limits
