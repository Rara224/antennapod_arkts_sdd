import { FeedDao } from '../database/FeedDao';
import { FeedItemDao } from '../database/FeedItemDao';
import { QueueDao } from '../database/QueueDao';
import { FeedItemDataSource } from '../datasource/FeedItemDataSource';
import { FeedDataSource } from '../datasource/FeedDataSource';
import { FeedItem } from '../models/FeedItem';
import { PLAY_STATE_NEW } from '../common/Constants';

export class HomeViewModel {
  private feedDao: FeedDao = new FeedDao();
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private queueDao: QueueDao = new QueueDao();
  recentEpisodes: FeedItemDataSource = new FeedItemDataSource();
  continueListening: FeedItemDataSource = new FeedItemDataSource();
  newEpisodes: FeedItemDataSource = new FeedItemDataSource();
  surpriseEpisodes: FeedItemDataSource = new FeedItemDataSource();
  classicFeeds: FeedDataSource = new FeedDataSource();
  downloadedEpisodes: FeedItemDataSource = new FeedItemDataSource();
  subscriptionCount: number = 0;
  newEpisodeCount: number = 0;

  async loadData(): Promise<void> {
    const items = await this.feedItemDao.getRecentlyPublished(0, 50);
    this.recentEpisodes.reloadAll(items);

    const feeds = await this.feedDao.getAllFeeds();
    this.subscriptionCount = feeds.length;
    this.classicFeeds.reloadAll(feeds);

    // Continue listening: all queue items
    const queueItems = await this.queueDao.getQueue();
    this.continueListening.reloadAll(queueItems);

    // Filter new episodes from recent items
    const newItems: FeedItem[] = [];
    for (let i = 0; i < items.length; i++) {
      if (items[i].state === PLAY_STATE_NEW) {
        newItems.push(items[i]);
      }
    }
    this.newEpisodeCount = newItems.length;
    const limitedNew: FeedItem[] = [];
    const maxNew = 2;
    for (let i = 0; i < newItems.length && i < maxNew; i++) {
      limitedNew.push(newItems[i]);
    }
    this.newEpisodes.reloadAll(limitedNew);

    // Load random surprise episodes
    const randomItems = await this.feedItemDao.getRandomEpisodes(5);
    this.surpriseEpisodes.reloadAll(randomItems);

    // Load downloaded episodes (limit to 3 for home page)
    const allDownloaded = await this.feedItemDao.getDownloadedItems();
    const limitedDownloaded: FeedItem[] = [];
    const maxDownloads = 3;
    for (let i = 0; i < allDownloaded.length && i < maxDownloads; i++) {
      limitedDownloaded.push(allDownloaded[i]);
    }
    this.downloadedEpisodes.reloadAll(limitedDownloaded);
  }
}
