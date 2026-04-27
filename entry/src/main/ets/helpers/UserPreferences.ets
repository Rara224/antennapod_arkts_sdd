import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  ENQUEUE_AT_BACK,
  SORT_DATE_NEW_OLD,
  THEME_SYSTEM
} from '../common/Constants';

const DOMAIN: number = 0x0000;
const TAG: string = 'UserPreferences';
const PREFS_NAME: string = 'user_prefs';

// Preference keys
const KEY_THEME: string = 'prefTheme';
const KEY_HIDDEN_DRAWER_ITEMS: string = 'prefHiddenDrawerItems';
const KEY_DRAWER_FEED_ORDER: string = 'prefDrawerFeedOrder';
const KEY_DRAWER_FEED_COUNTER: string = 'prefDrawerFeedCounter';
const KEY_EXPAND_NOTIFY: string = 'prefExpandNotify';
const KEY_PERSISTENT_NOTIFICATION: string = 'prefPersistNotify';
const KEY_SHOW_DOWNLOAD_REPORT: string = 'prefShowDownloadReport';
const KEY_ENQUEUE_LOCATION: string = 'prefEnqueueLocation';
const KEY_ENQUEUE_DOWNLOADED: string = 'prefEnqueueDownloaded';
const KEY_UPDATE_INTERVAL: string = 'prefAutoUpdateIntervall';
const KEY_AUTO_UPDATE_DISABLED: string = 'prefAutoUpdateDisabled';
const KEY_MOBILE_UPDATE: string = 'prefMobileUpdate';
const KEY_EPISODE_CACHE_SIZE: string = 'prefEpisodeCacheSize';
const KEY_ENABLE_AUTODL: string = 'prefEnableAutoDl';
const KEY_ENABLE_AUTODL_ON_BATTERY: string = 'prefEnableAutoDownloadOnBattery';
const KEY_ENABLE_AUTODL_WIFI_FILTER: string = 'prefEnableAutoDownloadWifiFilter';
const KEY_AUTODL_SELECTED_NETWORKS: string = 'prefAutodownloadSelectedNetworks';
const KEY_PLAYBACK_SPEED: string = 'prefPlaybackSpeed';
const KEY_FAST_FORWARD_SECS: string = 'prefFastForwardSecs';
const KEY_REWIND_SECS: string = 'prefRewindSecs';
const KEY_QUEUE_KEEP_SORTED: string = 'prefQueueKeepSorted';
const KEY_QUEUE_KEEP_SORTED_ORDER: string = 'prefQueueKeepSortedOrder';
const KEY_DOWNLOADS_SORTED_ORDER: string = 'prefDownloadSortedOrder';
const KEY_FEED_ORDER: string = 'prefFeedOrder';
const KEY_FEED_COUNTER: string = 'prefFeedCounter';
const KEY_SKIP_SILENCE: string = 'prefSkipSilence';
const KEY_STREAM_OVER_DOWNLOAD: string = 'prefStreamOverDownload';
const KEY_DEFAULT_PAGE: string = 'prefDefaultPage';
const KEY_DELETE_WHEN_PLAYED: string = 'prefDeleteWhenPlayed';
const KEY_SHOW_REMAIN_TIME: string = 'prefShowRemainTime';
const KEY_FAVORITE_KEEP_SORTED: string = 'prefFavoriteKeepSorted';
const KEY_FAVORITE_SORT_ORDER: string = 'prefFavoriteSortedOrder';
const KEY_SWIPE_FEED: string = 'prefSwipeFeed';
const KEY_USE_EPISODE_COVER: string = 'prefUseEpisodeCover';
const KEY_SUBSCRIPTION_COLUMNS: string = 'prefSubscriptionColumns';
const KEY_SHOW_SUBSCRIPTION_TITLES: string = 'prefShowSubscriptionTitles';
const KEY_QUEUE_LOCKED: string = 'prefQueueLocked';
const KEY_HIDDEN_HOME_SECTIONS: string = 'prefHiddenHomeSections';

/**
 * User preferences backed by @kit.ArkData Preferences.
 * Uses typeof runtime checks instead of `as` assertion (per CLAUDE.md).
 */
export class UserPreferences {
  private static instance: UserPreferences | undefined = undefined;
  private prefs: preferences.Preferences | undefined = undefined;

