import { hilog } from '@kit.PerformanceAnalysisKit';
import { HttpClient, HttpCredentials } from './HttpClient';
import { NetworkUtils } from './NetworkUtils';
import { FeedParser } from '../parser/FeedParser';
import { FeedDao } from '../database/FeedDao';
import { FeedItemDao } from '../database/FeedItemDao';
import { FeedMediaDao } from '../database/FeedMediaDao';
import { ChapterDao } from '../database/ChapterDao';
import { Feed } from '../models/Feed';
import { FeedItem } from '../models/FeedItem';
import { FEED_STATE_SUBSCRIBED, PLAY_STATE_UNPLAYED } from '../common/Constants';
import {
  EventBus,
  EVENT_SUBSCRIPTION_ADDED,
  EVENT_FEED_UPDATED,
  EVENT_FEED_UPDATE_RUNNING
} from '../common/EventBus';
import {
  SubscriptionAddedData,
  FeedUpdateRunningData
} from '../common/EventData';

const DOMAIN: number = 0x0000;
const TAG: string = 'FeedUpdateService';

export class FeedUpdateService {
  private feedDao: FeedDao = new FeedDao();
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private feedMediaDao: FeedMediaDao = new FeedMediaDao();
  private chapterDao: ChapterDao = new ChapterDao();
  private parser: FeedParser = new FeedParser();

  /**
   * Subscribe to a new feed: fetch → parse → store → emit event.
   * Returns feedId on success, throws on failure.
   */
  async subscribeFeed(url: string): Promise<number> {
    // Check network
    const hasNetwork = await NetworkUtils.isNetworkAvailable();
    if (!hasNetwork) {
      throw new Error('No network connection');
    }

    // Check if already subscribed
    const existing = await this.feedDao.getFeedByUrl(url);
    if (existing !== null) {
      throw new Error('Already subscribed to this feed');
    }

    hilog.info(DOMAIN, TAG, 'Subscribing to feed: %{public}s', url);

    // Fetch XML
    const response = await HttpClient.get(url, new Map(), undefined);
    if (response.responseCode === 404) {
      throw new Error('Feed not found (404). Please check the URL — it may be case-sensitive.');
    }
    if (response.responseCode !== 200) {
      throw new Error('Failed to fetch feed: HTTP ' + response.responseCode.toString());
    }

    // Handle permanent redirects
    let finalUrl = url;
    if (response.redirectUrl.length > 0) {
      finalUrl = response.redirectUrl;
    }

    // Parse XML
    const feed = this.parser.parse(response.body);
    feed.downloadUrl = finalUrl;
    feed.state = FEED_STATE_SUBSCRIBED;

    // Save last-modified/etag for conditional requests
    const lastModified = response.headers.get('last-modified');
    if (lastModified !== undefined) {
      feed.lastModified = lastModified;
    }

    // Save feed to DB
    const feedId = await this.feedDao.setFeed(feed);
    hilog.info(DOMAIN, TAG, 'Feed saved with id=%{public}d, items=%{public}d',
      feedId, feed.items.length);

    // Save items, media, chapters
    // Only the latest episode stays NEW (inbox); older ones become UNPLAYED
    for (let i = 1; i < feed.items.length; i++) {
      feed.items[i].state = PLAY_STATE_UNPLAYED;
    }
    await this.saveItems(feed.items, feedId);

    // Emit event
    EventBus.getInstance().publish(EVENT_SUBSCRIPTION_ADDED,
      new SubscriptionAddedData(feedId));

    return feedId;
  }

