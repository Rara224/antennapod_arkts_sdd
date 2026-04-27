import { relationalStore } from '@kit.ArkData';
import { PodDatabase } from './PodDatabase';
import { FeedMedia } from '../models/FeedMedia';
import { TABLE_FEED_MEDIA } from '../common/Constants';

export class FeedMediaDao {
  private getStore(): relationalStore.RdbStore {
    return PodDatabase.getInstance().getStore();
  }

  async getFeedMedia(mediaId: number): Promise<FeedMedia | null> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_FEED_MEDIA + ' WHERE id = ?', [mediaId]
    );
    try {
      if (resultSet.goToFirstRow()) {
        return this.parseMediaResultSet(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getFeedMediaByItemId(itemId: number): Promise<FeedMedia | null> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_FEED_MEDIA + ' WHERE feeditem = ?', [itemId]
    );
    try {
      if (resultSet.goToFirstRow()) {
        return this.parseMediaResultSet(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  async getPlayedMedia(): Promise<FeedMedia[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_FEED_MEDIA + ' WHERE playback_completion_date > 0 ' +
      'ORDER BY playback_completion_date DESC'
    );
    try {
      const list: FeedMedia[] = [];
      while (resultSet.goToNextRow()) {
        list.push(this.parseMediaResultSet(resultSet));
      }
      return list;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Insert or update FeedMedia. Returns the media id.
   */
  async setFeedMedia(media: FeedMedia): Promise<number> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'duration': media.duration,
      'file_url': media.localFileUrl,
      'download_url': media.downloadUrl,
      'downloaded': media.downloadDate,
      'position': media.position,
      'filesize': media.size,
      'mime_type': media.mimeType,
      'playback_completion_date': media.lastPlayedTimeHistory,
      'feeditem': media.itemId,
      'played_duration': media.playedDuration,
      'has_embedded_picture': media.hasEmbeddedPicture ? 1 : -1,
      'last_played_time': media.lastPlayedTimeStatistics
    };

    if (media.id > 0) {
      const predicates = new relationalStore.RdbPredicates(TABLE_FEED_MEDIA);
      predicates.equalTo('id', media.id);
      await store.update(bucket, predicates);
      return media.id;
    }

    const rowId = await store.insert(TABLE_FEED_MEDIA, bucket);
    media.id = rowId;
    return rowId;
  }

  async setPosition(mediaId: number, position: number): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'position': position
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEED_MEDIA);
    predicates.equalTo('id', mediaId);
    await store.update(bucket, predicates);
  }

  async setLastPlayedTime(mediaId: number, time: number): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'last_played_time': time
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEED_MEDIA);
    predicates.equalTo('id', mediaId);
    await store.update(bucket, predicates);
  }

  async setDuration(mediaId: number, duration: number): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'duration': duration
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEED_MEDIA);
    predicates.equalTo('id', mediaId);
    await store.update(bucket, predicates);
  }

  async clearPlaybackHistory(): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'last_played_time': 0,
      'playback_completion_date': 0
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEED_MEDIA);
    predicates.greaterThan('last_played_time', 0)
      .or()
      .greaterThan('playback_completion_date', 0);
    await store.update(bucket, predicates);
  }

  async setPlaybackCompletionDate(mediaId: number, date: number): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'playback_completion_date': date
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEED_MEDIA);
    predicates.equalTo('id', mediaId);
    await store.update(bucket, predicates);
  }

  async getTotalPlayedDuration(): Promise<number> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT SUM(played_duration) AS total FROM ' + TABLE_FEED_MEDIA
    );
    try {
      if (resultSet.goToFirstRow()) {
        if (resultSet.isColumnNull(resultSet.getColumnIndex('total'))) {
          return 0;
        }
        return resultSet.getLong(resultSet.getColumnIndex('total'));
      }
      return 0;
    } finally {
      resultSet.close();
    }
  }

  async getCompletedEpisodeCount(): Promise<number> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT COUNT(*) AS cnt FROM ' + TABLE_FEED_MEDIA + ' WHERE playback_completion_date > 0'
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

  async getFeedPlayedDuration(feedId: number): Promise<number> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT SUM(m.played_duration) AS total FROM ' + TABLE_FEED_MEDIA +
      ' m INNER JOIN FeedItems i ON m.feeditem = i.id WHERE i.feed = ?', [feedId]
    );
    try {
      if (resultSet.goToFirstRow()) {
        if (resultSet.isColumnNull(resultSet.getColumnIndex('total'))) {
          return 0;
        }
        return resultSet.getLong(resultSet.getColumnIndex('total'));
      }
      return 0;
    } finally {
      resultSet.close();
    }
  }

  async getFeedStartedEpisodeCount(feedId: number): Promise<number> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT COUNT(*) AS cnt FROM ' + TABLE_FEED_MEDIA +
      ' m INNER JOIN FeedItems i ON m.feeditem = i.id WHERE i.feed = ? AND m.position > 0',
      [feedId]
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

  async getFeedStorageSize(feedId: number): Promise<number> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT SUM(m.filesize) AS total FROM ' + TABLE_FEED_MEDIA +
      ' m INNER JOIN FeedItems i ON m.feeditem = i.id WHERE i.feed = ? AND m.file_url IS NOT NULL AND m.file_url != ?',
      [feedId, '']
    );
    try {
      if (resultSet.goToFirstRow()) {
        if (resultSet.isColumnNull(resultSet.getColumnIndex('total'))) {
          return 0;
        }
        return resultSet.getLong(resultSet.getColumnIndex('total'));
      }
      return 0;
    } finally {
      resultSet.close();
    }
  }

  private parseMediaResultSet(resultSet: relationalStore.ResultSet): FeedMedia {
    const media = new FeedMedia();
    media.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    media.duration = resultSet.getLong(resultSet.getColumnIndex('duration'));
    media.localFileUrl = this.getStringCol(resultSet, 'file_url');
    media.downloadUrl = this.getStringCol(resultSet, 'download_url');
    media.downloadDate = resultSet.getLong(resultSet.getColumnIndex('downloaded'));
    media.position = resultSet.getLong(resultSet.getColumnIndex('position'));
    media.size = resultSet.getLong(resultSet.getColumnIndex('filesize'));
    media.mimeType = this.getStringCol(resultSet, 'mime_type');
    media.lastPlayedTimeHistory = resultSet.getLong(resultSet.getColumnIndex('playback_completion_date'));
    media.itemId = resultSet.getLong(resultSet.getColumnIndex('feeditem'));
    media.playedDuration = resultSet.getLong(resultSet.getColumnIndex('played_duration'));
    media.hasEmbeddedPicture = resultSet.getLong(resultSet.getColumnIndex('has_embedded_picture')) === 1;
    media.lastPlayedTimeStatistics = resultSet.getLong(resultSet.getColumnIndex('last_played_time'));
    return media;
  }

  private getStringCol(resultSet: relationalStore.ResultSet, colName: string): string {
    const idx = resultSet.getColumnIndex(colName);
    if (resultSet.isColumnNull(idx)) {
      return '';
    }
    return resultSet.getString(idx);
  }
}
