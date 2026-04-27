import { FeedItemDao } from '../database/FeedItemDao';
import { FeedMediaDao } from '../database/FeedMediaDao';
import { FeedItemDataSource } from '../datasource/FeedItemDataSource';
import {
  EventBus,
  EVENT_PLAYBACK_HISTORY_CHANGED
} from '../common/EventBus';

export class PlaybackHistoryViewModel {
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private feedMediaDao: FeedMediaDao = new FeedMediaDao();
  historyDataSource: FeedItemDataSource = new FeedItemDataSource();
  historyCount: number = 0;

  async loadHistory(): Promise<void> {
    const items = await this.feedItemDao.getPlaybackHistory();
    this.historyDataSource.reloadAll(items);
    this.historyCount = items.length;
  }

  async clearHistory(): Promise<void> {
    await this.feedMediaDao.clearPlaybackHistory();
    this.historyDataSource.reloadAll([]);
    this.historyCount = 0;
    EventBus.getInstance().publish(EVENT_PLAYBACK_HISTORY_CHANGED, new Object());
  }
}
