import xml from '@ohos.xml';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Feed } from '../models/Feed';
import { FeedItem } from '../models/FeedItem';
import { FeedMedia } from '../models/FeedMedia';
import { Chapter } from '../models/Chapter';
import { FeedFunding } from '../models/FeedFunding';
import { FEED_TYPE_RSS, FEED_TYPE_ATOM, PLAY_STATE_NEW } from '../common/Constants';
import { DateParser } from './DateParser';
import {
  handleStartTag as itunesStart,
  handleEndTag as itunesEnd
} from './namespace/ItunesNamespace';
import {
  handleStartTag as mediaStart,
  handleEndTag as mediaEnd
} from './namespace/MediaNamespace';
import { handleEndTag as dcEnd } from './namespace/DublinCoreNamespace';
import { handleEndTag as contentEnd } from './namespace/ContentNamespace';
import { handleStartTag as podcastIndexStart } from './namespace/PodcastIndexNamespace';

const DOMAIN: number = 0x0000;
const TAG: string = 'FeedParser';

const ITUNES_URI: string = 'http://www.itunes.com/dtds/podcast-1.0.dtd';
const MEDIA_URI: string = 'http://search.yahoo.com/mrss/';
const DC_URI: string = 'http://purl.org/dc/elements/1.1/';
const CONTENT_URI: string = 'http://purl.org/rss/1.0/modules/content/';
const PODCAST_INDEX_URI: string = 'https://podcastindex.org/namespace/1.0';
const ATOM_URI: string = 'http://www.w3.org/2005/Atom';
const SIMPLE_CHAPTERS_URI: string = 'http://podlove.org/simple-chapters';

