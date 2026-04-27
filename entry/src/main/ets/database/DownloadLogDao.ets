import { relationalStore } from '@kit.ArkData';
import { PodDatabase } from './PodDatabase';
import { DownloadResult } from '../models/DownloadResult';
import { TABLE_DOWNLOAD_LOG } from '../common/Constants';

export class DownloadLogDao {
  private getStore(): relationalStore.RdbStore {
    return PodDatabase.getInstance().getStore();
  }

  async getDownloadLog(): Promise<DownloadResult[]> {
    const store = this.getStore();
    const resultSet = await store.querySql(
      'SELECT * FROM ' + TABLE_DOWNLOAD_LOG + ' ORDER BY completion_date DESC'
    );
    try {
      const logs: DownloadResult[] = [];
      while (resultSet.goToNextRow()) {
        logs.push(this.parseResultSet(resultSet));
      }
      return logs;
    } finally {
      resultSet.close();
    }
  }

  async addDownloadLog(result: DownloadResult): Promise<void> {
    const store = this.getStore();
    const bucket: relationalStore.ValuesBucket = {
      'feedfile': result.feedfileId,
      'feedfile_type': result.feedfileType,
      'reason': result.reason,
      'successful': result.successful ? 1 : 0,
      'completion_date': result.completionDate,
      'reason_detailed': result.reasonDetailed,
      'title': result.title
    };
    await store.insert(TABLE_DOWNLOAD_LOG, bucket);
  }

  async clearDownloadLog(): Promise<void> {
    const store = this.getStore();
    await store.executeSql('DELETE FROM ' + TABLE_DOWNLOAD_LOG);
  }

  private parseResultSet(resultSet: relationalStore.ResultSet): DownloadResult {
    const result = new DownloadResult();
    result.id = resultSet.getLong(resultSet.getColumnIndex('id'));
    result.feedfileId = resultSet.getLong(resultSet.getColumnIndex('feedfile'));
    result.feedfileType = resultSet.getLong(resultSet.getColumnIndex('feedfile_type'));
    result.reason = resultSet.getLong(resultSet.getColumnIndex('reason'));
    result.successful = resultSet.getLong(resultSet.getColumnIndex('successful')) === 1;
    result.completionDate = resultSet.getLong(resultSet.getColumnIndex('completion_date'));
    result.reasonDetailed = this.getStringCol(resultSet, 'reason_detailed');
    result.title = this.getStringCol(resultSet, 'title');
    return result;
  }

  private getStringCol(resultSet: relationalStore.ResultSet, colName: string): string {
    const idx = resultSet.getColumnIndex(colName);
    if (resultSet.isColumnNull(idx)) {
      return '';
    }
    return resultSet.getString(idx);
  }
}
