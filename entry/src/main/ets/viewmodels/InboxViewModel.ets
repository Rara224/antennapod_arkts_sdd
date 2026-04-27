import { FeedItemDao } from '../database/FeedItemDao';
import { FeedItemDataSource } from '../datasource/FeedItemDataSource';
import { PLAY_STATE_UNPLAYED } from '../common/Constants';

const PAGE_SIZE: number = 50;

// 排序维度：播放时长、下载时间
export const INBOX_SORT_DURATION_ASC: number = 0;
export const INBOX_SORT_DURATION_DESC: number = 1;
export const INBOX_SORT_DOWNLOAD_DATE_ASC: number = 2;
export const INBOX_SORT_DOWNLOAD_DATE_DESC: number = 3;

export class InboxViewModel {
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private offset: number = 0;
  episodeDataSource: FeedItemDataSource = new FeedItemDataSource();
  hasMore: boolean = true;
  currentSort: number = INBOX_SORT_DURATION_DESC;

  private getOrderByClause(): string {
    switch (this.currentSort) {
      case INBOX_SORT_DURATION_ASC:
        return 'fm.duration ASC';
      case INBOX_SORT_DURATION_DESC:
        return 'fm.duration DESC';
      case INBOX_SORT_DOWNLOAD_DATE_ASC:
        return 'fm.downloaded ASC';
      case INBOX_SORT_DOWNLOAD_DATE_DESC:
        return 'fm.downloaded DESC';
      default:
        return 'fi.pubDate DESC';
    }
  }

  async loadInitial(): Promise<void> {
    this.offset = 0;
    this.hasMore = true;
    const items = await this.feedItemDao.getNewItems(0, PAGE_SIZE, this.getOrderByClause());
    this.episodeDataSource.reloadAll(items);
    this.offset = items.length;
    this.hasMore = items.length >= PAGE_SIZE;
  }

  async loadMore(): Promise<void> {
    if (!this.hasMore) {
      return;
    }
    const items = await this.feedItemDao.getNewItems(this.offset, PAGE_SIZE, this.getOrderByClause());
    this.episodeDataSource.appendItems(items);
    this.offset += items.length;
    this.hasMore = items.length >= PAGE_SIZE;
  }

  async removeFromInbox(itemId: number): Promise<void> {
    await this.feedItemDao.markItemPlayed(itemId, PLAY_STATE_UNPLAYED);
  }

  async removeAllFromInbox(): Promise<void> {
    await this.feedItemDao.markAllNewAsUnplayed();
    this.episodeDataSource.reloadAll([]);
    this.offset = 0;
    this.hasMore = false;
  }
}