export class FeedParser {
  parse(xmlData: string): Feed {
    const feed = new Feed();
    let currentItem: FeedItem | undefined = undefined;
    let currentText: string = '';
    let insideChannel: boolean = false;
    let insideItem: boolean = false;
    let insideImage: boolean = false;
    let insideAuthor: boolean = false;
    let feedType: string = '';
    let currentStartAttrs: Map<string, string> = new Map();
    // 属性通过 attributeValueCallbackFunction 收集，在 START_TAG 之前触发
    let pendingAttrs: Map<string, string> = new Map();

    const arrayBuffer = FeedParser.toArrayBuffer(xmlData);
    const parser = new xml.XmlPullParser(arrayBuffer, 'utf-8');

    parser.parse({
      supportDoctype: true,
      ignoreNameSpace: false,
      attributeValueCallbackFunction: (attrName: string, attrValue: string): boolean => {
        pendingAttrs.set(attrName, attrValue);
        return true;
      },
      tokenValueCallbackFunction: (eventType: xml.EventType, value: xml.ParseInfo): boolean => {
        const name = value.getName();
        const prefix = value.getPrefix();
        const ns = value.getNamespace();
        const isNamespaced = prefix.length > 0;

        if (eventType === xml.EventType.START_TAG) {
          currentText = '';

          // 使用 attributeValueCallbackFunction 收集到的属性
          const attrs = pendingAttrs;
          pendingAttrs = new Map();
          currentStartAttrs = attrs;

          // Detect feed type from root element
          if (name === 'rss' && feedType === '') {
            feedType = 'rss';
            feed.type = FEED_TYPE_RSS;
            return true;
          }
          if (name === 'feed' && feedType === '') {
            feedType = 'atom';
            feed.type = FEED_TYPE_ATOM;
            insideChannel = true;
            return true;
          }

          // Namespace dispatch
          if (isNamespaced) {
            if (prefix === 'itunes' || ns === ITUNES_URI) {
              itunesStart(name, attrs, feed, currentItem, insideItem);
            } else if (prefix === 'media' || ns === MEDIA_URI) {
              mediaStart(name, attrs, feed, currentItem, insideItem);
            } else if (prefix === 'podcast' || ns === PODCAST_INDEX_URI) {
              podcastIndexStart(name, attrs, feed, currentItem, insideItem);
            } else if (prefix === 'psc' || ns === SIMPLE_CHAPTERS_URI) {
              if (name === 'chapter' && insideItem && currentItem !== undefined) {
                const startStr = attrs.get('start');
                const titleStr = attrs.get('title');
                const href = attrs.get('href');
                const image = attrs.get('image');
                const startMs = startStr !== undefined ? DateParser.parseDuration(startStr) : 0;
                const chapter = new Chapter(
                  startMs,
                  titleStr !== undefined ? titleStr : '',
                  href !== undefined ? href : '',
                  image !== undefined ? image : ''
                );
                currentItem.chapters.push(chapter);
                currentItem.hasChapters = true;
              }
            }
            return true;
          }

          // Core tag handling
          if (name === 'channel') {
            insideChannel = true;
          } else if (name === 'item' || (name === 'entry' && feedType === 'atom')) {
            insideItem = true;
            currentItem = new FeedItem();
            currentItem.state = PLAY_STATE_NEW;
          } else if (name === 'image') {
            if (insideChannel && !insideItem) {
              insideImage = true;
            }
            // Item-level <image href="..."> (non-namespaced)
            if (insideItem && currentItem !== undefined) {
              const href = attrs.get('href');
              if (href !== undefined && href.length > 0 && currentItem.imageUrl.length === 0) {
                currentItem.imageUrl = href;
              }
            }
          } else if (name === 'author' && feedType === 'atom') {
            insideAuthor = true;
          } else if (name === 'enclosure' && insideItem && currentItem !== undefined) {
            const media = new FeedMedia();
            const url = attrs.get('url');
            if (url !== undefined) {
              media.downloadUrl = url;
            }
            const type = attrs.get('type');
            if (type !== undefined) {
              media.mimeType = type;
            }
            const length = attrs.get('length');
            if (length !== undefined) {
              const size = parseInt(length);
              if (!isNaN(size)) {
                media.size = size;
              }
            }
            currentItem.media = media;
          } else if (name === 'link' && feedType === 'atom') {
            const rel = attrs.get('rel');
            const href = attrs.get('href');
            const type = attrs.get('type');
            const length = attrs.get('length');

            if (rel === 'enclosure' && insideItem && currentItem !== undefined && href !== undefined) {
              if (currentItem.media === null) {
                const media = new FeedMedia();
                media.downloadUrl = href;
                if (type !== undefined) {
                  media.mimeType = type;
                }
                if (length !== undefined) {
                  const size = parseInt(length);
                  if (!isNaN(size)) {
                    media.size = size;
                  }
                }
                currentItem.media = media;
              }
            } else if (href !== undefined && (rel === 'alternate' || rel === undefined)) {
              if (insideItem && currentItem !== undefined) {
                currentItem.link = href;
              } else if (!insideItem) {
                feed.link = href;
              }
            }
          }
          return true;

        } else if (eventType === xml.EventType.TEXT || eventType === xml.EventType.CDSECT) {
          currentText += value.getText();
          return true;

        } else if (eventType === xml.EventType.END_TAG) {
          const text = currentText.trim();

          // Namespace dispatch
          if (isNamespaced) {
            if (prefix === 'itunes' || ns === ITUNES_URI) {
              itunesEnd(name, text, feed, currentItem, insideItem);
            } else if (prefix === 'media' || ns === MEDIA_URI) {
              mediaEnd(name, text, feed, currentItem, insideItem);
            } else if (prefix === 'dc' || ns === DC_URI) {
              dcEnd(name, text, feed, currentItem, insideItem);
            } else if (prefix === 'content' || ns === CONTENT_URI) {
              contentEnd(name, text, currentItem, insideItem);
            } else if (prefix === 'podcast' || ns === PODCAST_INDEX_URI) {
              // podcast:funding has url attr + text content
              if (name === 'funding' && !insideItem) {
                const url = currentStartAttrs.get('url');
                if (url !== undefined && url.length > 0) {
                  const funding = new FeedFunding(url, text);
                  feed.fundingList.push(funding);
                }
              }
            }
            currentText = '';
            return true;
          }

          // Core end tags
          if (name === 'channel') {
            insideChannel = false;
          } else if (name === 'item' || (name === 'entry' && feedType === 'atom')) {
            if (currentItem !== undefined) {
              feed.items.push(currentItem);
            }
            insideItem = false;
            currentItem = undefined;
          } else if (name === 'image' && insideImage) {
            insideImage = false;
          } else if (name === 'author' && insideAuthor && feedType === 'atom') {
            insideAuthor = false;
          } else if (name === 'title') {
            if (insideItem && currentItem !== undefined) {
              currentItem.title = text;
            } else if (insideChannel) {
              feed.feedTitle = text;
            }
          } else if (name === 'link' && feedType !== 'atom') {
            // RSS link (text content, not Atom attribute)
            if (insideItem && currentItem !== undefined) {
              currentItem.link = text;
            } else if (insideChannel && !insideImage) {
              feed.link = text;
            }
          } else if (name === 'description') {
            if (insideItem && currentItem !== undefined) {
              if (currentItem.description.length === 0) {
                currentItem.description = text;
              }
            } else if (insideChannel) {
              if (feed.description.length === 0) {
                feed.description = text;
              }
            }
          } else if (name === 'summary' && feedType === 'atom') {
            if (insideItem && currentItem !== undefined) {
              if (currentItem.description.length === 0) {
                currentItem.description = text;
              }
            }
          } else if (name === 'content' && feedType === 'atom') {
            // Atom <content> overrides <summary>
            if (insideItem && currentItem !== undefined) {
              currentItem.description = text;
            }
          } else if (name === 'pubDate') {
            if (insideItem && currentItem !== undefined) {
              currentItem.pubDate = DateParser.parseDate(text);
            }
          } else if (name === 'published' || name === 'updated') {
            if (insideItem && currentItem !== undefined) {
              if (name === 'published' || currentItem.pubDate === 0) {
                currentItem.pubDate = DateParser.parseDate(text);
              }
            }
          } else if (name === 'guid' || name === 'id') {
            if (insideItem && currentItem !== undefined) {
              currentItem.itemIdentifier = text;
            }
          } else if (name === 'language') {
            if (insideChannel && !insideItem) {
              feed.language = text;
            }
          } else if (name === 'url' && insideImage && !insideItem) {
            feed.imageUrl = text;
          } else if (name === 'author' && feedType !== 'atom') {
            if (!insideItem && insideChannel) {
              feed.author = text;
            }
          } else if (name === 'name' && insideAuthor && feedType === 'atom') {
            if (!insideItem) {
              feed.author = text;
            }
          }
          currentText = '';
          return true;
        }
        return true;
      }
    });

    // 后处理：attributeValueCallbackFunction 不可靠，用字符串扫描补全
    FeedParser.fillMissingEnclosures(xmlData, feed);
    FeedParser.fillMissingItemImages(xmlData, feed);

    return feed;
  }

