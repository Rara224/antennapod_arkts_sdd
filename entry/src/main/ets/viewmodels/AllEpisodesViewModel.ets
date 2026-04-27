import { FeedItemDao } from '../database/FeedItemDao';
import { FavoritesDao } from '../database/FavoritesDao';
import { FeedItemDataSource } from '../datasource/FeedItemDataSource';

const PAGE_SIZE: number = 50;

export class AllEpisodesViewModel {
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private favoritesDao: FavoritesDao = new FavoritesDao();
  private offset: number = 0;
  private favoriteOnly: boolean = false;
  episodeDataSource: FeedItemDataSource = new FeedItemDataSource();
  hasMore: boolean = true;

  async loadInitial(): Promise<void> {
    this.favoriteOnly = false;
    await this.reload();
  }

  async loadEpisodes(favoriteOnly: boolean): Promise<void> {
    this.favoriteOnly = favoriteOnly;
    await this.reload();
  }

  private async reload(): Promise<void> {
    this.offset = 0;
    this.hasMore = true;
    if (this.favoriteOnly) {
      const items = await this.favoritesDao.getFavorites();
      this.episodeDataSource.reloadAll(items);
      this.hasMore = false;
    } else {
      const items = await this.feedItemDao.getRecentlyPublished(0, PAGE_SIZE);
      this.episodeDataSource.reloadAll(items);
      this.offset = items.length;
      this.hasMore = items.length >= PAGE_SIZE;
    }
  }

  async loadMore(): Promise<void> {
    if (!this.hasMore || this.favoriteOnly) {
      return;
    }
    const items = await this.feedItemDao.getRecentlyPublished(this.offset, PAGE_SIZE);
    this.episodeDataSource.appendItems(items);
    this.offset += items.length;
    this.hasMore = items.length >= PAGE_SIZE;
  }
}