  /**
   * Refresh an existing feed: conditional request → parse → merge new episodes.
   */
  async refreshFeed(feedId: number): Promise<void> {
    const existingFeed = await this.feedDao.getFeed(feedId);
    if (existingFeed === null) {
      hilog.warn(DOMAIN, TAG, 'Feed not found: %{public}d', feedId);
      return;
    }

    const hasNetwork = await NetworkUtils.isNetworkAvailable();
    if (!hasNetwork) {
      throw new Error('No network connection');
    }

    hilog.info(DOMAIN, TAG, 'Refreshing feed: %{public}s', existingFeed.downloadUrl);

    // Build credentials if stored
    let credentials: HttpCredentials | undefined = undefined;
    if (existingFeed.preferences.username.length > 0) {
      credentials = new HttpCredentials(
        existingFeed.preferences.username,
        existingFeed.preferences.password
      );
    }

    // Conditional request with If-Modified-Since / If-None-Match
    const etag = this.getEtag(existingFeed);
    const response = await HttpClient.getConditional(
      existingFeed.downloadUrl,
      existingFeed.lastModified,
      etag,
      credentials
    );

    // 304 Not Modified — nothing to do
    if (response.responseCode === 304) {
      hilog.info(DOMAIN, TAG, 'Feed not modified: %{public}d', feedId);
      return;
    }

    if (response.responseCode !== 200) {
      existingFeed.lastUpdateFailed = true;
      await this.feedDao.setFeed(existingFeed);
      throw new Error('Failed to refresh feed: HTTP ' + response.responseCode.toString());
    }

    // Handle permanent redirects
    if (response.redirectUrl.length > 0) {
      existingFeed.downloadUrl = response.redirectUrl;
    }

    // Update last-modified
    const newLastModified = response.headers.get('last-modified');
    if (newLastModified !== undefined) {
      existingFeed.lastModified = newLastModified;
    }

    // Parse updated feed
    const parsedFeed = this.parser.parse(response.body);

    // Update feed-level metadata
    existingFeed.feedTitle = parsedFeed.feedTitle;
    if (parsedFeed.imageUrl.length > 0) {
      existingFeed.imageUrl = parsedFeed.imageUrl;
    }
    if (parsedFeed.description.length > 0) {
      existingFeed.description = parsedFeed.description;
    }
    if (parsedFeed.author.length > 0) {
      existingFeed.author = parsedFeed.author;
    }
    if (parsedFeed.link.length > 0) {
      existingFeed.link = parsedFeed.link;
    }
    existingFeed.lastUpdateFailed = false;
    existingFeed.lastRefreshAttempt = Date.now();
    await this.feedDao.setFeed(existingFeed);

    // Merge new episodes (only insert items not already in DB)
    let newItemCount = 0;
    for (let i = 0; i < parsedFeed.items.length; i++) {
      const parsedItem = parsedFeed.items[i];
      const mediaUrl = parsedItem.media !== null ? parsedItem.media.downloadUrl : '';
      const existingItem = await this.feedItemDao.getFeedItemByGuidOrUrl(
        feedId, parsedItem.itemIdentifier, mediaUrl
      );
      if (existingItem === null) {
        // New episode
        parsedItem.feedId = feedId;
        const itemId = await this.feedItemDao.setFeedItem(parsedItem);
        if (parsedItem.media !== null) {
          parsedItem.media.itemId = itemId;
          await this.feedMediaDao.setFeedMedia(parsedItem.media);
        }
        if (parsedItem.chapters.length > 0) {
          await this.chapterDao.setChapters(itemId, parsedItem.chapters);
        }
        newItemCount++;
      } else {
        // Update existing episode's imageUrl if it was missing
        if (existingItem.imageUrl.length === 0 && parsedItem.imageUrl.length > 0) {
          existingItem.imageUrl = parsedItem.imageUrl;
          await this.feedItemDao.setFeedItem(existingItem);
        }
        // Repair missing media downloadUrl (getFeedItemByGuidOrUrl 不含 media，需单独加载)
        if (parsedItem.media !== null && parsedItem.media.downloadUrl.length > 0) {
          const existingMedia = await this.feedMediaDao.getFeedMediaByItemId(existingItem.id);
          if (existingMedia !== null && existingMedia.downloadUrl.length === 0) {
            existingMedia.downloadUrl = parsedItem.media.downloadUrl;
            if (parsedItem.media.mimeType.length > 0) {
              existingMedia.mimeType = parsedItem.media.mimeType;
            }
            if (parsedItem.media.size > 0 && existingMedia.size === 0) {
              existingMedia.size = parsedItem.media.size;
            }
            await this.feedMediaDao.setFeedMedia(existingMedia);
          }
        }
      }
    }

    hilog.info(DOMAIN, TAG, 'Feed %{public}d refreshed, %{public}d new items',
      feedId, newItemCount);

    EventBus.getInstance().publish(EVENT_FEED_UPDATED, new Object());
  }

  /**
   * Refresh all subscribed feeds.
   */
  async refreshAllFeeds(): Promise<void> {
    EventBus.getInstance().publish(EVENT_FEED_UPDATE_RUNNING,
      new FeedUpdateRunningData(true));

    try {
      const feeds = await this.feedDao.getAllFeeds();
      for (let i = 0; i < feeds.length; i++) {
        const feed = feeds[i];
        if (feed.preferences.keepUpdated) {
          try {
            await this.refreshFeed(feed.id);
          } catch (e) {
            hilog.error(DOMAIN, TAG, 'Failed to refresh feed %{public}d: %{public}s',
              feed.id, JSON.stringify(e));
          }
        }
      }
    } finally {
      EventBus.getInstance().publish(EVENT_FEED_UPDATE_RUNNING,
        new FeedUpdateRunningData(false));
    }
  }

  private async saveItems(items: FeedItem[], feedId: number): Promise<void> {
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      item.feedId = feedId;
      const itemId = await this.feedItemDao.setFeedItem(item);
      if (item.media !== null) {
        item.media.itemId = itemId;
        await this.feedMediaDao.setFeedMedia(item.media);
      }
      if (item.chapters.length > 0) {
        await this.chapterDao.setChapters(itemId, item.chapters);
      }
    }
  }

  private getEtag(feed: Feed): string {
    // ETag stored alongside lastModified is not in the current schema,
    // so return empty for now. Can be added to Feed model later.
    return '';
  }
}
