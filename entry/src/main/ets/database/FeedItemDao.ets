import { relationalStore } from '@kit.ArkData';
import { PodDatabase } from './PodDatabase';
import { FeedItem } from '../models/FeedItem';
import { FeedMedia } from '../models/FeedMedia';
import { Feed } from '../models/Feed';
import { TABLE_FEED_ITEMS, TABLE_FEED_MEDIA, TABLE_FEEDS, PLAY_STATE_NEW, PLAY_STATE_UNPLAYED } from '../common/Constants';

export class FeedItemDao {
  private getStore(): relationalStore.RdbStore {
    return PodDatabase.getInstance().getStore();
  }

  async getFeedItem(itemId: number): Promise<FeedItem | null> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time ' +
      'FROM ' + TABLE_FEED_ITEMS + ' fi ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'WHERE fi.id = ?', [itemId]
    );
    try {
      if (resultSet.goToFirstRow()) {
        return this.parseItemWithMedia(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getFeedItemByGuidOrUrl(feedId: number, guid: string, url: string): Promise<FeedItem | null> {
    const store = this.getStore();
    let resultSet: relationalStore.ResultSet;
    if (guid.length > 0) {
      resultSet = await store.querySql(
        'SELECT * FROM ' + TABLE_FEED_ITEMS + ' WHERE feed = ? AND item_identifier = ?',
        [feedId, guid]
      );
    } else {
      resultSet = await store.querySql(
        'SELECT fi.* FROM ' + TABLE_FEED_ITEMS + ' fi ' +
        'INNER JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
        'WHERE fi.feed = ? AND fm.download_url = ?',
        [feedId, url]
      );
    }
    try {
      if (resultSet.goToFirstRow()) {
        return this.parseItemResultSet(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getPlaybackHistory(): Promise<FeedItem[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time, ' +
      'f.title AS feed_title, f.custom_title AS feed_custom_title, ' +
      'f.image_url AS feed_image_url, f.author AS feed_author ' +
      'FROM ' + TABLE_FEED_ITEMS + ' fi ' +
      'INNER JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'INNER JOIN ' + TABLE_FEEDS + ' f ON f.id = fi.feed ' +
      'WHERE fm.last_played_time > 0 OR fm.playback_completion_date > 0 ' +
      'ORDER BY CASE WHEN fm.last_played_time > fm.playback_completion_date ' +
      'THEN fm.last_played_time ELSE fm.playback_completion_date END DESC'
    );
    try {
      const items: FeedItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = this.parseItemWithMedia(resultSet);
        this.parseFeedFromJoin(resultSet, item);
        items.push(item);
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async getFeedItems(feedId: number): Promise<FeedItem[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time, ' +
      'f.title AS feed_title, f.custom_title AS feed_custom_title, ' +
      'f.image_url AS feed_image_url, f.author AS feed_author ' +
      'FROM ' + TABLE_FEED_ITEMS + ' fi ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'INNER JOIN ' + TABLE_FEEDS + ' f ON f.id = fi.feed ' +
      'WHERE fi.feed = ? ORDER BY fi.pubDate DESC', [feedId]
    );
    try {
      const items: FeedItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = this.parseItemWithMedia(resultSet);
        this.parseFeedFromJoin(resultSet, item);
        items.push(item);
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async getRecentlyPublished(offset: number, limit: number): Promise<FeedItem[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time, ' +
      'f.title AS feed_title, f.custom_title AS feed_custom_title, ' +
      'f.image_url AS feed_image_url, f.author AS feed_author ' +
      'FROM ' + TABLE_FEED_ITEMS + ' fi ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'INNER JOIN ' + TABLE_FEEDS + ' f ON f.id = fi.feed ' +
      'ORDER BY fi.pubDate DESC LIMIT ? OFFSET ?', [limit, offset]
    );
    try {
      const items: FeedItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = this.parseItemWithMedia(resultSet);
        this.parseFeedFromJoin(resultSet, item);
        items.push(item);
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async getNewItems(offset: number, limit: number,
    orderBy: string = 'fi.pubDate DESC'): Promise<FeedItem[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time, ' +
      'f.title AS feed_title, f.custom_title AS feed_custom_title, ' +
      'f.image_url AS feed_image_url, f.author AS feed_author ' +
      'FROM ' + TABLE_FEED_ITEMS + ' fi ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'INNER JOIN ' + TABLE_FEEDS + ' f ON f.id = fi.feed ' +
      'WHERE fi.read = -1 ' +
      'ORDER BY ' + orderBy + ' LIMIT ? OFFSET ?', [limit, offset]
    );
    try {
      const items: FeedItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = this.parseItemWithMedia(resultSet);
        this.parseFeedFromJoin(resultSet, item);
        items.push(item);
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async searchItems(query: string): Promise<FeedItem[]> {
    const store = this.getStore();
    const searchTerm = '%' + query + '%';
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time ' +
      'FROM ' + TABLE_FEED_ITEMS + ' fi ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'WHERE fi.title LIKE ? OR fi.description LIKE ? ' +
      'ORDER BY fi.pubDate DESC', [searchTerm, searchTerm]
    );
    try {
      const items: FeedItem[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.parseItemWithMedia(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Insert or update a FeedItem. Returns the item id.
   */
  async setFeedItem(item: FeedItem): Promise<number> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'title': item.title,
      'pubDate': item.pubDate,
      'read': item.state,
      'link': item.link,
      'description': item.description,
      'payment_link': item.paymentLink,
      'feed': item.feedId,
      'has_simple_chapters': item.hasChapters ? 1 : 0,
      'item_identifier': item.itemIdentifier,
      'image_url': item.imageUrl,
      'auto_download': item.autoDownloadEnabled ? 1 : 0,
      'podcastindex_chapter_url': item.podcastIndexChapterUrl,
      'podcastindex_transcript_type': item.podcastIndexTranscriptType,
      'podcastindex_transcript_url': item.podcastIndexTranscriptUrl,
      'social_interact_url': item.socialInteractUrl
    };

    if (item.id > 0) {
      const predicates = new relationalStore.RdbPredicates(TABLE_FEED_ITEMS);
      predicates.equalTo('id', item.id);
      await store.update(bucket, predicates);
      return item.id;
    }

    const rowId = await store.insert(TABLE_FEED_ITEMS, bucket);
    item.id = rowId;
    return rowId;
  }

  async markItemPlayed(itemId: number, played: number): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'read': played
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEED_ITEMS);
    predicates.equalTo('id', itemId);
    await store.update(bucket, predicates);
  }

  async getDownloadedItems(): Promise<FeedItem[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time, ' +
      'f.title AS feed_title, f.custom_title AS feed_custom_title, ' +
      'f.image_url AS feed_image_url, f.author AS feed_author ' +
      'FROM ' + TABLE_FEED_ITEMS + ' fi ' +
      'INNER JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'INNER JOIN ' + TABLE_FEEDS + ' f ON f.id = fi.feed ' +
      'WHERE fm.file_url IS NOT NULL AND fm.file_url != ? ' +
      'ORDER BY fm.downloaded DESC', ['']
    );
    try {
      const items: FeedItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = this.parseItemWithMedia(resultSet);
        this.parseFeedFromJoin(resultSet, item);
        items.push(item);
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async getPlayedEpisodeCount(): Promise<number> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT COUNT(*) AS cnt FROM ' + TABLE_FEED_ITEMS + ' WHERE read = 1'
    );
    try {
      if (resultSet.goToFirstRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('cnt'));
      }
      return 0;
    } finally {
      resultSet.close();
    }
  }

  async markAllNewAsUnplayed(): Promise<void> {
    const store = this.getStore();
    await store.executeSql(
      'UPDATE ' + TABLE_FEED_ITEMS + ' SET read = ? WHERE read = ?', [PLAY_STATE_UNPLAYED, PLAY_STATE_NEW]
    );
  }

  async markNewAsUnplayedForFeed(feedId: number): Promise<void> {
    const store = this.getStore();
    await store.executeSql(
      'UPDATE ' + TABLE_FEED_ITEMS + ' SET read = ? WHERE read = ? AND feed = ?',
      [PLAY_STATE_UNPLAYED, PLAY_STATE_NEW, feedId]
    );
  }

  async getRandomEpisodes(limit: number): Promise<FeedItem[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time, ' +
      'f.title AS feed_title, f.custom_title AS feed_custom_title, ' +
      'f.image_url AS feed_image_url, f.author AS feed_author ' +
      'FROM ' + TABLE_FEED_ITEMS + ' fi ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'INNER JOIN ' + TABLE_FEEDS + ' f ON f.id = fi.feed ' +
      'GROUP BY fi.feed ' +
      'ORDER BY RANDOM() LIMIT ?', [limit]
    );
    try {
      const items: FeedItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = this.parseItemWithMedia(resultSet);
        this.parseFeedFromJoin(resultSet, item);
        items.push(item);
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async setFeedItemAutoDownload(itemId: number, enabled: boolean): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'auto_download': enabled ? 1 : 0
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEED_ITEMS);
    predicates.equalTo('id', itemId);
    await store.update(bucket, predicates);
  }

  private parseItemWithMedia(resultSet: relationalStore.ResultSet): FeedItem {
    const item = this.parseItemResultSet(resultSet);

    // Parse joined FeedMedia if present
    const mediaIdIdx = resultSet.getColumnIndex('media_id');
    if (!resultSet.isColumnNull(mediaIdIdx)) {
      const media = new FeedMedia();
      media.id = resultSet.getLong(mediaIdIdx);
      media.duration = resultSet.getLong(resultSet.getColumnIndex('duration'));
      media.localFileUrl = this.getStringCol(resultSet, 'media_file_url');
      media.downloadUrl = this.getStringCol(resultSet, 'media_download_url');
      media.downloadDate = resultSet.getLong(resultSet.getColumnIndex('media_downloaded'));
      media.position = resultSet.getLong(resultSet.getColumnIndex('position'));
      media.size = resultSet.getLong(resultSet.getColumnIndex('filesize'));
      media.mimeType = this.getStringCol(resultSet, 'mime_type');
      media.lastPlayedTimeHistory = resultSet.getLong(resultSet.getColumnIndex('playback_completion_date'));
      media.playedDuration = resultSet.getLong(resultSet.getColumnIndex('played_duration'));
      media.hasEmbeddedPicture = resultSet.getLong(resultSet.getColumnIndex('has_embedded_picture')) === 1;
      media.lastPlayedTimeStatistics = resultSet.getLong(resultSet.getColumnIndex('last_played_time'));
      media.itemId = item.id;
      media.item = item;
      item.media = media;
    }

    return item;
  }

  private parseItemResultSet(resultSet: relationalStore.ResultSet): FeedItem {
    const item = new FeedItem();
    item.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    item.title = this.getStringCol(resultSet, 'title');
    item.pubDate = resultSet.getLong(resultSet.getColumnIndex('pubDate'));
    item.state = resultSet.getLong(resultSet.getColumnIndex('read'));
    item.link = this.getStringCol(resultSet, 'link');
    item.description = this.getStringCol(resultSet, 'description');
    item.paymentLink = this.getStringCol(resultSet, 'payment_link');
    item.feedId = resultSet.getLong(resultSet.getColumnIndex('feed'));
    item.hasChapters = resultSet.getLong(resultSet.getColumnIndex('has_simple_chapters')) === 1;
    item.itemIdentifier = this.getStringCol(resultSet, 'item_identifier');
    item.imageUrl = this.getStringCol(resultSet, 'image_url');
    item.autoDownloadEnabled = resultSet.getLong(resultSet.getColumnIndex('auto_download')) === 1;
    item.podcastIndexChapterUrl = this.getStringCol(resultSet, 'podcastindex_chapter_url');
    item.podcastIndexTranscriptType = this.getStringCol(resultSet, 'podcastindex_transcript_type');
    item.podcastIndexTranscriptUrl = this.getStringCol(resultSet, 'podcastindex_transcript_url');
    item.socialInteractUrl = this.getStringCol(resultSet, 'social_interact_url');
    return item;
  }

  private parseFeedFromJoin(resultSet: relationalStore.ResultSet, item: FeedItem): void {
    const titleIdx = resultSet.getColumnIndex('feed_title');
    if (titleIdx < 0) {
      return;
    }
    const feed = new Feed();
    feed.id = item.feedId;
    feed.feedTitle = this.getStringCol(resultSet, 'feed_title');
    feed.customTitle = this.getStringCol(resultSet, 'feed_custom_title');
    feed.imageUrl = this.getStringCol(resultSet, 'feed_image_url');
    feed.author = this.getStringCol(resultSet, 'feed_author');
    item.feed = feed;
  }

  private getStringCol(resultSet: relationalStore.ResultSet, colName: string): string {
    const idx = resultSet.getColumnIndex(colName);
    if (resultSet.isColumnNull(idx)) {
      return '';
    }
    return resultSet.getString(idx);
  }
}
