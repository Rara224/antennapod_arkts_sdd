import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PodDatabase } from './PodDatabase';
import { Feed } from '../models/Feed';
import { FeedPreferences } from '../models/FeedPreferences';
import { JsonUtils } from '../helpers/JsonUtils';
import {
  TABLE_FEEDS,
  TABLE_FEED_ITEMS,
  TABLE_FEED_MEDIA,
  TABLE_SIMPLE_CHAPTERS,
  TABLE_QUEUE,
  TABLE_FAVORITES
} from '../common/Constants';

const DOMAIN: number = 0x0000;
const TAG: string = 'FeedDao';

export class FeedDao {
  private getStore(): relationalStore.RdbStore {
    return PodDatabase.getInstance().getStore();
  }

  async getAllFeeds(): Promise<Feed[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_FEEDS + ' ORDER BY title COLLATE NOCASE ASC'
    );
    try {
      const feeds: Feed[] = [];
      while (resultSet.goToNextRow()) {
        feeds.push(this.parseFeedResultSet(resultSet));
      }
      return feeds;
    } finally {
      resultSet.close();
    }
  }

  async getAllFeedsWithStats(): Promise<Feed[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT f.*, ' +
      'COUNT(fi.id) AS episode_count, ' +
      'COALESCE(SUM(fm.duration), 0) AS total_duration ' +
      'FROM ' + TABLE_FEEDS + ' f ' +
      'LEFT JOIN ' + TABLE_FEED_ITEMS + ' fi ON fi.feed = f.id ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'GROUP BY f.id ' +
      'ORDER BY f.title COLLATE NOCASE ASC'
    );
    try {
      const feeds: Feed[] = [];
      while (resultSet.goToNextRow()) {
        const feed = this.parseFeedResultSet(resultSet);
        feed.episodeCount = resultSet.getLong(resultSet.getColumnIndex('episode_count'));
        feed.totalDuration = resultSet.getLong(resultSet.getColumnIndex('total_duration'));
        feeds.push(feed);
      }
      return feeds;
    } finally {
      resultSet.close();
    }
  }

  async getFeed(feedId: number): Promise<Feed | null> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_FEEDS + ' WHERE id = ?', [feedId]
    );
    try {
      if (resultSet.goToFirstRow()) {
        return this.parseFeedResultSet(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getFeedByUrl(downloadUrl: string): Promise<Feed | null> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_FEEDS + ' WHERE download_url = ?', [downloadUrl]
    );
    try {
      if (resultSet.goToFirstRow()) {
        return this.parseFeedResultSet(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getFeedByIdentifier(identifier: string): Promise<Feed | null> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_FEEDS + ' WHERE feed_identifier = ?', [identifier]
    );
    try {
      if (resultSet.goToFirstRow()) {
        return this.parseFeedResultSet(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Insert or update a Feed. Uses two-step SELECT→INSERT/UPDATE to preserve id.
   * Returns the feed id.
   */
  async setFeed(feed: Feed): Promise<number> {
    const store = this.getStore();
    const bucket = this.buildFeedBucket(feed);

    // Check if feed with same download_url already exists
    const existingId = await this.findFeedIdByUrl(feed.downloadUrl);
    if (existingId > 0) {
      const predicates = new relationalStore.RdbPredicates(TABLE_FEEDS);
      predicates.equalTo('id', existingId);
      await store.update(bucket, predicates);
      feed.id = existingId;
      return existingId;
    }

    const rowId = await store.insert(TABLE_FEEDS, bucket);
    feed.id = rowId;
    return rowId;
  }

  async setFeedPreferences(prefs: FeedPreferences, feedId: number): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'auto_download': prefs.autoDownload,
      'username': prefs.username,
      'password': prefs.password,
      'include_filter': prefs.includeFilter,
      'exclude_filter': prefs.excludeFilter,
      'minimal_duration_filter': prefs.minimalDurationFilter,
      'keep_updated': prefs.keepUpdated ? 1 : 0,
      'auto_delete_action': prefs.autoDeleteAction,
      'feed_volume_adaption': prefs.volumeAdaptionSetting,
      'tags': JsonUtils.setToJson(prefs.tags),
      'feed_skip_intro': prefs.feedSkipIntro,
      'feed_skip_ending': prefs.feedSkipEnding,
      'episode_notification': prefs.episodeNotification ? 1 : 0,
      'new_episodes_action': prefs.newEpisodesAction,
      'feed_playback_speed': prefs.feedPlaybackSpeed,
      'feed_skip_silence': prefs.feedSkipSilence
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEEDS);
    predicates.equalTo('id', feedId);
    await store.update(bucket, predicates);
  }

  async setFeedItemFilter(feedId: number, includeFilter: string, excludeFilter: string): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'include_filter': includeFilter,
      'exclude_filter': excludeFilter
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEEDS);
    predicates.equalTo('id', feedId);
    await store.update(bucket, predicates);
  }

  async setFeedItemSortOrder(feedId: number, sortOrder: string): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'sort_order': sortOrder
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEEDS);
    predicates.equalTo('id', feedId);
    await store.update(bucket, predicates);
  }

  /**
   * Remove a feed and all its associated data (cascade delete in transaction).
   * Order: Chapters → Queue/Favorites (by item) → FeedMedia → FeedItems → Feed
   */
  async removeFeed(feed: Feed): Promise<void> {
    const store = this.getStore();
    await store.beginTransaction();
    try {
      const feedId = feed.id;

      // Get all item ids for this feed
      const itemIds = await this.getFeedItemIds(feedId);

      if (itemIds.length > 0) {
        // Delete chapters for all items
        for (let i = 0; i < itemIds.length; i++) {
          await store.executeSql(
            'DELETE FROM ' + TABLE_SIMPLE_CHAPTERS + ' WHERE feeditem = ?', [itemIds[i]]
          );
        }

        // Delete from queue and favorites
        for (let i = 0; i < itemIds.length; i++) {
          await store.executeSql(
            'DELETE FROM ' + TABLE_QUEUE + ' WHERE feeditem = ?', [itemIds[i]]
          );
          await store.executeSql(
            'DELETE FROM ' + TABLE_FAVORITES + ' WHERE feeditem = ?', [itemIds[i]]
          );
        }

        // Delete feed media
        for (let i = 0; i < itemIds.length; i++) {
          await store.executeSql(
            'DELETE FROM ' + TABLE_FEED_MEDIA + ' WHERE feeditem = ?', [itemIds[i]]
          );
        }
      }

      // Delete feed items
      await store.executeSql(
        'DELETE FROM ' + TABLE_FEED_ITEMS + ' WHERE feed = ?', [feedId]
      );

      // Delete feed
      await store.executeSql(
        'DELETE FROM ' + TABLE_FEEDS + ' WHERE id = ?', [feedId]
      );

      await store.commit();
      hilog.info(DOMAIN, TAG, 'Removed feed id=%{public}d', feedId);
    } catch (e) {
      await store.rollBack();
      hilog.error(DOMAIN, TAG, 'removeFeed failed: %{public}s', JSON.stringify(e));
      if (e instanceof Error) {
        throw e;
      }
      throw new Error('removeFeed failed');
    }
  }

  async setFeedState(feedId: number, state: number): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'state': state
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEEDS);
    predicates.equalTo('id', feedId);
    await store.update(bucket, predicates);
  }

  private async findFeedIdByUrl(downloadUrl: string): Promise<number> {
    if (downloadUrl.length === 0) {
      return 0;
    }
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT id FROM ' + TABLE_FEEDS + ' WHERE download_url = ?', [downloadUrl]
    );
    try {
      if (resultSet.goToFirstRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('id'));
      }
      return 0;
    } finally {
      resultSet.close();
    }
  }

  private async getFeedItemIds(feedId: number): Promise<number[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT id FROM ' + TABLE_FEED_ITEMS + ' WHERE feed = ?', [feedId]
    );
    try {
      const ids: number[] = [];
      while (resultSet.goToNextRow()) {
        ids.push(resultSet.getLong(resultSet.getColumnIndex('id')));
      }
      return ids;
    } finally {
      resultSet.close();
    }
  }

  private buildFeedBucket(feed: Feed): relationalStore.ValuesBucket {
    const prefs = feed.preferences;
    const bucket: relationalStore.ValuesBucket = {
      'title': feed.feedTitle,
      'custom_title': feed.customTitle,
      'file_url': feed.localFileUrl,
      'download_url': feed.downloadUrl,
      'link': feed.link,
      'description': feed.description,
      'language': feed.language,
      'author': feed.author,
      'image_url': feed.imageUrl,
      'type': feed.type,
      'feed_identifier': feed.feedIdentifier,
      'last_update': feed.lastModified,
      'is_paged': feed.paged ? 1 : 0,
      'next_page_link': feed.nextPageLink,
      'last_update_failed': feed.lastUpdateFailed ? 1 : 0,
      'state': feed.state,
      'sort_order': feed.sortOrder,
      'auto_download': prefs.autoDownload,
      'username': prefs.username,
      'password': prefs.password,
      'include_filter': prefs.includeFilter,
      'exclude_filter': prefs.excludeFilter,
      'minimal_duration_filter': prefs.minimalDurationFilter,
      'keep_updated': prefs.keepUpdated ? 1 : 0,
      'auto_delete_action': prefs.autoDeleteAction,
      'feed_volume_adaption': prefs.volumeAdaptionSetting,
      'tags': JsonUtils.setToJson(prefs.tags),
      'feed_skip_intro': prefs.feedSkipIntro,
      'feed_skip_ending': prefs.feedSkipEnding,
      'episode_notification': prefs.episodeNotification ? 1 : 0,
      'new_episodes_action': prefs.newEpisodesAction,
      'feed_playback_speed': prefs.feedPlaybackSpeed,
      'feed_skip_silence': prefs.feedSkipSilence
    };
    return bucket;
  }

  private parseFeedResultSet(resultSet: relationalStore.ResultSet): Feed {
    const feed = new Feed();
    feed.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    feed.feedTitle = this.getStringCol(resultSet, 'title');
    feed.customTitle = this.getStringCol(resultSet, 'custom_title');
    feed.localFileUrl = this.getStringCol(resultSet, 'file_url');
    feed.downloadUrl = this.getStringCol(resultSet, 'download_url');
    feed.link = this.getStringCol(resultSet, 'link');
    feed.description = this.getStringCol(resultSet, 'description');
    feed.language = this.getStringCol(resultSet, 'language');
    feed.author = this.getStringCol(resultSet, 'author');
    feed.imageUrl = this.getStringCol(resultSet, 'image_url');
    feed.type = this.getStringCol(resultSet, 'type');
    feed.feedIdentifier = this.getStringCol(resultSet, 'feed_identifier');
    feed.lastModified = this.getStringCol(resultSet, 'last_update');
    feed.paged = resultSet.getLong(resultSet.getColumnIndex('is_paged')) === 1;
    feed.nextPageLink = this.getStringCol(resultSet, 'next_page_link');
    feed.lastUpdateFailed = resultSet.getLong(resultSet.getColumnIndex('last_update_failed')) === 1;
    feed.state = resultSet.getLong(resultSet.getColumnIndex('state'));
    feed.sortOrder = this.getStringCol(resultSet, 'sort_order');

    // Parse FeedPreferences from same row
    const prefs = new FeedPreferences();
    prefs.autoDownload = resultSet.getLong(resultSet.getColumnIndex('auto_download'));
    prefs.username = this.getStringCol(resultSet, 'username');
    prefs.password = this.getStringCol(resultSet, 'password');
    prefs.includeFilter = this.getStringCol(resultSet, 'include_filter');
    prefs.excludeFilter = this.getStringCol(resultSet, 'exclude_filter');
    prefs.minimalDurationFilter = resultSet.getLong(resultSet.getColumnIndex('minimal_duration_filter'));
    prefs.keepUpdated = resultSet.getLong(resultSet.getColumnIndex('keep_updated')) === 1;
    prefs.autoDeleteAction = resultSet.getLong(resultSet.getColumnIndex('auto_delete_action'));
    prefs.volumeAdaptionSetting = resultSet.getLong(resultSet.getColumnIndex('feed_volume_adaption'));
    prefs.tags = JsonUtils.jsonToSet(this.getStringCol(resultSet, 'tags'));
    prefs.feedSkipIntro = resultSet.getLong(resultSet.getColumnIndex('feed_skip_intro'));
    prefs.feedSkipEnding = resultSet.getLong(resultSet.getColumnIndex('feed_skip_ending'));
    prefs.episodeNotification = resultSet.getLong(resultSet.getColumnIndex('episode_notification')) === 1;
    prefs.newEpisodesAction = resultSet.getLong(resultSet.getColumnIndex('new_episodes_action'));
    prefs.feedPlaybackSpeed = resultSet.getDouble(resultSet.getColumnIndex('feed_playback_speed'));
    prefs.feedSkipSilence = resultSet.getLong(resultSet.getColumnIndex('feed_skip_silence'));
    feed.preferences = prefs;

    return feed;
  }

  private getStringCol(resultSet: relationalStore.ResultSet, colName: string): string {
    const idx = resultSet.getColumnIndex(colName);
    if (resultSet.isColumnNull(idx)) {
      return '';
    }
    return resultSet.getString(idx);
  }
}
