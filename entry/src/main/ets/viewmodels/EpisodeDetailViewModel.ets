import { FeedItemDao } from '../database/FeedItemDao';
import { FeedDao } from '../database/FeedDao';
import { FavoritesDao } from '../database/FavoritesDao';
import { QueueDao } from '../database/QueueDao';
import { ChapterDao } from '../database/ChapterDao';
import { FeedMediaDao } from '../database/FeedMediaDao';
import { Chapter } from '../models/Chapter';
import { PLAY_STATE_PLAYED, PLAY_STATE_UNPLAYED } from '../common/Constants';
import {
  EventBus,
  EVENT_QUEUE_CHANGED,
  EVENT_FAVORITES_CHANGED,
  EVENT_EPISODE_PLAY_STATE_CHANGED
} from '../common/EventBus';

export class EpisodeDetailViewModel {
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private feedDao: FeedDao = new FeedDao();
  private favoritesDao: FavoritesDao = new FavoritesDao();
  private queueDao: QueueDao = new QueueDao();
  private chapterDao: ChapterDao = new ChapterDao();
  private mediaDao: FeedMediaDao = new FeedMediaDao();
  private itemId: number = 0;
  private feedId: number = 0;
  title: string = '';
  description: string = '';
  pubDate: string = '';
  feedTitle: string = '';
  isFavorite: boolean = false;
  isInQueue: boolean = false;
  isDownloaded: boolean = false;
  durationStr: string = '';
  downloadUrl: string = '';
  mimeType: string = '';
  imageUrl: string = '';
  feedImageUrl: string = '';
  episodeLink: string = '';
  chapters: Chapter[] = [];
  state: number = 0;

  async loadEpisode(episodeId: number): Promise<void> {
    this.itemId = episodeId;
    const item = await this.feedItemDao.getFeedItem(episodeId);
    if (item === null) {
      return;
    }
    this.feedId = item.feedId;
    this.title = item.title;
    this.description = item.description;
    this.pubDate = item.getPubDateStr();
    this.state = item.state;
    this.imageUrl = item.imageUrl;
    this.episodeLink = item.link;

    if (item.media !== null) {
      this.isDownloaded = item.media.isDownloaded();
      this.durationStr = item.media.getDurationStr();
      this.downloadUrl = item.media.downloadUrl;
      this.mimeType = item.media.mimeType;
    }

    const feed = await this.feedDao.getFeed(item.feedId);
    if (feed !== null) {
      this.feedTitle = feed.getDisplayTitle();
      this.feedImageUrl = feed.imageUrl;
      if (this.imageUrl.length === 0) {
        this.imageUrl = feed.imageUrl;
      }
    }

    this.isFavorite = await this.favoritesDao.isFavorite(episodeId);
    this.isInQueue = await this.queueDao.isInQueue(episodeId);

    if (item.hasChapters) {
      this.chapters = await this.chapterDao.getChapters(episodeId);
    }
  }

  async toggleFavorite(): Promise<void> {
    if (this.isFavorite) {
      await this.favoritesDao.removeFromFavorites(this.itemId);
      this.isFavorite = false;
    } else {
      await this.favoritesDao.addToFavorites(this.itemId, this.feedId);
      this.isFavorite = true;
    }
    EventBus.getInstance().publish(EVENT_FAVORITES_CHANGED, new Object());
  }

  async toggleQueue(): Promise<void> {
    if (this.isInQueue) {
      await this.queueDao.removeFromQueue(this.itemId);
      this.isInQueue = false;
    } else {
      await this.queueDao.addToQueue(this.itemId, this.feedId);
      this.isInQueue = true;
    }
    EventBus.getInstance().publish(EVENT_QUEUE_CHANGED, new Object());
  }

  async markPlayed(): Promise<void> {
    const newState = this.state === PLAY_STATE_PLAYED ? PLAY_STATE_UNPLAYED : PLAY_STATE_PLAYED;
    await this.feedItemDao.markItemPlayed(this.itemId, newState);
    this.state = newState;
    EventBus.getInstance().publish(EVENT_EPISODE_PLAY_STATE_CHANGED, new Object());
  }

  async resetPlaybackPosition(): Promise<void> {
    const media = await this.mediaDao.getFeedMediaByItemId(this.itemId);
    if (media !== null) {
      media.position = 0;
      await this.mediaDao.setFeedMedia(media);
    }
  }
}
