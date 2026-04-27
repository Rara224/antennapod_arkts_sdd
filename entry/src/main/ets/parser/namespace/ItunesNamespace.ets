import { Feed } from '../../models/Feed';
import { FeedItem } from '../../models/FeedItem';
import { DateParser } from '../DateParser';

export function handleStartTag(
  tagName: string,
  attrs: Map<string, string>,
  feed: Feed,
  item: FeedItem | undefined,
  insideItem: boolean
): void {
  if (tagName === 'image') {
    const href = attrs.get('href');
    if (href !== undefined && href.length > 0) {
      if (insideItem && item !== undefined) {
        item.imageUrl = href;
      } else {
        feed.imageUrl = href;
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
  if (tagName === 'author') {
    if (!insideItem) {
      feed.author = text;
    }
  } else if (tagName === 'summary') {
    if (insideItem && item !== undefined) {
      if (item.description.length === 0) {
        item.description = text;
      }
    } else {
      if (feed.description.length === 0) {
        feed.description = text;
      }
    }
  } else if (tagName === 'subtitle') {
    if (!insideItem && feed.description.length === 0) {
      feed.description = text;
    }
  } else if (tagName === 'duration') {
    if (insideItem && item !== undefined && item.media !== null) {
      const durationMs = DateParser.parseDuration(text);
      if (durationMs > 0) {
        item.media.duration = durationMs;
      }
    }
  }
}
