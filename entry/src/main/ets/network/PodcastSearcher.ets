import { hilog } from '@kit.PerformanceAnalysisKit';
import { HttpClient } from './HttpClient';
import { PodcastSearchResult } from '../models/PodcastSearchResult';

const DOMAIN: number = 0x0000;
const TAG: string = 'PodcastSearcher';

export class PodcastSearcher {
  private static readonly ITUNES_SEARCH_URL: string = 'https://itunes.apple.com/search';

  /**
   * Fetch top podcasts from Apple iTunes RSS feed.
   * Parses the response directly (single API call) and stores iTunes collection ID
   * as feedUrl with "itunes:" prefix for later resolution.
   */
  static async getTopPodcasts(countryCode: string, limit: number): Promise<PodcastSearchResult[]> {
    const url = 'https://itunes.apple.com/' + countryCode +
      '/rss/toppodcasts/limit=' + limit.toString() + '/json';

    hilog.info(DOMAIN, TAG, 'Fetching top podcasts: %{public}s', url);

    const response = await HttpClient.get(url, new Map(), undefined);
    if (response.responseCode !== 200) {
      throw new Error('Failed to fetch top podcasts: HTTP ' + response.responseCode.toString());
    }

    return PodcastSearcher.parseTopPodcastsResponse(response.body);
  }

  /**
   * Resolve an iTunes collection ID to a real RSS feed URL via lookup API.
   */
  static async resolveItunesFeedUrl(itunesId: string): Promise<string> {
    const url = 'https://itunes.apple.com/lookup?id=' + itunesId + '&entity=podcast';
    hilog.info(DOMAIN, TAG, 'Looking up feedUrl for iTunes ID: %{public}s', itunesId);

    const response = await HttpClient.get(url, new Map(), undefined);
    if (response.responseCode !== 200) {
      throw new Error('Lookup failed: HTTP ' + response.responseCode.toString());
    }

    const feedUrl = PodcastSearcher.extractJsonString(response.body, 'feedUrl');
    if (feedUrl.length === 0) {
      throw new Error('No feedUrl found for iTunes ID: ' + itunesId);
    }
    return feedUrl;
  }

  /**
   * Parse the iTunes top podcasts RSS JSON response directly.
   * Extracts name, artist, artwork URL, and iTunes collection ID from each entry.
   */
  private static parseTopPodcastsResponse(json: string): PodcastSearchResult[] {
    const results: PodcastSearchResult[] = [];

    // Find "entry":[ array
    const arrMarker = '"entry":[';
    const arrStart = json.indexOf(arrMarker);
    if (arrStart < 0) {
      return results;
    }
    let pos = arrStart + arrMarker.length;

    while (pos < json.length) {
      // Skip to next object
      while (pos < json.length) {
        const ch = json.charAt(pos);
        if (ch === '{') {
          break;
        }
        if (ch === ']') {
          return results;
        }
        pos++;
      }
      if (pos >= json.length) {
        break;
      }

      // Find matching closing brace (depth tracking)
      let depth = 0;
      let objEnd = pos;
      for (let i = pos; i < json.length; i++) {
        const ch = json.charAt(i);
        if (ch === '{') {
          depth++;
        } else if (ch === '}') {
          depth--;
          if (depth === 0) {
            objEnd = i;
            break;
          }
        } else if (ch === '"') {
          i++;
          while (i < json.length && json.charAt(i) !== '"') {
            if (json.charAt(i) === '\\') {
              i++;
            }
            i++;
          }
        }
      }

      const objStr = json.substring(pos, objEnd + 1);
      pos = objEnd + 1;

      // Extract im:name -> {"label":"..."}
      const name = PodcastSearcher.extractNestedLabel(objStr, '"im:name"');
      // Extract im:artist -> {"label":"..."}
      const artist = PodcastSearcher.extractNestedLabel(objStr, '"im:artist"');
      // Extract im:id from id.attributes
      const itunesId = PodcastSearcher.extractJsonString(objStr, 'im:id');
      // Extract largest image (170x170)
      const artworkUrl = PodcastSearcher.extractLargestImage(objStr);

      if (itunesId.length > 0 && name.length > 0) {
        // Store iTunes ID with prefix for later resolution
        results.push(new PodcastSearchResult(
          name,
          artist,
          'itunes:' + itunesId,
          artworkUrl,
          ''
        ));
      }
    }

    hilog.info(DOMAIN, TAG, 'Parsed %{public}d top podcasts from RSS', results.length);
    return results;
  }

