import { FeedDao } from '../database/FeedDao';
import { FeedItemDao } from '../database/FeedItemDao';
import { FeedDataSource } from '../datasource/FeedDataSource';
import { Feed } from '../models/Feed';
import { EventBus, EVENT_SUBSCRIPTION_REMOVED, EVENT_INBOX_CHANGED } from '../common/EventBus';
import { FeedUpdateService } from '../network/FeedUpdateService';

export class SubscriptionViewModel {
  private feedDao: FeedDao = new FeedDao();
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private feedUpdateService: FeedUpdateService = new FeedUpdateService();
  feedDataSource: FeedDataSource = new FeedDataSource();

  async loadFeeds(): Promise<void> {
    const feeds = await this.feedDao.getAllFeedsWithStats();
    this.feedDataSource.reloadAll(feeds);
  }

  async deleteFeed(feedId: number): Promise<void> {
    const feed = await this.feedDao.getFeed(feedId);
    if (feed !== null) {
      await this.feedDao.removeFeed(feed);
      EventBus.getInstance().publish(EVENT_SUBSCRIPTION_REMOVED, new Object());
    }
  }

  async deleteFeeds(feedIds: number[]): Promise<void> {
    for (let i = 0; i < feedIds.length; i++) {
      const feed = await this.feedDao.getFeed(feedIds[i]);
      if (feed !== null) {
        await this.feedDao.removeFeed(feed);
      }
    }
    EventBus.getInstance().publish(EVENT_SUBSCRIPTION_REMOVED, new Object());
  }

  async removeFromInboxForFeeds(feedIds: number[]): Promise<void> {
    for (let i = 0; i < feedIds.length; i++) {
      await this.feedItemDao.markNewAsUnplayedForFeed(feedIds[i]);
    }
    EventBus.getInstance().publish(EVENT_INBOX_CHANGED, new Object());
  }

  async updateTagsForFeeds(feedIds: number[], tag: string): Promise<void> {
    for (let i = 0; i < feedIds.length; i++) {
      const feed = await this.feedDao.getFeed(feedIds[i]);
      if (feed !== null) {
        feed.preferences.tags.add(tag);
        await this.feedDao.setFeedPreferences(feed.preferences, feed.id);
      }
    }
  }

  async refreshAllFeeds(): Promise<void> {
    await this.feedUpdateService.refreshAllFeeds();
  }
}
