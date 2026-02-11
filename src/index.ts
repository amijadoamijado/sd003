/**
 * SD002 Framework Entry Point
 *
 * Spec-Driven Development with GAS Local Testing Integration
 *
 * @packageDocumentation
 */

// Core exports from SD001
export * from './spec-driven/id-registry';
export * from './spec-driven/traceability-engine';
export * from './spec-driven/quality-gate';

// Core exports from GA001
export * from './interfaces/IEnv';
export * from './env/LocalEnv';
export * from './env/GasEnv';

// Mock services from GA001
export * from './mocks';

// SD002 specific exports
// export * from './core/workflow';
export * from './cli';
// export * from './gas-integration/deployer';

// Types
export * from './types';

/**
 * SD002 Framework version
 */
export const VERSION = '1.0.0';

/**
 * Framework metadata
 */
export const METADATA = {
  name: 'SD002 Framework',
  version: VERSION,
  description: 'Spec-Driven Development with GAS Local Testing Integration',
  author: 'SD002 Team',
  license: 'MIT',
  integrations: {
    sd001: '3.0.0',
    ga001: '1.3.0'
  }
} as const;
