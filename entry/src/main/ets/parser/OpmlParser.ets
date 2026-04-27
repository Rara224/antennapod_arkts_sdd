import xml from '@ohos.xml';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'OpmlParser';

export class OpmlFeed {
  title: string = '';
  xmlUrl: string = '';
  htmlUrl: string = '';
}

export class OpmlParser {
  /**
   * Parse OPML XML string and return list of feed URLs with titles.
   */
  parse(xmlData: string): OpmlFeed[] {
    const feeds: OpmlFeed[] = [];
    let pendingAttrs: Map<string, string> = new Map();

    const encoder = new util.TextEncoder();
    const uint8 = encoder.encodeInto(xmlData);
    const ab = new ArrayBuffer(uint8.length);
    const view = new Uint8Array(ab);
    for (let i = 0; i < uint8.length; i++) {
      view[i] = uint8[i];
    }

    const parser = new xml.XmlPullParser(ab, 'utf-8');
    parser.parse({
      supportDoctype: true,
      ignoreNameSpace: true,
      attributeValueCallbackFunction: (attrName: string, attrValue: string): boolean => {
        pendingAttrs.set(attrName.toLowerCase(), attrValue);
        return true;
      },
      tokenValueCallbackFunction: (eventType: xml.EventType, value: xml.ParseInfo): boolean => {
        if (eventType === xml.EventType.START_TAG) {
          const name = value.getName();
          const attrs = pendingAttrs;
          pendingAttrs = new Map();
          if (name === 'outline') {
            const xmlUrl = attrs.get('xmlurl');
            if (xmlUrl !== undefined && xmlUrl.length > 0) {
              const feed = new OpmlFeed();
              feed.xmlUrl = xmlUrl;
              const title = attrs.get('text');
              if (title !== undefined) {
                feed.title = title;
              } else {
                const titleAttr = attrs.get('title');
                if (titleAttr !== undefined) {
                  feed.title = titleAttr;
                }
              }
              const htmlUrl = attrs.get('htmlurl');
              if (htmlUrl !== undefined) {
                feed.htmlUrl = htmlUrl;
              }
              feeds.push(feed);
            }
          }
        }
        return true;
      }
    });

    hilog.info(DOMAIN, TAG, 'Parsed %{public}d feeds from OPML', feeds.length);
    return feeds;
  }
}
