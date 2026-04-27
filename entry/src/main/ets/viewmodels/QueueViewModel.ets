import { QueueDao } from '../database/QueueDao';
import { FeedItemDataSource } from '../datasource/FeedItemDataSource';
import { FeedItem } from '../models/FeedItem';

export class QueueViewModel {
  private queueDao: QueueDao = new QueueDao();
  queueDataSource: FeedItemDataSource = new FeedItemDataSource();
  queueSize: number = 0;
  totalDuration: number = 0;

  async loadQueue(): Promise<void> {
    const items = await this.queueDao.getQueue();
    this.queueDataSource.reloadAll(items);
    this.queueSize = items.length;
    this.totalDuration = 0;
    for (let i = 0; i < items.length; i++) {
      if (items[i].media !== null) {
        this.totalDuration += items[i].media!.duration;
      }
    }
  }

  async removeFromQueue(itemId: number): Promise<void> {
    await this.queueDao.removeFromQueue(itemId);
    const allItems = this.queueDataSource.getAll();
    for (let i = 0; i < allItems.length; i++) {
      if (allItems[i].id === itemId) {
        this.queueDataSource.removeItem(i);
        this.queueSize = this.queueDataSource.totalCount();
        break;
      }
    }
  }

  async moveInQueue(from: number, to: number): Promise<void> {
    this.queueDataSource.moveItem(from, to);
    const allItems = this.queueDataSource.getAll();
    const itemIds: number[] = [];
    const feedIds: number[] = [];
    for (let i = 0; i < allItems.length; i++) {
      itemIds.push(allItems[i].id);
      feedIds.push(allItems[i].feedId);
    }
    await this.queueDao.moveInQueue(itemIds, feedIds);
  }

  getDurationStr(): string {
    if (this.totalDuration <= 0) {
      return '';
    }
    const totalSeconds = Math.floor(this.totalDuration / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    if (hours > 0) {
      return 'Time left: ' + hours.toString() + ' hours ' + minutes.toString() + ' minutes';
    }
    return 'Time left: ' + minutes.toString() + ' minutes';
  }
}
