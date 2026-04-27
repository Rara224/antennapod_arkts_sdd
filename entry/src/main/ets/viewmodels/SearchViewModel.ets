import { FeedItemDao } from '../database/FeedItemDao';
import { FeedItemDataSource } from '../datasource/FeedItemDataSource';

export class SearchViewModel {
  private feedItemDao: FeedItemDao = new FeedItemDao();
  searchResultsDataSource: FeedItemDataSource = new FeedItemDataSource();
  resultCount: number = 0;

  async search(query: string): Promise<void> {
    if (query.length === 0) {
      this.clearResults();
      return;
    }
    const items = await this.feedItemDao.searchItems(query);
    this.searchResultsDataSource.reloadAll(items);
    this.resultCount = items.length;
  }

  clearResults(): void {
    this.searchResultsDataSource.reloadAll([]);
    this.resultCount = 0;
  }
}
