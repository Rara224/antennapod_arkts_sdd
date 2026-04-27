import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'DateParser';

const MONTH_MAP: Map<string, number> = new Map([
  ['jan', 0], ['feb', 1], ['mar', 2], ['apr', 3],
  ['may', 4], ['jun', 5], ['jul', 6], ['aug', 7],
  ['sep', 8], ['oct', 9], ['nov', 10], ['dec', 11]
]);

export class DateParser {
  /**
   * Parse RFC 822 or ISO 8601 date string to timestamp ms. Returns 0 on failure.
   */
  static parseDate(dateStr: string): number {
    if (dateStr.length === 0) {
      return 0;
    }
    // ISO 8601 (contains 'T')
    if (dateStr.indexOf('T') >= 0) {
      return DateParser.parseIso8601(dateStr);
    }
    // RFC 822
    const rfc = DateParser.parseRfc822(dateStr);
    if (rfc > 0) {
      return rfc;
    }
    // Fallback: Date.parse
    const fallback = Date.parse(dateStr);
    if (!isNaN(fallback)) {
      return fallback;
    }
    hilog.warn(DOMAIN, TAG, 'Failed to parse date: %{public}s', dateStr);
    return 0;
  }

  /**
   * Parse RFC 822: "Mon, 15 Mar 2026 10:30:00 GMT"
   */
  static parseRfc822(dateStr: string): number {
    let working = dateStr.trim();
    const commaIdx = working.indexOf(',');
    if (commaIdx >= 0 && commaIdx < 5) {
      working = working.substring(commaIdx + 1).trim();
    }
    const parts = working.split(' ');
    if (parts.length < 4) {
      return 0;
    }
    const day = parseInt(parts[0]);
    const monthStr = parts[1].toLowerCase().substring(0, 3);
    const month = MONTH_MAP.get(monthStr);
    if (month === undefined || isNaN(day)) {
      return 0;
    }
    let year = parseInt(parts[2]);
    if (isNaN(year)) {
      return 0;
    }
    if (year < 100) {
      year += year < 70 ? 2000 : 1900;
    }
    let hours = 0;
    let minutes = 0;
    let seconds = 0;
    if (parts.length >= 4 && parts[3].indexOf(':') >= 0) {
      const timeParts = parts[3].split(':');
      hours = parseInt(timeParts[0]);
      minutes = timeParts.length > 1 ? parseInt(timeParts[1]) : 0;
      seconds = timeParts.length > 2 ? parseInt(timeParts[2]) : 0;
      if (isNaN(hours)) hours = 0;
      if (isNaN(minutes)) minutes = 0;
      if (isNaN(seconds)) seconds = 0;
    }
    const date = new Date(Date.UTC(year, month, day, hours, minutes, seconds));
    if (parts.length >= 5) {
      const offsetMs = DateParser.parseTzOffset(parts[4]);
      return date.getTime() - offsetMs;
    }
    return date.getTime();
  }

  /**
   * Parse ISO 8601: "2026-03-15T10:30:00Z"
   */
  static parseIso8601(dateStr: string): number {
    const result = Date.parse(dateStr);
    if (!isNaN(result)) {
      return result;
    }
    return 0;
  }

  private static parseTzOffset(tz: string): number {
    if (tz === 'GMT' || tz === 'UTC' || tz === 'Z' || tz === 'UT') {
      return 0;
    }
    if (tz === 'EST' || tz === 'EDT') return -5 * 3600000;
    if (tz === 'CST' || tz === 'CDT') return -6 * 3600000;
    if (tz === 'MST' || tz === 'MDT') return -7 * 3600000;
    if (tz === 'PST' || tz === 'PDT') return -8 * 3600000;

    if (tz.startsWith('+') || tz.startsWith('-')) {
      const sign = tz.startsWith('+') ? 1 : -1;
      let offsetStr = tz.substring(1).replace(':', '');
      if (offsetStr.length >= 4) {
        const h = parseInt(offsetStr.substring(0, 2));
        const m = parseInt(offsetStr.substring(2, 4));
        if (!isNaN(h) && !isNaN(m)) {
          return sign * (h * 3600000 + m * 60000);
        }
      }
    }
    return 0;
  }

  /**
   * Parse iTunes duration string to milliseconds.
   * "3600" → 3600000, "1:00:00" → 3600000, "30:00" → 1800000
   */
  static parseDuration(durationStr: string): number {
    if (durationStr.length === 0) {
      return 0;
    }
    const trimmed = durationStr.trim();
    if (trimmed.indexOf(':') < 0) {
      const secs = parseInt(trimmed);
      if (!isNaN(secs) && secs >= 0) {
        return secs * 1000;
      }
      return 0;
    }
    const parts = trimmed.split(':');
    if (parts.length === 3) {
      const h = parseInt(parts[0]);
      const m = parseInt(parts[1]);
      const s = parseInt(parts[2]);
      if (!isNaN(h) && !isNaN(m) && !isNaN(s)) {
        return (h * 3600 + m * 60 + s) * 1000;
      }
    } else if (parts.length === 2) {
      const m = parseInt(parts[0]);
      const s = parseInt(parts[1]);
      if (!isNaN(m) && !isNaN(s)) {
        return (m * 60 + s) * 1000;
      }
    }
    return 0;
  }
}
