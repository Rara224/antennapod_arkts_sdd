/**
 * Utility for serializing/deserializing Set<string> to/from JSON strings
 * for database TEXT column storage.
 */
export class JsonUtils {
  /**
   * Converts a Set<string> to a JSON string for DB storage.
   */
  static setToJson(set: Set<string>): string {
    return JSON.stringify(Array.from(set));
  }

  /**
   * Converts a JSON string back to a Set<string>.
   * Returns empty Set on parse error.
   */
  static jsonToSet(json: string): Set<string> {
    if (json.length === 0) {
      return new Set<string>();
    }
    try {
      const parsed: Object = JSON.parse(json);
      if (Array.isArray(parsed)) {
        const arr: string[] = [];
        for (let i = 0; i < parsed.length; i++) {
          const item: Object = parsed[i];
          if (typeof item === 'string') {
            arr.push(item);
          }
        }
        return new Set<string>(arr);
      }
      return new Set<string>();
    } catch (e) {
      return new Set<string>();
    }
  }
}
