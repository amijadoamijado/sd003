# Code Quality Rules

## TypeScript Rules
- ✅ Strict mode must be enabled
- ✅ All functions must have explicit return types
- ✅ No `any` types allowed (use `unknown` instead)
- ✅ No unused variables or imports
- ✅ Prefer `const` over `let`, never use `var`

## Naming Conventions
- ✅ Classes: PascalCase (e.g., `MockSpreadsheetApp`)
- ✅ Files: kebab-case (e.g., `spreadsheet-app.mock.ts`)
- ✅ Interfaces: `I` prefix or `Type` suffix
- ✅ Constants: UPPER_SNAKE_CASE
- ✅ Functions/Variables: camelCase

## Code Organization
- ✅ One class per file
- ✅ Maximum function length: 50 lines
- ✅ Maximum file length: 300 lines
- ✅ Group related functions together
- ✅ Exports at bottom of file

## Testing Requirements
- ✅ Unit test coverage ≥80%
- ✅ Integration test coverage ≥70%
- ✅ E2E tests for critical user paths
- ✅ All tests must pass before commit
- ✅ No skipped or disabled tests in main branch

## Documentation Requirements
- ✅ JSDoc comments for all public APIs
- ✅ Inline comments for complex logic
- ✅ README for each major module
- ✅ Examples in documentation
- ✅ Keep documentation up-to-date

## Error Handling
- ✅ All errors must be caught and handled
- ✅ Use custom error types for domain errors
- ✅ Log errors with context
- ✅ Never swallow errors silently
- ✅ Provide meaningful error messages
