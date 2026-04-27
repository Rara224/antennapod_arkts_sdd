export class RichTextSegment {
  text: string = '';
  href: string = '';
}

export class StringUtils {
  static isEmpty(s: string | undefined): boolean {
    return s === undefined || s.length === 0;
  }

  static isNotEmpty(s: string | undefined): boolean {
    return !StringUtils.isEmpty(s);
  }

  static isBlank(s: string | undefined): boolean {
    return s === undefined || s.trim().length === 0;
  }

  static isNotBlank(s: string | undefined): boolean {
    return !StringUtils.isBlank(s);
  }

  static trimToEmpty(s: string | undefined): string {
    if (s === undefined) {
      return '';
    }
    return s.trim();
  }

  static join(items: string[], separator: string): string {
    return items.join(separator);
  }

  static containsIgnoreCase(str: string, search: string): boolean {
    return str.toLowerCase().includes(search.toLowerCase());
  }

  static toLong(s: string, defaultValue: number): number {
    const parsed = parseInt(s);
    if (isNaN(parsed)) {
      return defaultValue;
    }
    return parsed;
  }

  /**
   * Parse HTML into an array of text segments (plain text + clickable links).
   * Converts block-level tags to newlines, strips all tags except <a>,
   * decodes entities, then splits on <a href="...">...</a>.
   */
  static parseHtmlToSegments(html: string): RichTextSegment[] {
    if (html.length === 0) {
      return [];
    }
    let text = html;

    // Block-level breaks
    text = text.replace(/<br\s*\/?>/gi, '\n');
    text = text.replace(/<\/p>/gi, '\n\n');
    text = text.replace(/<\/div>/gi, '\n');
    text = text.replace(/<\/h[1-6]>/gi, '\n\n');
    text = text.replace(/<\/li>/gi, '\n');
    text = text.replace(/<li[^>]*>/gi, '\n\u2022 ');
    text = text.replace(/<\/tr>/gi, '\n');

    // Remove all tags EXCEPT <a ...> and </a>
    text = text.replace(/<(?!\/?a[\s>])[^>]+>/g, '');

    // Decode HTML entities
    text = text.replace(/&amp;/g, '&');
    text = text.replace(/&lt;/g, '<');
    text = text.replace(/&gt;/g, '>');
    text = text.replace(/&quot;/g, '"');
    text = text.replace(/&#39;/g, "'");
    text = text.replace(/&apos;/g, "'");
    text = text.replace(/&nbsp;/g, ' ');
    text = text.replace(/&#(\d+);/g, (_match: string, code: string): string => {
      const num = parseInt(code);
      if (!isNaN(num) && num > 0 && num < 65536) {
        return String.fromCharCode(num);
      }
      return '';
    });

    text = text.replace(/\\n/g, '\n');
    text = text.replace(/[ \t]+/g, ' ');
    text = text.replace(/\n /g, '\n');
    text = text.replace(/ \n/g, '\n');
    text = text.replace(/\n{3,}/g, '\n\n');
    text = text.trim();

    // Split into segments by <a href="...">...</a>
    const segments: RichTextSegment[] = [];
    let pos = 0;

    while (pos < text.length) {
      const aStart = text.indexOf('<a ', pos);
      const aStart2 = text.indexOf('<a>', pos);
      let actualStart = -1;
      if (aStart >= 0 && aStart2 >= 0) {
        actualStart = Math.min(aStart, aStart2);
      } else if (aStart >= 0) {
        actualStart = aStart;
      } else {
        actualStart = aStart2;
      }

      if (actualStart < 0) {
        const remaining = text.substring(pos);
        if (remaining.length > 0) {
          const seg = new RichTextSegment();
          seg.text = remaining;
          segments.push(seg);
        }
        break;
      }

      // Plain text before the link
      if (actualStart > pos) {
        const beforeText = text.substring(pos, actualStart);
        if (beforeText.length > 0) {
          const seg = new RichTextSegment();
          seg.text = beforeText;
          segments.push(seg);
        }
      }

      // Find end of opening <a> tag
      const tagEnd = text.indexOf('>', actualStart);
      if (tagEnd < 0) {
        const remaining = text.substring(actualStart);
        const seg = new RichTextSegment();
        seg.text = remaining;
        segments.push(seg);
        break;
      }

      // Extract href
      const tagContent = text.substring(actualStart, tagEnd + 1);
      let href = '';
      const hrefIdx = tagContent.indexOf('href=');
      if (hrefIdx >= 0) {
        const afterHref = tagContent.substring(hrefIdx + 5);
        let quote = afterHref.charAt(0);
        if (quote === '"' || quote === "'") {
          const endQuote = afterHref.indexOf(quote, 1);
          if (endQuote > 0) {
            href = afterHref.substring(1, endQuote);
          }
        }
      }

      // Find </a>
      const closeTag = text.indexOf('</a>', tagEnd);
      if (closeTag < 0) {
        const linkText = text.substring(tagEnd + 1);
        const seg = new RichTextSegment();
        seg.text = linkText;
        seg.href = href;
        segments.push(seg);
        break;
      }

      const linkText = text.substring(tagEnd + 1, closeTag);
      if (linkText.length > 0) {
        const seg = new RichTextSegment();
        seg.text = linkText;
        seg.href = href;
        segments.push(seg);
      }

      pos = closeTag + 4;
    }

    return segments;
  }

  /**
   * Convert HTML to plain text:
   * - <br>, </p>, </div>, </li> → newline
   * - <li> → newline + "• "
   * - Strip all other tags
   * - Decode common HTML entities
   * - Collapse multiple blank lines
   */
  static htmlToPlainText(html: string): string {
    if (html.length === 0) {
      return '';
    }
    let text = html;

    // Block-level breaks BEFORE stripping tags
    text = text.replace(/<br\s*\/?>/gi, '\n');
    text = text.replace(/<\/p>/gi, '\n\n');
    text = text.replace(/<\/div>/gi, '\n');
    text = text.replace(/<\/h[1-6]>/gi, '\n\n');
    text = text.replace(/<\/li>/gi, '\n');
    text = text.replace(/<li[^>]*>/gi, '\n\u2022 ');
    text = text.replace(/<\/tr>/gi, '\n');

    // Strip remaining tags
    text = text.replace(/<[^>]+>/g, '');

    // Decode HTML entities
    text = text.replace(/&amp;/g, '&');
    text = text.replace(/&lt;/g, '<');
    text = text.replace(/&gt;/g, '>');
    text = text.replace(/&quot;/g, '"');
    text = text.replace(/&#39;/g, "'");
    text = text.replace(/&apos;/g, "'");
    text = text.replace(/&nbsp;/g, ' ');
    // Numeric entities &#NNN;
    text = text.replace(/&#(\d+);/g, (_match: string, code: string): string => {
      const num = parseInt(code);
      if (!isNaN(num) && num > 0 && num < 65536) {
        return String.fromCharCode(num);
      }
      return '';
    });

    // Convert literal \n (backslash + n) to real newlines
    text = text.replace(/\\n/g, '\n');

    // Collapse whitespace: multiple spaces → single, multiple blank lines → double newline
    text = text.replace(/[ \t]+/g, ' ');
    text = text.replace(/\n /g, '\n');
    text = text.replace(/ \n/g, '\n');
    text = text.replace(/\n{3,}/g, '\n\n');

    return text.trim();
  }
}
