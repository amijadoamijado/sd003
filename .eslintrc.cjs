// ESLint config for the SD003 framework (src/ TypeScript).
//
// Purpose: make `npm run lint` / the `qa:deploy:safe` LintValidation gate a REAL,
// honest check. Before this file existed, `eslint src/**/*.ts` hard-errored with
// "No ESLint configuration found", so the gate was permanently FAILED (not because
// the code was bad — because eslint could not run at all).
//
// Ruleset = eslint:recommended + @typescript-eslint/recommended, tuned to the
// project's stated minimum bar (Silent Interior: strict TS, no `any`, no @ts-ignore).
// Stylistic preference is intentionally NOT enforced here — the gate checks
// correctness-relevant rules only, so it stays green on clean code and does not
// force a large cosmetic cleanup.
module.exports = {
  root: true,
  env: { node: true, es2022: true, jest: true },
  parser: '@typescript-eslint/parser',
  parserOptions: { ecmaVersion: 2022, sourceType: 'module' },
  plugins: ['@typescript-eslint'],
  extends: ['eslint:recommended', 'plugin:@typescript-eslint/recommended'],
  ignorePatterns: ['dist/', 'node_modules/', 'coverage/', '*.js', '*.cjs', '*.mjs'],
  rules: {
    // TypeScript already resolves symbols/imports; the base rules produce false
    // positives on TS syntax and duplicate tsc's job.
    'no-undef': 'off',
    'no-unused-vars': 'off',
    '@typescript-eslint/no-unused-vars': [
      'error',
      { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' },
    ],
    // Minimum bar (see .claude/rules/global/silent-interior.md): no lazy `any`,
    // no @ts-ignore/@ts-nocheck escape hatches.
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/ban-ts-comment': 'error',
    // This is a CLI framework; stdout IS the product output (Output Primacy CLI
    // exception), so console is a legitimate sink, not a debugging leftover.
    'no-console': 'off',
  },
  overrides: [
    {
      // GAS boundary layer: mirrors the untyped Google Apps Script runtime
      // (injected globals + spreadsheet cell values, which GAS itself returns as
      // `any`). `any` here is the documented Env Interface exception, not lazy
      // typing. Business logic (spec-driven/, cli/) stays strict.
      files: ['src/env/**/*.ts', 'src/interfaces/**/*.ts', 'src/mocks/**/*.ts'],
      rules: { '@typescript-eslint/no-explicit-any': 'off' },
    },
  ],
};
