import { HttpClient } from '../network/HttpClient';
import { FeedParser } from '../parser/FeedParser';
import { FeedDao } from '../database/FeedDao';
import { FeedUpdateService } from '../network/FeedUpdateService';
import { Feed } from '../models/Feed';
import { FeedItem } from '../models/FeedItem';

export class OnlineFeedViewModel {
  feed: Feed | null = null;
  previewItems: FeedItem[] = [];
  isSubscribed: boolean = false;
  isLoading: boolean = false;
  errorMessage: string = '';

  private feedDao: FeedDao = new FeedDao();
  private feedUpdateService: FeedUpdateService = new FeedUpdateService();
  private parser: FeedParser = new FeedParser();

  async loadFeed(feedUrl: string): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const response = await HttpClient.get(feedUrl, new Map(), undefined);
      if (response.responseCode !== 200) {
        this.errorMessage = 'Failed to fetch feed: HTTP ' + response.responseCode.toString();
        return;
      }

      this.feed = this.parser.parse(response.body);
      this.feed.downloadUrl = feedUrl;

      // Limit preview to 20 items
      if (this.feed.items.length > 20) {
        this.previewItems = this.feed.items.slice(0, 20);
      } else {
        this.previewItems = this.feed.items;
      }

      // Check if already subscribed
      const existing = await this.feedDao.getFeedByUrl(feedUrl);
      this.isSubscribed = existing !== null;
    } catch (e) {
      if (e instanceof Error) {
        this.errorMessage = e.message;
      } else {
        this.errorMessage = 'Failed to load feed';
      }
    } finally {
      this.isLoading = false;
    }
  }

  async subscribe(feedUrl: string): Promise<void> {
    await this.feedUpdateService.subscribeFeed(feedUrl);
    this.isSubscribed = true;
  }
}
