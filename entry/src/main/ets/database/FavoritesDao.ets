import { relationalStore } from '@kit.ArkData';
import { PodDatabase } from './PodDatabase';
import { FeedItem } from '../models/FeedItem';
import { FeedMedia } from '../models/FeedMedia';
import {
  TABLE_FAVORITES,
  TABLE_FEED_ITEMS,
  TABLE_FEED_MEDIA
} from '../common/Constants';

export class FavoritesDao {
  private getStore(): relationalStore.RdbStore {
    return PodDatabase.getInstance().getStore();
  }

  async getFavorites(): Promise<FeedItem[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT fi.*, fm.id AS media_id, fm.duration, fm.file_url AS media_file_url, ' +
      'fm.download_url AS media_download_url, fm.downloaded AS media_downloaded, ' +
      'fm.position, fm.filesize, fm.mime_type, fm.playback_completion_date, ' +
      'fm.played_duration, fm.has_embedded_picture, fm.last_played_time ' +
      'FROM ' + TABLE_FAVORITES + ' f ' +
      'INNER JOIN ' + TABLE_FEED_ITEMS + ' fi ON fi.id = f.feeditem ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'ORDER BY f.id DESC'
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

  async addToFavorites(itemId: number, feedId: number): Promise<void> {
    const alreadyFav = await this.isFavorite(itemId);
    if (alreadyFav) {
      return;
    }
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'feeditem': itemId,
      'feed': feedId
    };
    await store.insert(TABLE_FAVORITES, bucket);
  }

  async removeFromFavorites(itemId: number): Promise<void> {
    const store = this.getStore();
    await store.executeSql(
      'DELETE FROM ' + TABLE_FAVORITES + ' WHERE feeditem = ?', [itemId]
    );
  }

  async isFavorite(itemId: number): Promise<boolean> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT id FROM ' + TABLE_FAVORITES + ' WHERE feeditem = ?', [itemId]
    );
    try {
      return resultSet.goToFirstRow();
    } finally {
      resultSet.close();
    }
  }

  private parseItemWithMedia(resultSet: relationalStore.ResultSet): FeedItem {
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

  private getStringCol(resultSet: relationalStore.ResultSet, colName: string): string {
    const idx = resultSet.getColumnIndex(colName);
    if (resultSet.isColumnNull(idx)) {
      return '';
    }
    return resultSet.getString(idx);
  }
}
