import { Feed } from '../../models/Feed';
import { FeedItem } from '../../models/FeedItem';
import { FeedMedia } from '../../models/FeedMedia';

export function handleStartTag(
  tagName: string,
  attrs: Map<string, string>,
  feed: Feed,
  item: FeedItem | undefined,
  insideItem: boolean
): void {
  if (!insideItem || item === undefined) {
    return;
  }
  if (tagName === 'content') {
    const medium = attrs.get('medium');
    const url = attrs.get('url');
    // media:content medium="image" → episode image
    if (medium === 'image' && url !== undefined && url.length > 0) {
      if (item.imageUrl.length === 0) {
        item.imageUrl = url;
      }
    } else if (item.media === null) {
      // Only create media from media:content if no enclosure exists
      if (url !== undefined && url.length > 0) {
        const media = new FeedMedia();
        media.downloadUrl = url;
        const type = attrs.get('type');
        if (type !== undefined) {
          media.mimeType = type;
        }
        const fileSize = attrs.get('fileSize');
        if (fileSize !== undefined) {
          const size = parseInt(fileSize);
          if (!isNaN(size)) {
            media.size = size;
          }
        }
        const duration = attrs.get('duration');
        if (duration !== undefined) {
          const dur = parseInt(duration);
          if (!isNaN(dur)) {
            media.duration = dur * 1000;
          }
        }
        item.media = media;
      }
    }
  } else if (tagName === 'thumbnail') {
    if (item.imageUrl.length === 0) {
      const url = attrs.get('url');
      if (url !== undefined) {
        item.imageUrl = url;
      }
    }
  }
}

export function handleEndTag(
  tagName: string,
  text: string,
  feed: Feed,
  item: FeedItem | undefined,
  insideItem: boolean
): void {
  if (!insideItem || item === undefined) {
    return;
  }
  if (tagName === 'description') {
    if (item.description.length === 0) {
      item.description = text;
    }
  }
}
