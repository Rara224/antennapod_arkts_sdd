import { FeedDao } from '../database/FeedDao';
import { FeedItemDao } from '../database/FeedItemDao';
import { FeedItemDataSource } from '../datasource/FeedItemDataSource';
import { FeedItem } from '../models/FeedItem';
import { FeedUpdateService } from '../network/FeedUpdateService';

export class EpisodeFilter {
  played: boolean = false;
  notPlayed: boolean = false;
  paused: boolean = false;
  notPaused: boolean = false;
  hasMedia: boolean = false;
  noMedia: boolean = false;
  downloaded: boolean = false;
  notDownloaded: boolean = false;

  isActive(): boolean {
    return this.played || this.notPlayed || this.paused || this.notPaused ||
      this.hasMedia || this.noMedia || this.downloaded || this.notDownloaded;
  }

  reset(): void {
    this.played = false;
    this.notPlayed = false;
    this.paused = false;
    this.notPaused = false;
    this.hasMedia = false;
    this.noMedia = false;
    this.downloaded = false;
    this.notDownloaded = false;
  }

  matches(item: FeedItem): boolean {
    if (!this.isActive()) {
      return true;
    }

    // Played / Not played
    if (this.played && !item.isPlayed()) {
      return false;
    }
    if (this.notPlayed && item.isPlayed()) {
      return false;
    }

    // Paused / Not paused (has partial progress)
    const isPaused = item.media !== null && item.media.position > 0 && !item.isPlayed();
    if (this.paused && !isPaused) {
      return false;
    }
    if (this.notPaused && isPaused) {
      return false;
    }

    // Has media / No media
    if (this.hasMedia && item.media === null) {
      return false;
    }
    if (this.noMedia && item.media !== null) {
      return false;
    }

    // Downloaded / Not downloaded
    const isDownloaded = item.media !== null && item.media.isDownloaded();
    if (this.downloaded && !isDownloaded) {
      return false;
    }
    if (this.notDownloaded && isDownloaded) {
      return false;
    }

    return true;
  }
}

export class FeedDetailViewModel {
  private feedDao: FeedDao = new FeedDao();
  private feedItemDao: FeedItemDao = new FeedItemDao();
  episodeDataSource: FeedItemDataSource = new FeedItemDataSource();
  feedTitle: string = '';
  author: string = '';
  imageUrl: string = '';
  description: string = '';
  link: string = '';
  downloadUrl: string = '';
  episodeCount: number = 0;
  private allItems: FeedItem[] = [];

  async loadFeed(feedId: number): Promise<void> {
    const feed = await this.feedDao.getFeed(feedId);
    if (feed !== null) {
      this.feedTitle = feed.getDisplayTitle();
      this.author = feed.author;
      this.imageUrl = feed.imageUrl;
      this.description = feed.description;
      this.link = feed.link;
      this.downloadUrl = feed.downloadUrl;
    }
    this.allItems = await this.feedItemDao.getFeedItems(feedId);
    this.episodeDataSource.reloadAll(this.allItems);
    this.episodeCount = this.allItems.length;
  }

  applyFilter(filter: EpisodeFilter): void {
    if (!filter.isActive()) {
      this.episodeDataSource.reloadAll(this.allItems);
      return;
    }
    const filtered: FeedItem[] = [];
    for (let i = 0; i < this.allItems.length; i++) {
      if (filter.matches(this.allItems[i])) {
        filtered.push(this.allItems[i]);
      }
    }
    this.episodeDataSource.reloadAll(filtered);
  }

  sortEpisodes(order: number): void {
    const items = this.allItems.slice();
    if (order === 0) {
      // Date: newest first (default)
      items.sort((a: FeedItem, b: FeedItem) => b.pubDate - a.pubDate);
    } else if (order === 1) {
      // Date: oldest first
      items.sort((a: FeedItem, b: FeedItem) => a.pubDate - b.pubDate);
    } else if (order === 2) {
      // Title A→Z
      items.sort((a: FeedItem, b: FeedItem) => a.title.localeCompare(b.title));
    } else if (order === 3) {
      // Duration: short→long
      items.sort((a: FeedItem, b: FeedItem) => {
        const aDur = a.media !== null ? a.media.duration : 0;
        const bDur = b.media !== null ? b.media.duration : 0;
        return aDur - bDur;
      });
    } else if (order === 4) {
      // Duration: long→short
      items.sort((a: FeedItem, b: FeedItem) => {
        const aDur = a.media !== null ? a.media.duration : 0;
        const bDur = b.media !== null ? b.media.duration : 0;
        return bDur - aDur;
      });
    }
    this.allItems = items;
    this.episodeDataSource.reloadAll(items);
  }

  async refreshFeed(feedId: number): Promise<void> {
    const service = new FeedUpdateService();
    await service.refreshFeed(feedId);
    await this.loadFeed(feedId);
  }

  async removeAllFromInbox(feedId: number): Promise<void> {
    await this.feedItemDao.markNewAsUnplayedForFeed(feedId);
    await this.loadFeed(feedId);
  }

  async deleteFeed(feedId: number): Promise<void> {
    const feed = await this.feedDao.getFeed(feedId);
    if (feed !== null) {
      await this.feedDao.removeFeed(feed);
    }
  }

  async archiveFeed(feedId: number): Promise<void> {
    await this.feedDao.setFeedState(feedId, 2);
  }
}
