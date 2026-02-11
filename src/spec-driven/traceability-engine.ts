// src/spec-driven/traceability-engine.ts

import { IdRegistry, IdType } from './id-registry';

/**
 * Represents a link between two IDs.
 */
export interface TraceLink {
  sourceId: string;
  targetId: string;
  type: 'implements' | 'tests' | 'relatesTo'; // Example link types
}

/**
 * Manages traceability between different specification artifacts (requirements, design, implementation, tests).
 */
export class TraceabilityEngine {
  private static links: TraceLink[] = [];

  /**
   * Adds a traceability link between two IDs.
   * Both IDs must be registered in the IdRegistry.
   * @param sourceId The ID of the source artifact.
   * @param targetId The ID of the target artifact.
   * @param type The type of relationship between the IDs.
   * @returns True if the link was added, false if either ID is not registered.
   */
  static addLink(sourceId: string, targetId: string, type: TraceLink['type'] = 'relatesTo'): boolean {
    if (!IdRegistry.isIdRegistered(sourceId)) {
      console.warn(`Source ID '${sourceId}' is not registered. Link not added.`);
      return false;
    }
    if (!IdRegistry.isIdRegistered(targetId)) {
      console.warn(`Target ID '${targetId}' is not registered. Link not added.`);
      return false;
    }

    const newLink: TraceLink = { sourceId, targetId, type };
    TraceabilityEngine.links.push(newLink);
    return true;
  }

  /**
   * Retrieves all traceability links.
   * @returns An array of all registered TraceLink objects.
   */
  static getAllLinks(): TraceLink[] {
    return [...TraceabilityEngine.links];
  }

  /**
   * Generates a traceability matrix for a given ID type.
   * This is a simplified representation; a full matrix would be more complex.
   * @param sourceType The type of source ID to build the matrix from.
   * @param targetType The type of target ID to link to.
   * @returns A map where keys are source IDs and values are arrays of linked target IDs.
   */
  static generateTraceabilityMatrix(sourceType: IdType, targetType: IdType): Map<string, string[]> {
    const matrix = new Map<string, string[]>();
    const sourceIds = IdRegistry.getAllIds().filter(id => id.startsWith(sourceType));


    sourceIds.forEach(sId => {
      const linkedTargets: string[] = [];
      TraceabilityEngine.links.forEach(link => {
        if (link.sourceId === sId && link.targetId.startsWith(targetType)) {
          linkedTargets.push(link.targetId);
        }
      });
      matrix.set(sId, linkedTargets.sort());
    });

    return matrix;
  }

  /**
   * Performs coverage analysis for a given ID type, checking if all IDs of that type are linked.
   * @param type The ID type to analyze for coverage.
   * @returns An object containing covered and uncovered IDs.
   */
  static analyzeCoverage(type: IdType): { covered: string[]; uncovered: string[] } {
    const allIdsOfType = IdRegistry.getAllIds().filter(id => id.startsWith(type));
    const coveredIds = new Set<string>();

    TraceabilityEngine.links.forEach(link => {
      if (link.sourceId.startsWith(type)) {
        coveredIds.add(link.sourceId);
      }
      if (link.targetId.startsWith(type)) {
        coveredIds.add(link.targetId);
      }
    });

    const uncoveredIds = allIdsOfType.filter(id => !coveredIds.has(id));

    return {
      covered: Array.from(coveredIds).sort(),
      uncovered: uncoveredIds.sort(),
    };
  }

  /**
   * Resets the engine for testing purposes.
   */
  static _reset(): void {
    TraceabilityEngine.links = [];
  }
}