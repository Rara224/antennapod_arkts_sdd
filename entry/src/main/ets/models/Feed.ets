import { FEED_STATE_SUBSCRIBED } from '../common/Constants';
import { FeedFunding } from './FeedFunding';
import { FeedItem } from './FeedItem';
import { FeedPreferences } from './FeedPreferences';

/**
 * Represents a podcast subscription (RSS/Atom feed).
 */
export class Feed {
  id: number = 0;
  feedTitle: string = '';
  customTitle: string = '';
  localFileUrl: string = '';
  downloadUrl: string = '';
  feedIdentifier: string = '';
  link: string = '';
  description: string = '';
  language: string = '';
  author: string = '';
  imageUrl: string = '';
  /** "RSS2" or "Atom" */
  type: string = '';
  lastModified: string = '';
  lastRefreshAttempt: number = 0;
  paged: boolean = false;
  nextPageLink: string = '';
  lastUpdateFailed: boolean = false;
  /** 0=NOT_SUBSCRIBED, 1=SUBSCRIBED, 2=ARCHIVED */
  state: number = FEED_STATE_SUBSCRIBED;
  /** Sort order identifier, stored as string in DB */
  sortOrder: string = '';
  /** Page number for paged feeds */
  pageNr: number = 0;

  items: FeedItem[] = [];
  preferences: FeedPreferences = new FeedPreferences();
  fundingList: FeedFunding[] = [];

  /** Runtime-only: episode count from aggregation query */
  episodeCount: number = 0;
  /** Runtime-only: total duration in ms from aggregation query */
  totalDuration: number = 0;

  getDisplayTitle(): string {
    if (this.customTitle.length > 0) {
      return this.customTitle;
    }
    return this.feedTitle;
  }

  isSubscribed(): boolean {
    return this.state === FEED_STATE_SUBSCRIBED;
  }
}