  /**
   * 补全 <enclosure> 的 url/type/length 属性。
   * attributeValueCallbackFunction 不可靠，此方法从原始 XML 提取。
   */
  private static fillMissingEnclosures(xmlData: string, feed: Feed): void {
    let needsFill = false;
    for (let i = 0; i < feed.items.length; i++) {
      const item = feed.items[i];
      if (item.media === null || item.media.downloadUrl.length === 0) {
        needsFill = true;
        break;
      }
    }
    if (!needsFill) {
      return;
    }

    // 收集每个 <item> 内的 <enclosure> 属性
    let itemIdx = 0;
    let pos = 0;
    let insideItem = false;
    const len = xmlData.length;

    while (pos < len && itemIdx < feed.items.length) {
      const ltIdx = xmlData.indexOf('<', pos);
      if (ltIdx < 0) {
        break;
      }

      // <item> or <item ...>
      if (!insideItem && ltIdx + 5 < len) {
        const c1 = xmlData.charAt(ltIdx + 1);
        const c2 = xmlData.charAt(ltIdx + 2);
        const c3 = xmlData.charAt(ltIdx + 3);
        const c4 = xmlData.charAt(ltIdx + 4);
        const c5 = xmlData.charAt(ltIdx + 5);
        if (c1 === 'i' && c2 === 't' && c3 === 'e' && c4 === 'm' &&
            (c5 === '>' || c5 === ' ' || c5 === '\n' || c5 === '\r')) {
          insideItem = true;
          pos = ltIdx + 5;
          continue;
        }
      }

      // </item>
      if (insideItem && ltIdx + 6 < len &&
          xmlData.charAt(ltIdx + 1) === '/' &&
          xmlData.charAt(ltIdx + 2) === 'i' && xmlData.charAt(ltIdx + 3) === 't' &&
          xmlData.charAt(ltIdx + 4) === 'e' && xmlData.charAt(ltIdx + 5) === 'm') {
        insideItem = false;
        itemIdx++;
        pos = ltIdx + 7;
        continue;
      }

      // <enclosure ...> inside item
      if (insideItem && ltIdx + 10 < len) {
        const slice9 = xmlData.substring(ltIdx + 1, ltIdx + 10);
        if (slice9 === 'enclosure') {
          const gtIdx = xmlData.indexOf('>', ltIdx);
          if (gtIdx > ltIdx && gtIdx - ltIdx < 500) {
            const tag = xmlData.substring(ltIdx, gtIdx + 1);
            const item = feed.items[itemIdx];
            const url = FeedParser.extractAttr(tag, 'url');
            if (url.length > 0 && (item.media === null || item.media.downloadUrl.length === 0)) {
              if (item.media === null) {
                const m = new FeedMedia();
                m.downloadUrl = url;
                m.mimeType = FeedParser.extractAttr(tag, 'type');
                const lengthStr = FeedParser.extractAttr(tag, 'length');
                if (lengthStr.length > 0) {
                  const size = parseInt(lengthStr);
                  if (!isNaN(size)) {
                    m.size = size;
                  }
                }
                item.media = m;
              } else {
                item.media.downloadUrl = url;
                const type = FeedParser.extractAttr(tag, 'type');
                if (type.length > 0 && item.media.mimeType.length === 0) {
                  item.media.mimeType = type;
                }
              }
            }
            pos = gtIdx + 1;
            continue;
          }
        }
      }

      pos = ltIdx + 1;
    }
  }

