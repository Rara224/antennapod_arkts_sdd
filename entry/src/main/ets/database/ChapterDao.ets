import { relationalStore } from '@kit.ArkData';
import { PodDatabase } from './PodDatabase';
import { Chapter } from '../models/Chapter';
import { TABLE_SIMPLE_CHAPTERS } from '../common/Constants';

export class ChapterDao {
  private getStore(): relationalStore.RdbStore {
    return PodDatabase.getInstance().getStore();
  }

  async getChapters(itemId: number): Promise<Chapter[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_SIMPLE_CHAPTERS + ' WHERE feeditem = ? ORDER BY start ASC',
      [itemId]
    );
    try {
      const chapters: Chapter[] = [];
      while (resultSet.goToNextRow()) {
        chapters.push(this.parseChapterResultSet(resultSet));
      }
      return chapters;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Replace all chapters for a feed item (delete + insert in transaction).
   */
  async setChapters(itemId: number, chapters: Chapter[]): Promise<void> {
    const store = this.getStore();
    await store.beginTransaction();
    try {
      // Delete existing chapters
      await store.executeSql(
        'DELETE FROM ' + TABLE_SIMPLE_CHAPTERS + ' WHERE feeditem = ?', [itemId]
      );

      // Insert new chapters
      for (let i = 0; i < chapters.length; i++) {
        const ch = chapters[i];
        const bucket: relationalStore.ValuesBucket = {
          'title': ch.title,
          'start': ch.start,
          'feeditem': itemId,
          'link': ch.link,
          'image_url': ch.imageUrl
        };
        await store.insert(TABLE_SIMPLE_CHAPTERS, bucket);
      }

      await store.commit();
    } catch (e) {
      await store.rollBack();
      if (e instanceof Error) {
        throw e;
      }
      throw new Error('setChapters failed');
    }
  }

  async deleteChapters(itemId: number): Promise<void> {
    const store = this.getStore();
    await store.executeSql(
      'DELETE FROM ' + TABLE_SIMPLE_CHAPTERS + ' WHERE feeditem = ?', [itemId]
    );
  }

  private parseChapterResultSet(resultSet: relationalStore.ResultSet): Chapter {
    const ch = new Chapter();
    ch.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    ch.title = this.getStringCol(resultSet, 'title');
    ch.start = resultSet.getLong(resultSet.getColumnIndex('start'));
    ch.link = this.getStringCol(resultSet, 'link');
    ch.imageUrl = this.getStringCol(resultSet, 'image_url');
    return ch;
  }

  private getStringCol(resultSet: relationalStore.ResultSet, colName: string): string {
    const idx = resultSet.getColumnIndex(colName);
    if (resultSet.isColumnNull(idx)) {
      return '';
    }
    return resultSet.getString(idx);
  }
}
