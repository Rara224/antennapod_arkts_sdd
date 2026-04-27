import { FeedItemDao } from '../database/FeedItemDao';
import { FeedItemDataSource } from '../datasource/FeedItemDataSource';

export class DownloadsViewModel {
  private feedItemDao: FeedItemDao = new FeedItemDao();
  downloadsDataSource: FeedItemDataSource = new FeedItemDataSource();
  downloadCount: number = 0;

  async loadDownloads(): Promise<void> {
    const items = await this.feedItemDao.getDownloadedItems();
    this.downloadsDataSource.reloadAll(items);
    this.downloadCount = items.length;
  }
}
