import { relationalStore } from '@kit.ArkData';
import { PodDatabase } from '../database/PodDatabase';
import { FeedMediaDao } from '../database/FeedMediaDao';
import { FeedItemDao } from '../database/FeedItemDao';
import { TABLE_FEEDS, TABLE_FEED_ITEMS, TABLE_FEED_MEDIA } from '../common/Constants';
import { ChartSegment } from '../components/statistics/HalfCircleChart';

export class FeedStatistics {
  feedId: number = 0;
  feedTitle: string = '';
  imageUrl: string = '';
  totalPlayedDuration: number = 0;
  playedCount: number = 0;
  totalCount: number = 0;
}

export class YearStatistics {
  year: number = 0;
  totalDuration: number = 0;
  episodeCount: number = 0;
}

export class DownloadStatistics {
  feedId: number = 0;
  feedTitle: string = '';
  imageUrl: string = '';
  downloadedCount: number = 0;
  totalSize: number = 0;
}

// Colors for chart segments
const CHART_COLORS: string[] = [
  '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF',
  '#FF9F40', '#C9CBCF', '#7BC225', '#E74C3C', '#3498DB'
];

export class StatisticsViewModel {
  private feedMediaDao: FeedMediaDao = new FeedMediaDao();
  private feedItemDao: FeedItemDao = new FeedItemDao();

  totalPlayedTime: number = 0;
  totalPlayedEpisodes: number = 0;
  totalCompletedEpisodes: number = 0;
  feedStatsList: FeedStatistics[] = [];
  chartSegments: ChartSegment[] = [];
  yearStatsList: YearStatistics[] = [];
  downloadStatsList: DownloadStatistics[] = [];

  async resetStatistics(): Promise<void> {
    const store = PodDatabase.getInstance().getStore();
    const bucket: relationalStore.ValuesBucket = {
      'played_duration': 0
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_FEED_MEDIA);
    predicates.greaterThan('played_duration', 0);
    await store.update(bucket, predicates);
    this.totalPlayedTime = 0;
    this.totalPlayedEpisodes = 0;
    this.feedStatsList = [];
    this.chartSegments = [];
  }

  async loadStatistics(): Promise<void> {
    this.totalPlayedTime = await this.feedMediaDao.getTotalPlayedDuration();
    this.totalPlayedEpisodes = await this.feedItemDao.getPlayedEpisodeCount();
    this.totalCompletedEpisodes = await this.feedMediaDao.getCompletedEpisodeCount();
    this.feedStatsList = await this.loadFeedStatistics();
    this.chartSegments = this.buildChartSegments();
  }

  async loadYearStatistics(): Promise<void> {
    const store = PodDatabase.getInstance().getStore();
    // Use COALESCE to fall back to playback_completion_date when last_played_time is not set
    const resultSet = await store.querySql(
      'SELECT CAST(strftime(\'%Y\', ' +
      'CASE WHEN fm.last_played_time > 0 THEN fm.last_played_time ' +
      'ELSE fm.playback_completion_date END / 1000, \'unixepoch\') AS INTEGER) AS year, ' +
      'COALESCE(SUM(fm.played_duration), 0) AS total_duration, ' +
      'COUNT(fm.id) AS episode_count ' +
      'FROM ' + TABLE_FEED_MEDIA + ' fm ' +
      'WHERE (fm.last_played_time > 0 OR fm.playback_completion_date > 0 OR fm.position > 0) ' +
      'GROUP BY year ' +
      'ORDER BY year DESC'
    );
    try {
      this.yearStatsList = [];
      while (resultSet.goToNextRow()) {
        const stat = new YearStatistics();
        stat.year = resultSet.getLong(resultSet.getColumnIndex('year'));
        stat.totalDuration = resultSet.getLong(resultSet.getColumnIndex('total_duration'));
        stat.episodeCount = resultSet.getLong(resultSet.getColumnIndex('episode_count'));
        if (stat.year > 2000) {
          this.yearStatsList.push(stat);
        }
      }
    } finally {
      resultSet.close();
    }
  }

