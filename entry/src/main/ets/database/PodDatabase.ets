import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DB_NAME, DB_VERSION } from '../common/Constants';

const DOMAIN: number = 0x0000;
const TAG: string = 'PodDatabase';

/**
 * Singleton database manager. Must call init(context) before any DAO operations.
 */
export class PodDatabase {
  private static instance: PodDatabase | undefined = undefined;
  private rdbStore: relationalStore.RdbStore | undefined = undefined;

  static getInstance(): PodDatabase {
    if (PodDatabase.instance === undefined) {
      PodDatabase.instance = new PodDatabase();
    }
    return PodDatabase.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.rdbStore !== undefined) {
      return;
    }
    hilog.info(DOMAIN, TAG, 'Initializing PodDatabase...');
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.rdbStore = await relationalStore.getRdbStore(context, config);
    await this.createTables();
    hilog.info(DOMAIN, TAG, 'PodDatabase initialized.');
  }

  getStore(): relationalStore.RdbStore {
    if (this.rdbStore === undefined) {
      throw new Error('PodDatabase not initialized. Call init() first.');
    }
    return this.rdbStore;
  }

  private async createTables(): Promise<void> {
    const store = this.getStore();

    // Table 1: Feeds (36 columns)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS Feeds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      custom_title TEXT,
      file_url TEXT,
      download_url TEXT,
      downloaded INTEGER DEFAULT 0,
      link TEXT,
      description TEXT,
      payment_link TEXT,
      last_update TEXT,
      language TEXT,
      author TEXT,
      image_url TEXT,
      type TEXT,
      feed_identifier TEXT,
      auto_download INTEGER DEFAULT 1,
      username TEXT,
      password TEXT,
      include_filter TEXT DEFAULT '',
      exclude_filter TEXT DEFAULT '',
      minimal_duration_filter INTEGER DEFAULT -1,
      keep_updated INTEGER DEFAULT 1,
      is_paged INTEGER DEFAULT 0,
      next_page_link TEXT,
      hide TEXT,
      sort_order TEXT,
      last_update_failed INTEGER DEFAULT 0,
      auto_delete_action INTEGER DEFAULT 0,
      feed_volume_adaption INTEGER DEFAULT 0,
      tags TEXT,
      feed_skip_intro INTEGER DEFAULT 0,
      feed_skip_ending INTEGER DEFAULT 0,
      episode_notification INTEGER DEFAULT 0,
      state INTEGER DEFAULT 0,
      new_episodes_action INTEGER DEFAULT 0,
      feed_playback_speed REAL DEFAULT -1.0,
      feed_skip_silence INTEGER DEFAULT 1
    )`);

    // Table 2: FeedItems (17 columns)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS FeedItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      pubDate INTEGER,
      read INTEGER DEFAULT -1,
      link TEXT,
      description TEXT,
      payment_link TEXT,
      media INTEGER,
      feed INTEGER,
      has_simple_chapters INTEGER DEFAULT 0,
      item_identifier TEXT,
      image_url TEXT,
      auto_download INTEGER DEFAULT 1,
      podcastindex_chapter_url TEXT,
      podcastindex_transcript_type TEXT,
      podcastindex_transcript_url TEXT,
      social_interact_url TEXT
    )`);

    await store.executeSql('CREATE INDEX IF NOT EXISTS FeedItems_feed ON FeedItems (feed)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS FeedItems_pubDate ON FeedItems (pubDate)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS FeedItems_read ON FeedItems (read)');

    // Table 3: FeedMedia (13 columns)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS FeedMedia (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      duration INTEGER DEFAULT 0,
      file_url TEXT,
      download_url TEXT,
      downloaded INTEGER DEFAULT 0,
      position INTEGER DEFAULT 0,
      filesize INTEGER DEFAULT 0,
      mime_type TEXT,
      playback_completion_date INTEGER DEFAULT 0,
      feeditem INTEGER,
      played_duration INTEGER DEFAULT 0,
      has_embedded_picture INTEGER DEFAULT -1,
      last_played_time INTEGER DEFAULT 0
    )`);

    await store.executeSql('CREATE INDEX IF NOT EXISTS FeedMedia_feeditem ON FeedMedia (feeditem)');

    // Table 4: SimpleChapters (6 columns)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS SimpleChapters (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      start INTEGER,
      feeditem INTEGER,
      link TEXT,
      image_url TEXT
    )`);

    await store.executeSql('CREATE INDEX IF NOT EXISTS SimpleChapters_feeditem ON SimpleChapters (feeditem)');

    // Table 5: DownloadLog (8 columns)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS DownloadLog (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      feedfile INTEGER,
      feedfile_type INTEGER,
      reason INTEGER,
      successful INTEGER,
      completion_date INTEGER,
      reason_detailed TEXT,
      title TEXT
    )`);

    // Table 6: Queue (3 columns)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS Queue (
      id INTEGER PRIMARY KEY,
      feeditem INTEGER,
      feed INTEGER
    )`);

    await store.executeSql('CREATE INDEX IF NOT EXISTS Queue_feeditem ON Queue (feeditem)');

    // Table 7: Favorites (3 columns)
    await store.executeSql(`CREATE TABLE IF NOT EXISTS Favorites (
      id INTEGER PRIMARY KEY,
      feeditem INTEGER,
      feed INTEGER
    )`);

    hilog.info(DOMAIN, TAG, 'All tables created.');
  }
}