  static getInstance(): UserPreferences {
    if (UserPreferences.instance === undefined) {
      UserPreferences.instance = new UserPreferences();
    }
    return UserPreferences.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.prefs !== undefined) {
      return;
    }
    hilog.info(DOMAIN, TAG, 'Initializing UserPreferences...');
    this.prefs = await preferences.getPreferences(context, PREFS_NAME);
    hilog.info(DOMAIN, TAG, 'UserPreferences initialized.');
  }

  // === Private safe getters (typeof checks, no `as`) ===

  private getInt(key: string, def: number): number {
    if (this.prefs === undefined) {
      return def;
    }
    const val = this.prefs.getSync(key, def);
    if (typeof val === 'number') {
      return val;
    }
    return def;
  }

  private getBoolean(key: string, def: boolean): boolean {
    if (this.prefs === undefined) {
      return def;
    }
    const val = this.prefs.getSync(key, def);
    if (typeof val === 'boolean') {
      return val;
    }
    return def;
  }

  private getString(key: string, def: string): string {
    if (this.prefs === undefined) {
      return def;
    }
    const val = this.prefs.getSync(key, def);
    if (typeof val === 'string') {
      return val;
    }
    return def;
  }

  private getFloat(key: string, def: number): number {
    if (this.prefs === undefined) {
      return def;
    }
    const val = this.prefs.getSync(key, def);
    if (typeof val === 'number') {
      return val;
    }
    return def;
  }

  private async putInt(key: string, val: number): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(key, val);
    await this.prefs.flush();
  }

  private async putBoolean(key: string, val: boolean): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(key, val);
    await this.prefs.flush();
  }

  private async putString(key: string, val: string): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(key, val);
    await this.prefs.flush();
  }

  private async putFloat(key: string, val: number): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(key, val);
    await this.prefs.flush();
  }

  // === Theme ===

  getThemeMode(): number {
    return this.getInt(KEY_THEME, THEME_SYSTEM);
  }

  async setThemeMode(mode: number): Promise<void> {
    await this.putInt(KEY_THEME, mode);
  }

  // === Enqueue ===

  getEnqueueLocation(): number {
    return this.getInt(KEY_ENQUEUE_LOCATION, ENQUEUE_AT_BACK);
  }

  async setEnqueueLocation(location: number): Promise<void> {
    await this.putInt(KEY_ENQUEUE_LOCATION, location);
  }

  isEnqueueDownloaded(): boolean {
    return this.getBoolean(KEY_ENQUEUE_DOWNLOADED, true);
  }

  async setEnqueueDownloaded(value: boolean): Promise<void> {
    await this.putBoolean(KEY_ENQUEUE_DOWNLOADED, value);
  }

  // === Playback ===

  getPlaybackSpeed(): number {
    return this.getFloat(KEY_PLAYBACK_SPEED, 1.0);
  }

  async setPlaybackSpeed(speed: number): Promise<void> {
    await this.putFloat(KEY_PLAYBACK_SPEED, speed);
  }

  getFastForwardSecs(): number {
    return this.getInt(KEY_FAST_FORWARD_SECS, 30);
  }

  async setFastForwardSecs(secs: number): Promise<void> {
    await this.putInt(KEY_FAST_FORWARD_SECS, secs);
  }

  getRewindSecs(): number {
    return this.getInt(KEY_REWIND_SECS, 10);
  }

  async setRewindSecs(secs: number): Promise<void> {
    await this.putInt(KEY_REWIND_SECS, secs);
  }

  isSkipSilence(): boolean {
    return this.getBoolean(KEY_SKIP_SILENCE, false);
  }

  async setSkipSilence(value: boolean): Promise<void> {
    await this.putBoolean(KEY_SKIP_SILENCE, value);
  }

  // === Queue sort ===

  isQueueKeepSorted(): boolean {
    return this.getBoolean(KEY_QUEUE_KEEP_SORTED, false);
  }

  async setQueueKeepSorted(value: boolean): Promise<void> {
    await this.putBoolean(KEY_QUEUE_KEEP_SORTED, value);
  }

  getQueueKeepSortedOrder(): number {
    return this.getInt(KEY_QUEUE_KEEP_SORTED_ORDER, SORT_DATE_NEW_OLD);
  }

  async setQueueKeepSortedOrder(order: number): Promise<void> {
    await this.putInt(KEY_QUEUE_KEEP_SORTED_ORDER, order);
  }

  // === Feed display ===

  getFeedOrder(): number {
    return this.getInt(KEY_FEED_ORDER, 0);
  }

  async setFeedOrder(order: number): Promise<void> {
    await this.putInt(KEY_FEED_ORDER, order);
  }

  getFeedCounter(): number {
    return this.getInt(KEY_FEED_COUNTER, 0);
  }

  async setFeedCounter(counter: number): Promise<void> {
    await this.putInt(KEY_FEED_COUNTER, counter);
  }

  // === Downloads ===

  getDownloadsSortedOrder(): number {
    return this.getInt(KEY_DOWNLOADS_SORTED_ORDER, SORT_DATE_NEW_OLD);
  }

  async setDownloadsSortedOrder(order: number): Promise<void> {
    await this.putInt(KEY_DOWNLOADS_SORTED_ORDER, order);
  }

  isStreamOverDownload(): boolean {
    return this.getBoolean(KEY_STREAM_OVER_DOWNLOAD, false);
  }

  async setStreamOverDownload(value: boolean): Promise<void> {
    await this.putBoolean(KEY_STREAM_OVER_DOWNLOAD, value);
  }

  // === Auto-download ===

  isEnableAutodownload(): boolean {
    return this.getBoolean(KEY_ENABLE_AUTODL, false);
  }

  async setEnableAutodownload(value: boolean): Promise<void> {
    await this.putBoolean(KEY_ENABLE_AUTODL, value);
  }

  isEnableAutodownloadOnBattery(): boolean {
    return this.getBoolean(KEY_ENABLE_AUTODL_ON_BATTERY, true);
  }

  async setEnableAutodownloadOnBattery(value: boolean): Promise<void> {
    await this.putBoolean(KEY_ENABLE_AUTODL_ON_BATTERY, value);
  }

  getEpisodeCacheSize(): number {
    return this.getInt(KEY_EPISODE_CACHE_SIZE, 25);
  }

  async setEpisodeCacheSize(size: number): Promise<void> {
    await this.putInt(KEY_EPISODE_CACHE_SIZE, size);
  }

  // === Auto-update ===

  getUpdateInterval(): number {
    return this.getInt(KEY_UPDATE_INTERVAL, 12);
  }

  async setUpdateInterval(hours: number): Promise<void> {
    await this.putInt(KEY_UPDATE_INTERVAL, hours);
  }

  isAutoUpdateDisabled(): boolean {
    return this.getBoolean(KEY_AUTO_UPDATE_DISABLED, false);
  }

  async setAutoUpdateDisabled(value: boolean): Promise<void> {
    await this.putBoolean(KEY_AUTO_UPDATE_DISABLED, value);
  }

  isMobileUpdate(): boolean {
    return this.getBoolean(KEY_MOBILE_UPDATE, false);
  }

  async setMobileUpdate(value: boolean): Promise<void> {
    await this.putBoolean(KEY_MOBILE_UPDATE, value);
  }

  // === UI ===

  getDefaultPage(): string {
    return this.getString(KEY_DEFAULT_PAGE, 'HomeFragment');
  }

  async setDefaultPage(page: string): Promise<void> {
    await this.putString(KEY_DEFAULT_PAGE, page);
  }

  isShowRemainTime(): boolean {
    return this.getBoolean(KEY_SHOW_REMAIN_TIME, false);
  }

  async setShowRemainTime(value: boolean): Promise<void> {
    await this.putBoolean(KEY_SHOW_REMAIN_TIME, value);
  }

  isUseEpisodeCover(): boolean {
    return this.getBoolean(KEY_USE_EPISODE_COVER, true);
  }

  async setUseEpisodeCover(value: boolean): Promise<void> {
    await this.putBoolean(KEY_USE_EPISODE_COVER, value);
  }

  isDeleteWhenPlayed(): boolean {
    return this.getBoolean(KEY_DELETE_WHEN_PLAYED, false);
  }

  async setDeleteWhenPlayed(value: boolean): Promise<void> {
    await this.putBoolean(KEY_DELETE_WHEN_PLAYED, value);
  }

  // === Notification ===

  isExpandNotify(): boolean {
    return this.getBoolean(KEY_EXPAND_NOTIFY, true);
  }

  async setExpandNotify(value: boolean): Promise<void> {
    await this.putBoolean(KEY_EXPAND_NOTIFY, value);
  }

  isPersistNotification(): boolean {
    return this.getBoolean(KEY_PERSISTENT_NOTIFICATION, true);
  }

  async setPersistNotification(value: boolean): Promise<void> {
    await this.putBoolean(KEY_PERSISTENT_NOTIFICATION, value);
  }

  isShowDownloadReport(): boolean {
    return this.getBoolean(KEY_SHOW_DOWNLOAD_REPORT, true);
  }

  async setShowDownloadReport(value: boolean): Promise<void> {
    await this.putBoolean(KEY_SHOW_DOWNLOAD_REPORT, value);
  }

  // === Favorites ===

  isFavoriteKeepSorted(): boolean {
    return this.getBoolean(KEY_FAVORITE_KEEP_SORTED, false);
  }

  async setFavoriteKeepSorted(value: boolean): Promise<void> {
    await this.putBoolean(KEY_FAVORITE_KEEP_SORTED, value);
  }

  getFavoriteSortOrder(): number {
    return this.getInt(KEY_FAVORITE_SORT_ORDER, SORT_DATE_NEW_OLD);
  }

  async setFavoriteSortOrder(order: number): Promise<void> {
    await this.putInt(KEY_FAVORITE_SORT_ORDER, order);
  }

  // === Drawer ===

  getHiddenDrawerItems(): string {
    return this.getString(KEY_HIDDEN_DRAWER_ITEMS, '');
  }

  async setHiddenDrawerItems(items: string): Promise<void> {
    await this.putString(KEY_HIDDEN_DRAWER_ITEMS, items);
  }

  // === Subscriptions display ===

  getSubscriptionColumns(): number {
    return this.getInt(KEY_SUBSCRIPTION_COLUMNS, 3);
  }

  async setSubscriptionColumns(columns: number): Promise<void> {
    await this.putInt(KEY_SUBSCRIPTION_COLUMNS, columns);
  }

  isShowSubscriptionTitles(): boolean {
    return this.getBoolean(KEY_SHOW_SUBSCRIPTION_TITLES, false);
  }

  async setShowSubscriptionTitles(value: boolean): Promise<void> {
    await this.putBoolean(KEY_SHOW_SUBSCRIPTION_TITLES, value);
  }

  // === Queue lock ===

  isQueueLocked(): boolean {
    return this.getBoolean(KEY_QUEUE_LOCKED, false);
  }

  async setQueueLocked(value: boolean): Promise<void> {
    await this.putBoolean(KEY_QUEUE_LOCKED, value);
  }

  // === Home screen sections ===

  getHiddenHomeSections(): Set<string> {
    const raw = this.getString(KEY_HIDDEN_HOME_SECTIONS, '');
    if (raw.length === 0) {
      return new Set<string>();
    }
    return new Set<string>(raw.split(','));
  }

  async setHiddenHomeSections(hidden: Set<string>): Promise<void> {
    await this.putString(KEY_HIDDEN_HOME_SECTIONS, Array.from(hidden).join(','));
  }

  // === Swipe ===

  getSwipeFeed(): string {
    return this.getString(KEY_SWIPE_FEED, '');
  }

  async setSwipeFeed(value: string): Promise<void> {
    await this.putString(KEY_SWIPE_FEED, value);
  }

  /**
   * Sync key preferences to AppStorage for UI binding.
   */
  syncToAppStorage(): void {
    AppStorage.setOrCreate<number>('themeMode', this.getThemeMode());
    AppStorage.setOrCreate<boolean>('enqueueDownloaded', this.isEnqueueDownloaded());
    AppStorage.setOrCreate<number>('enqueueLocation', this.getEnqueueLocation());
    AppStorage.setOrCreate<number>('playbackSpeed', this.getPlaybackSpeed());
    AppStorage.setOrCreate<number>('fastForwardSecs', this.getFastForwardSecs());
    AppStorage.setOrCreate<number>('rewindSecs', this.getRewindSecs());
    AppStorage.setOrCreate<boolean>('skipSilence', this.isSkipSilence());
    AppStorage.setOrCreate<boolean>('showRemainTime', this.isShowRemainTime());
    AppStorage.setOrCreate<boolean>('streamOverDownload', this.isStreamOverDownload());
    AppStorage.setOrCreate<boolean>('useEpisodeCover', this.isUseEpisodeCover());
  }
}
