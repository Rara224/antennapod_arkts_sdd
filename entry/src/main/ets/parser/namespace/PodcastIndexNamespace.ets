import { Feed } from '../../models/Feed';
import { FeedItem } from '../../models/FeedItem';

export function handleStartTag(
  tagName: string,
  attrs: Map<string, string>,
  feed: Feed,
  item: FeedItem | undefined,
  insideItem: boolean
): void {
  if (tagName === 'transcript' && insideItem && item !== undefined) {
    const url = attrs.get('url');
    const type = attrs.get('type');
    if (url !== undefined && url.length > 0) {
      item.podcastIndexTranscriptUrl = url;
      if (type !== undefined) {
        item.podcastIndexTranscriptType = type;
      }
    }
  } else if (tagName === 'chapters' && insideItem && item !== undefined) {
    const url = attrs.get('url');
    if (url !== undefined && url.length > 0) {
      item.podcastIndexChapterUrl = url;
      item.hasChapters = true;
    }
  }
}
