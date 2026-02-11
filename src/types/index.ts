/**
 * Type Definitions
 */

export type IDType = 'REQ' | 'DESIGN' | 'IMPL' | 'TEST';

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
