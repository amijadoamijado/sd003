// src/spec-driven/id-registry.ts

/**
 * Represents the type of an ID.
 */
export type IdType = 'REQ' | 'DESIGN' | 'IMPL' | 'TEST';

/**
 * Manages the generation, validation, and tracking of specification IDs.
 * IDs are formatted as TYPE-NNN (e.g., REQ-001, DESIGN-005).
 */
export class IdRegistry {
  private static registeredIds: Set<string> = new Set();
  private static nextIdCounters: Map<IdType, number> = new Map([
    ['REQ', 0],
    ['DESIGN', 0],
    ['IMPL', 0],
    ['TEST', 0],
  ]);

  /**
   * Generates a new unique ID of the specified type.
   * @param type The type of ID to generate (e.g., 'REQ', 'DESIGN').
   * @returns A new unique ID string (e.g., 'REQ-001').
   */
  static generateId(type: IdType): string {
    let counter = IdRegistry.nextIdCounters.get(type) || 0;
    let newId: string;
    do {
      counter++;
      newId = `${type}-${String(counter).padStart(3, '0')}`;
    } while (IdRegistry.registeredIds.has(newId));

    IdRegistry.nextIdCounters.set(type, counter);
    IdRegistry.registeredIds.add(newId);
    return newId;
  }

  /**
   * Validates if a given string is a valid ID format (TYPE-NNN).
   * @param id The ID string to validate.
   * @returns True if the ID is valid, false otherwise.
   */
  static isValidId(id: string): boolean {
    const idPattern = /^(REQ|DESIGN|IMPL|TEST)-\d{3}$/;
    return idPattern.test(id);
  }

  /**
   * Registers an existing ID. Useful for loading IDs from existing specifications.
   * @param id The ID string to register.
   * @returns True if the ID was successfully registered, false if it was already registered or invalid.
   */
  static registerId(id: string): boolean {
    if (!IdRegistry.isValidId(id)) {
      console.warn(`Attempted to register an invalid ID format: ${id}`);
      return false;
    }
    if (IdRegistry.registeredIds.has(id)) {
      console.warn(`ID '${id}' is already registered.`);
      return false;
    }

    const [typeStr, numStr] = id.split('-');
    const type = typeStr as IdType;
    const num = parseInt(numStr, 10);

    // Update the counter if the registered ID's number is higher
    const currentCounter = IdRegistry.nextIdCounters.get(type) || 0;
    if (num > currentCounter) {
      IdRegistry.nextIdCounters.set(type, num);
    }

    IdRegistry.registeredIds.add(id);
    return true;
  }

  /**
   * Checks if an ID is registered.
   * @param id The ID string to check.
   * @returns True if the ID is registered, false otherwise.
   */
  static isIdRegistered(id: string): boolean {
    return IdRegistry.registeredIds.has(id);
  }

  /**
   * Retrieves all registered IDs.
   * @returns An array of all registered ID strings.
   */
  static getAllIds(): string[] {
    return Array.from(IdRegistry.registeredIds).sort();
  }

  /**
   * Searches for IDs matching a given type or pattern.
   * @param query The type (e.g., 'REQ') or a partial string to search for.
   * @returns An array of matching ID strings.
   */
  static searchIds(query: string): string[] {
    const lowerQuery = query.toLowerCase();
    return Array.from(IdRegistry.registeredIds).filter(id =>
      id.toLowerCase().includes(lowerQuery)
    ).sort();
  }

  /**
   * Resets the registry for testing purposes.
   */
  static _reset(): void {
    IdRegistry.registeredIds.clear();
    IdRegistry.nextIdCounters.set('REQ', 0);
    IdRegistry.nextIdCounters.set('DESIGN', 0);
    IdRegistry.nextIdCounters.set('IMPL', 0);
    IdRegistry.nextIdCounters.set('TEST', 0);
  }
}