  /**
   * 单次扫描原始 XML，提取 item 级 itunes:image href，
   * 补全 XmlPullParser attributeValueCallbackFunction 未能捕获的图片。
   */
  private static fillMissingItemImages(xmlData: string, feed: Feed): void {
    // 快速检查：如果所有 item 都已有图则跳过
    let needsFill = false;
    for (let i = 0; i < feed.items.length; i++) {
      if (feed.items[i].imageUrl.length === 0) {
        needsFill = true;
        break;
      }
    }
    if (!needsFill) {
      return;
    }

    // 单次扫描：收集每个 <item> 内的第一个 itunes:image href
    const imageUrls: string[] = [];
    let insideItem = false;
    let foundImageForCurrentItem = false;
    let pos = 0;
    const len = xmlData.length;

    while (pos < len) {
      const ltIdx = xmlData.indexOf('<', pos);
      if (ltIdx < 0) {
        break;
      }

      // 检查是否是 <item 或 <item>
      if (!insideItem && ltIdx + 5 < len &&
          xmlData.charAt(ltIdx + 1) === 'i' && xmlData.charAt(ltIdx + 2) === 't' &&
          xmlData.charAt(ltIdx + 3) === 'e' && xmlData.charAt(ltIdx + 4) === 'm') {
        const afterTag = xmlData.charAt(ltIdx + 5);
        if (afterTag === '>' || afterTag === ' ' || afterTag === '\n' || afterTag === '\r') {
          insideItem = true;
          foundImageForCurrentItem = false;
          pos = ltIdx + 5;
          continue;
        }
      }

      // 检查 </item>
      if (insideItem && ltIdx + 6 < len &&
          xmlData.charAt(ltIdx + 1) === '/' &&
          xmlData.charAt(ltIdx + 2) === 'i' && xmlData.charAt(ltIdx + 3) === 't' &&
          xmlData.charAt(ltIdx + 4) === 'e' && xmlData.charAt(ltIdx + 5) === 'm') {
        if (!foundImageForCurrentItem) {
          imageUrls.push('');
        }
        insideItem = false;
        pos = ltIdx + 7;
        continue;
      }

      // 在 <item> 内查找 itunes:image
      if (insideItem && !foundImageForCurrentItem) {
        const gtIdx = xmlData.indexOf('>', ltIdx);
        if (gtIdx < 0) {
          break;
        }
        // 检查是否包含 itunes:image
        const tagLen = gtIdx - ltIdx;
        if (tagLen < 200) {
          // 短标签，快速检查
          const tagSlice = xmlData.substring(ltIdx, gtIdx + 1);
          if (tagSlice.indexOf('itunes:image') >= 0) {
            const href = FeedParser.extractAttr(tagSlice, 'href');
            if (href.length > 0) {
              imageUrls.push(href);
              foundImageForCurrentItem = true;
            }
          }
        }
        pos = gtIdx + 1;
        continue;
      }

      pos = ltIdx + 1;
    }

    // 对齐赋值
    const count = imageUrls.length < feed.items.length ? imageUrls.length : feed.items.length;
    for (let i = 0; i < count; i++) {
      if (feed.items[i].imageUrl.length === 0 && imageUrls[i].length > 0) {
        feed.items[i].imageUrl = imageUrls[i];
      }
    }
  }

  private static extractAttr(tag: string, attrName: string): string {
    const key = attrName + '=';
    const idx = tag.indexOf(key);
    if (idx < 0) {
      return '';
    }
    const q = tag.charAt(idx + key.length);
    if (q !== '"' && q !== "'") {
      return '';
    }
    const start = idx + key.length + 1;
    const end = tag.indexOf(q, start);
    if (end <= start) {
      return '';
    }
    return tag.substring(start, end);
  }

  private static toArrayBuffer(str: string): ArrayBuffer {
    const encoder = new util.TextEncoder();
    const uint8 = encoder.encodeInto(str);
    const ab = new ArrayBuffer(uint8.length);
    const view = new Uint8Array(ab);
    for (let i = 0; i < uint8.length; i++) {
      view[i] = uint8[i];
    }
    return ab;
  }
}