  async loadDownloadStatistics(): Promise<void> {
    const store = PodDatabase.getInstance().getStore();
    const resultSet = await store.querySql(
      'SELECT f.id AS feed_id, f.title AS feed_title, f.image_url AS feed_image, ' +
      'COUNT(fm.id) AS downloaded_count, ' +
      'COALESCE(SUM(fm.filesize), 0) AS total_size ' +
      'FROM ' + TABLE_FEEDS + ' f ' +
      'INNER JOIN ' + TABLE_FEED_ITEMS + ' fi ON fi.feed = f.id ' +
      'INNER JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'WHERE fm.file_url IS NOT NULL AND fm.file_url != ? ' +
      'GROUP BY f.id ' +
      'ORDER BY total_size DESC', ['']
    );
    try {
      this.downloadStatsList = [];
      while (resultSet.goToNextRow()) {
        const stat = new DownloadStatistics();
        stat.feedId = resultSet.getLong(resultSet.getColumnIndex('feed_id'));
        stat.feedTitle = this.getStringCol(resultSet, 'feed_title');
        stat.imageUrl = this.getStringCol(resultSet, 'feed_image');
        stat.downloadedCount = resultSet.getLong(resultSet.getColumnIndex('downloaded_count'));
        stat.totalSize = resultSet.getLong(resultSet.getColumnIndex('total_size'));
        this.downloadStatsList.push(stat);
      }
    } finally {
      resultSet.close();
    }
  }

  private buildChartSegments(): ChartSegment[] {
    if (this.totalPlayedTime <= 0 || this.feedStatsList.length === 0) {
      return [];
    }
    const segments: ChartSegment[] = [];
    for (let i = 0; i < this.feedStatsList.length && i < 10; i++) {
      const stat = this.feedStatsList[i];
      if (stat.totalPlayedDuration > 0) {
        const segment = new ChartSegment();
        segment.color = CHART_COLORS[i % CHART_COLORS.length];
        segment.percentage = Math.round(stat.totalPlayedDuration * 100 / this.totalPlayedTime);
        segment.label = stat.feedTitle;
        segments.push(segment);
      }
    }
    return segments;
  }

  private async loadFeedStatistics(): Promise<FeedStatistics[]> {
    const store = PodDatabase.getInstance().getStore();
    const resultSet = await store.querySql(
      'SELECT f.id AS feed_id, f.title AS feed_title, f.image_url AS feed_image, ' +
      'COALESCE(SUM(fm.played_duration), 0) AS total_played, ' +
      'COUNT(CASE WHEN fi.read = 1 THEN 1 ELSE NULL END) AS played_count, ' +
      'COUNT(fi.id) AS total_count ' +
      'FROM ' + TABLE_FEEDS + ' f ' +
      'LEFT JOIN ' + TABLE_FEED_ITEMS + ' fi ON fi.feed = f.id ' +
      'LEFT JOIN ' + TABLE_FEED_MEDIA + ' fm ON fm.feeditem = fi.id ' +
      'GROUP BY f.id ' +
      'ORDER BY total_played DESC'
    );
    try {
      const list: FeedStatistics[] = [];
      while (resultSet.goToNextRow()) {
        const stat = new FeedStatistics();
        stat.feedId = resultSet.getLong(resultSet.getColumnIndex('feed_id'));
        stat.feedTitle = this.getStringCol(resultSet, 'feed_title');
        stat.imageUrl = this.getStringCol(resultSet, 'feed_image');
        stat.totalPlayedDuration = resultSet.getLong(resultSet.getColumnIndex('total_played'));
        stat.playedCount = resultSet.getLong(resultSet.getColumnIndex('played_count'));
        stat.totalCount = resultSet.getLong(resultSet.getColumnIndex('total_count'));
        list.push(stat);
      }
      return list;
    } finally {
      resultSet.close();
    }
  }

  formatDuration(ms: number): string {
    if (ms <= 0) {
      return '0 hours';
    }
    const hours = ms / 3600000;
    if (hours < 0.1) {
      return '0 hours';
    }
    if (hours >= 10) {
      return Math.round(hours).toString() + ' hours';
    }
    return hours.toFixed(1) + ' hours';
  }

  formatSize(bytes: number): string {
    if (bytes <= 0) {
      return '0 B';
    }
    if (bytes < 1024) {
      return bytes.toString() + ' B';
    }
    if (bytes < 1024 * 1024) {
      return (Math.round(bytes * 10 / 1024) / 10).toString() + ' KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return (Math.round(bytes * 10 / (1024 * 1024)) / 10).toString() + ' MB';
    }
    return (Math.round(bytes * 10 / (1024 * 1024 * 1024)) / 10).toString() + ' GB';
  }

  private getStringCol(resultSet: relationalStore.ResultSet, colName: string): string {
    const idx = resultSet.getColumnIndex(colName);
    if (resultSet.isColumnNull(idx)) {
      return '';
    }
    return resultSet.getString(idx);
  }
}
