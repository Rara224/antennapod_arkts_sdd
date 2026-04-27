import { PLAY_STATE_NEW, PLAY_STATE_PLAYED } from '../common/Constants';
import { Chapter } from './Chapter';
import { Feed } from './Feed';
import { FeedMedia } from './FeedMedia';

/**
 * Represents a single podcast episode.
 */
export class FeedItem {
  id: number = 0;
  itemIdentifier: string = '';
  title: string = '';
  description: string = '';
  link: string = '';
  /** Publication date as timestamp in ms */
  pubDate: number = 0;
  /** -1=NEW, 0=UNPLAYED, 1=PLAYED */
  state: number = PLAY_STATE_NEW;
  paymentLink: string = '';
  media: FeedMedia | null = null;
  feed: Feed | null = null;
  feedId: number = 0;
  hasChapters: boolean = false;
  chapters: Chapter[] = [];
  imageUrl: string = '';
  autoDownloadEnabled: boolean = true;
  podcastIndexChapterUrl: string = '';
  podcastIndexTranscriptUrl: string = '';
  podcastIndexTranscriptType: string = '';
  socialInteractUrl: string = '';
  tags: Set<string> = new Set<string>();

  isNew(): boolean {
    return this.state === PLAY_STATE_NEW;
  }

  isPlayed(): boolean {
    return this.state === PLAY_STATE_PLAYED;
  }

  getImageLocation(): string {
    if (this.imageUrl.length > 0) {
      return this.imageUrl;
    }
    if (this.feed !== null && this.feed.imageUrl.length > 0) {
      return this.feed.imageUrl;
    }
    return '';
  }

  getPubDateStr(): string {
    if (this.pubDate <= 0) {
      return '';
    }
    const date = new Date(this.pubDate);
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    return year.toString() + '-' + pad(month) + '-' + pad(day);
  }

  getShortPubDateStr(): string {
    if (this.pubDate <= 0) {
      return '';
    }
    const date = new Date(this.pubDate);
    const now = new Date();
    const months: string[] = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const month = months[date.getMonth()];
    const day = date.getDate();
    if (date.getFullYear() === now.getFullYear()) {
      return month + ' ' + day.toString();
    }
    return month + ' ' + day.toString() + ', ' + date.getFullYear().toString();
  }
}
