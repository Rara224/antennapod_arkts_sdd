import { TranscriptEntry } from '../models/TranscriptEntry';

export class TranscriptParser {
  /**
   * Parse WebVTT subtitle content into transcript entries.
   * Format:
   *   WEBVTT
   *
   *   00:00:01.000 --> 00:00:04.000
   *   Hello, welcome to the podcast.
   *
   *   NOTE this is a comment
   *
   *   00:00:04.500 --> 00:00:08.200
   *   <v Speaker Name>Today we discuss...
   */
  static parseVTT(content: string): TranscriptEntry[] {
    const entries: TranscriptEntry[] = [];
    const lines = content.split('\n');
    let i = 0;

    // Skip WEBVTT header
    while (i < lines.length) {
      const line = lines[i].trim();
      if (line.startsWith('WEBVTT')) {
        i++;
        break;
      }
      i++;
    }

    while (i < lines.length) {
      const line = lines[i].trim();

      // Skip empty lines, comments (NOTE), and cue identifiers (numeric lines)
      if (line.length === 0 || line.startsWith('NOTE')) {
        i++;
        // Skip comment body
        if (line.startsWith('NOTE')) {
          while (i < lines.length && lines[i].trim().length > 0) {
            i++;
          }
        }
        continue;
      }

      // Check for timestamp line: HH:MM:SS.mmm --> HH:MM:SS.mmm
      const arrowIndex = line.indexOf('-->');
      if (arrowIndex < 0) {
        // Could be a cue identifier, skip it
        i++;
        continue;
      }

      const startStr = line.substring(0, arrowIndex).trim();
      // End time may have position settings after it, take only the time part
      let endPart = line.substring(arrowIndex + 3).trim();
      const spaceIdx = endPart.indexOf(' ');
      if (spaceIdx > 0) {
        endPart = endPart.substring(0, spaceIdx);
      }

      const startMs = TranscriptParser.parseTimestamp(startStr);
      const endMs = TranscriptParser.parseTimestamp(endPart);

      i++;

      // Collect text lines until empty line
      let text = '';
      let speaker = '';
      while (i < lines.length && lines[i].trim().length > 0) {
        let textLine = lines[i].trim();

        // Extract VTT voice tag: <v Speaker Name>text
        if (textLine.startsWith('<v ')) {
          const closeAngle = textLine.indexOf('>');
          if (closeAngle > 3) {
            speaker = textLine.substring(3, closeAngle);
            textLine = textLine.substring(closeAngle + 1);
          }
        }

        // Strip other VTT tags like <b>, <i>, <u>, </v>, etc.
        textLine = TranscriptParser.stripTags(textLine);

        if (text.length > 0) {
          text += ' ';
        }
        text += textLine;
        i++;
      }

      if (text.length > 0) {
        entries.push(new TranscriptEntry(startMs, endMs, text, speaker));
      }
    }

    return entries;
  }

  /**
   * Parse SRT subtitle content into transcript entries.
   * Format:
   *   1
   *   00:00:01,000 --> 00:00:04,000
   *   Hello, welcome to the podcast.
   *
   *   2
   *   00:00:04,500 --> 00:00:08,200
   *   Today we discuss...
   */
  static parseSRT(content: string): TranscriptEntry[] {
    const entries: TranscriptEntry[] = [];
    const lines = content.split('\n');
    let i = 0;

    while (i < lines.length) {
      const line = lines[i].trim();

      // Skip empty lines
      if (line.length === 0) {
        i++;
        continue;
      }

      // Skip cue number (numeric-only line)
      if (TranscriptParser.isNumeric(line)) {
        i++;
        continue;
      }

      // Check for timestamp line: HH:MM:SS,mmm --> HH:MM:SS,mmm
      const arrowIndex = line.indexOf('-->');
      if (arrowIndex < 0) {
        i++;
        continue;
      }

      // SRT uses comma for milliseconds, normalize to dot
      const startStr = line.substring(0, arrowIndex).trim().replace(',', '.');
      const endStr = line.substring(arrowIndex + 3).trim().replace(',', '.');

      const startMs = TranscriptParser.parseTimestamp(startStr);
      const endMs = TranscriptParser.parseTimestamp(endStr);

      i++;

      // Collect text lines until empty line or next number
      let text = '';
      while (i < lines.length && lines[i].trim().length > 0) {
        let textLine = lines[i].trim();
        // Strip basic HTML tags that may appear in SRT
        textLine = TranscriptParser.stripTags(textLine);
        if (text.length > 0) {
          text += ' ';
        }
        text += textLine;
        i++;
      }

      if (text.length > 0) {
        entries.push(new TranscriptEntry(startMs, endMs, text, ''));
      }
    }

    return entries;
  }

  /**
   * Parse a timestamp string like "HH:MM:SS.mmm" or "MM:SS.mmm" into milliseconds.
   */
  private static parseTimestamp(ts: string): number {
    const trimmed = ts.trim();
    if (trimmed.length === 0) {
      return 0;
    }

    // Split by : to get parts
    const colonParts = trimmed.split(':');
    let hours = 0;
    let minutes = 0;
    let secondsWithMs = '';

    if (colonParts.length === 3) {
      hours = parseInt(colonParts[0]);
      minutes = parseInt(colonParts[1]);
      secondsWithMs = colonParts[2];
    } else if (colonParts.length === 2) {
      minutes = parseInt(colonParts[0]);
      secondsWithMs = colonParts[1];
    } else {
      return 0;
    }

    // Split seconds and milliseconds by . or ,
    let seconds = 0;
    let ms = 0;
    const dotIdx = secondsWithMs.indexOf('.');
    const commaIdx = secondsWithMs.indexOf(',');
    const sepIdx = dotIdx >= 0 ? dotIdx : commaIdx;

    if (sepIdx >= 0) {
      seconds = parseInt(secondsWithMs.substring(0, sepIdx));
      let msStr = secondsWithMs.substring(sepIdx + 1);
      // Pad or truncate to 3 digits
      while (msStr.length < 3) {
        msStr += '0';
      }
      if (msStr.length > 3) {
        msStr = msStr.substring(0, 3);
      }
      ms = parseInt(msStr);
    } else {
      seconds = parseInt(secondsWithMs);
    }

    if (isNaN(hours)) {
      hours = 0;
    }
    if (isNaN(minutes)) {
      minutes = 0;
    }
    if (isNaN(seconds)) {
      seconds = 0;
    }
    if (isNaN(ms)) {
      ms = 0;
    }

    return hours * 3600000 + minutes * 60000 + seconds * 1000 + ms;
  }

  /**
   * Strip HTML/VTT tags from a string.
   */
  private static stripTags(input: string): string {
    let result = '';
    let inTag = false;
    for (let i = 0; i < input.length; i++) {
      const ch = input.charAt(i);
      if (ch === '<') {
        inTag = true;
      } else if (ch === '>') {
        inTag = false;
      } else if (!inTag) {
        result += ch;
      }
    }
    return result;
  }

  /**
   * Check if a string is purely numeric.
   */
  private static isNumeric(str: string): boolean {
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i);
      if (code < 48 || code > 57) {
        return false;
      }
    }
    return str.length > 0;
  }
}
