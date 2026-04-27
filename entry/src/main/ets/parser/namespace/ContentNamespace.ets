import { FeedItem } from '../../models/FeedItem';

export function handleEndTag(
  tagName: string,
  text: string,
  item: FeedItem | undefined,
  insideItem: boolean
): void {
  if (tagName === 'encoded' && insideItem && item !== undefined) {
    // content:encoded takes priority over <description>
    item.description = text;
  }
}