  /**
   * Extract "label" value from a nested object like "im:name":{"label":"The Daily"}
   */
  private static extractNestedLabel(json: string, key: string): string {
    const keyIdx = json.indexOf(key);
    if (keyIdx < 0) {
      return '';
    }
    // Find {"label":" after the key
    const labelMarker = '"label":"';
    const labelIdx = json.indexOf(labelMarker, keyIdx);
    if (labelIdx < 0 || labelIdx > keyIdx + key.length + 20) {
      return '';
    }
    const start = labelIdx + labelMarker.length;
    let end = start;
    while (end < json.length && json.charAt(end) !== '"') {
      if (json.charAt(end) === '\\') {
        end++;
      }
      end++;
    }
    return json.substring(start, end);
  }

  /**
   * Extract the largest image URL (170x170) from im:image array.
   */
  private static extractLargestImage(json: string): string {
    // Look for the 170x170 image which is the last/largest in the array
    const marker170 = '"height":"170"';
    const idx170 = json.indexOf(marker170);
    if (idx170 < 0) {
      // Fallback: look for any height
      const markerAny = '"height":"60"';
      const idxAny = json.indexOf(markerAny);
      if (idxAny < 0) {
        return '';
      }
      return PodcastSearcher.extractImageLabelBefore(json, idxAny);
    }
    return PodcastSearcher.extractImageLabelBefore(json, idx170);
  }

  /**
   * Extract the "label" URL before a given position in im:image entry.
   */
  private static extractImageLabelBefore(json: string, beforePos: number): string {
    // Search backwards from beforePos for "label":"
    const labelMarker = '"label":"';
    let searchStart = beforePos - 300;
    if (searchStart < 0) {
      searchStart = 0;
    }
    const segment = json.substring(searchStart, beforePos);
    const lastIdx = segment.lastIndexOf(labelMarker);
    if (lastIdx < 0) {
      return '';
    }
    const start = searchStart + lastIdx + labelMarker.length;
    let end = start;
    while (end < json.length && json.charAt(end) !== '"') {
      if (json.charAt(end) === '\\') {
        end++;
      }
      end++;
    }
    return json.substring(start, end);
  }

  /**
   * Search podcasts via fyyd API (public, no auth needed).
   * Endpoint: https://api.fyyd.de/0.2/search/podcast?title=QUERY&count=25
   */
  static async searchFyyd(query: string): Promise<PodcastSearchResult[]> {
    if (query.trim().length === 0) {
      return [];
    }

    const encodedQuery = encodeURIComponent(query.trim());
    const url = 'https://api.fyyd.de/0.2/search/podcast?title=' + encodedQuery + '&count=25';

    hilog.info(DOMAIN, TAG, 'Searching fyyd: %{public}s', query);

    const response = await HttpClient.get(url, new Map(), undefined);
    if (response.responseCode !== 200) {
      throw new Error('fyyd search failed: HTTP ' + response.responseCode.toString());
    }

    return PodcastSearcher.parseFyydResults(response.body);
  }

  /**
   * Parse fyyd search JSON response.
   * Format: {"status":1,"data":[{"title":"...","author":"...","xmlURL":"...","imgURL":"..."}, ...]}
   */
  private static parseFyydResults(jsonStr: string): PodcastSearchResult[] {
    const results: PodcastSearchResult[] = [];

    const arrMarker = '"data":[';
    const arrStart = jsonStr.indexOf(arrMarker);
    if (arrStart < 0) {
      return results;
    }
    let pos = arrStart + arrMarker.length;

    while (pos < jsonStr.length) {
      while (pos < jsonStr.length) {
        const ch = jsonStr.charAt(pos);
        if (ch === '{') {
          break;
        }
        if (ch === ']') {
          return results;
        }
        pos++;
      }
      if (pos >= jsonStr.length) {
        break;
      }

      let depth = 0;
      let objEnd = pos;
      for (let i = pos; i < jsonStr.length; i++) {
        const ch = jsonStr.charAt(i);
        if (ch === '{') {
          depth++;
        } else if (ch === '}') {
          depth--;
          if (depth === 0) {
            objEnd = i;
            break;
          }
        } else if (ch === '"') {
          i++;
          while (i < jsonStr.length && jsonStr.charAt(i) !== '"') {
            if (jsonStr.charAt(i) === '\\') {
              i++;
            }
            i++;
          }
        }
      }

      const objStr = jsonStr.substring(pos, objEnd + 1);
      pos = objEnd + 1;

      const feedUrl = PodcastSearcher.extractJsonString(objStr, 'xmlURL');
      if (feedUrl.length === 0) {
        continue;
      }

      const title = PodcastSearcher.extractJsonString(objStr, 'title');
      const author = PodcastSearcher.extractJsonString(objStr, 'author');
      const imgUrl = PodcastSearcher.extractJsonString(objStr, 'imgURL');

      results.push(new PodcastSearchResult(title, author, feedUrl, imgUrl, ''));
    }

    return results;
  }

