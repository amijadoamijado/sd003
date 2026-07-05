/**
 * Type Definitions
 */

import type { IdType } from '../spec-driven/id-registry';

/**
 * @deprecated Use `IdType` from `spec-driven/id-registry` (the canonical definition).
 * Kept as a type alias so existing imports of `IDType` keep compiling.
 */
export type IDType = IdType;

export type LogLevel = 'LOG' | 'ERROR' | 'WARN' | 'INFO';

export type QualityStage = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8;

export interface SpecMetadata {
  id: string;
  name: string;
  version: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Requirement {
  id: string;
  description: string;
  priority: 'high' | 'medium' | 'low';
}

export interface Design {
  id: string;
  requirementId: string;
  description: string;
}

export interface Implementation {
  id: string;
  designId: string;
  filePath: string;
}

export interface Test {
  id: string;
  implementationId: string;
  testPath: string;
}
