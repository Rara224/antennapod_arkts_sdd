import { Feed } from '../../models/Feed';
import { FeedItem } from '../../models/FeedItem';
import { DateParser } from '../DateParser';

export function handleEndTag(
  tagName: string,
  text: string,
  feed: Feed,
  item: FeedItem | undefined,
  insideItem: boolean
): void {
  if (tagName === 'date') {
    if (insideItem && item !== undefined && item.pubDate === 0) {
      item.pubDate = DateParser.parseDate(text);
    }
  } else if (tagName === 'creator') {
    if (!insideItem && feed.author.length === 0) {
      feed.author = text;
    }
  }
}