  /**
   * Search podcasts via Podcast Index API.
   * Endpoint: https://api.podcastindex.org/api/1.0/search/byterm?q=QUERY
   * Note: Podcast Index requires API authentication. Falls back to iTunes search.
   */
  static async searchPodcastIndex(query: string): Promise<PodcastSearchResult[]> {
    if (query.trim().length === 0) {
      return [];
    }

    // Podcast Index requires API key/secret authentication.
    // Fall back to iTunes search which provides similar results.
    hilog.info(DOMAIN, TAG, 'Searching Podcast Index (via iTunes fallback): %{public}s', query);
    return PodcastSearcher.search(query);
  }

  static async search(query: string): Promise<PodcastSearchResult[]> {
    if (query.trim().length === 0) {
      return [];
    }

    const encodedQuery = encodeURIComponent(query.trim());
    const url = PodcastSearcher.ITUNES_SEARCH_URL +
      '?term=' + encodedQuery + '&media=podcast&limit=25';

    hilog.info(DOMAIN, TAG, 'Searching: %{public}s', query);

    const response = await HttpClient.get(url, new Map(), undefined);
    if (response.responseCode !== 200) {
      throw new Error('Search failed: HTTP ' + response.responseCode.toString());
    }

    return PodcastSearcher.parseResults(response.body);
  }

  /**
   * Parse iTunes search JSON response using string operations to avoid any/unknown types.
   * Follows the same pattern as HttpClient.extractHeaders.
   */
  private static parseResults(jsonStr: string): PodcastSearchResult[] {
    const results: PodcastSearchResult[] = [];

    // Find "results":[ array start
    const arrMarker = '"results":[';
    const arrStart = jsonStr.indexOf(arrMarker);
    if (arrStart < 0) {
      return results;
    }
    let pos = arrStart + arrMarker.length;

    // Iterate over each {...} object in the array
    while (pos < jsonStr.length) {
      // Skip whitespace and commas
      while (pos < jsonStr.length) {
        const ch = jsonStr.charAt(pos);
        if (ch === '{') {
          break;
        }
        if (ch === ']') {
          return results;
        }
        pos++;
      }
      if (pos >= jsonStr.length) {
        break;
      }

      // Find matching closing brace
      let depth = 0;
      let objEnd = pos;
      for (let i = pos; i < jsonStr.length; i++) {
        const ch = jsonStr.charAt(i);
        if (ch === '{') {
          depth++;
        } else if (ch === '}') {
          depth--;
          if (depth === 0) {
            objEnd = i;
            break;
          }
        } else if (ch === '"') {
          // Skip string content to avoid counting braces inside strings
          i++;
          while (i < jsonStr.length && jsonStr.charAt(i) !== '"') {
            if (jsonStr.charAt(i) === '\\') {
              i++;
            }
            i++;
          }
        }
      }

      const objStr = jsonStr.substring(pos, objEnd + 1);
      pos = objEnd + 1;

      const feedUrl = PodcastSearcher.extractJsonString(objStr, 'feedUrl');
      if (feedUrl.length === 0) {
        continue;
      }

      const trackName = PodcastSearcher.extractJsonString(objStr, 'trackName');
      const artistName = PodcastSearcher.extractJsonString(objStr, 'artistName');
      const artworkUrl = PodcastSearcher.extractJsonString(objStr, 'artworkUrl100');
      const collectionName = PodcastSearcher.extractJsonString(objStr, 'collectionName');

      results.push(new PodcastSearchResult(
        trackName.length > 0 ? trackName : collectionName,
        artistName,
        feedUrl,
        artworkUrl,
        ''
      ));
    }

    return results;
  }

  /**
   * Extract a string value for the given key from a JSON object string.
   * e.g. extractJsonString('{"foo":"bar"}', 'foo') => 'bar'
   */
  private static extractJsonString(json: string, key: string): string {
    const search = '"' + key + '":"';
    const idx = json.indexOf(search);
    if (idx < 0) {
      return '';
    }
    const start = idx + search.length;
    let end = start;
    while (end < json.length && json.charAt(end) !== '"') {
      if (json.charAt(end) === '\\') {
        end++; // skip escaped character
      }
      end++;
    }
    return json.substring(start, end);
  }
}
