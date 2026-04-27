import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FEED_FILE_FEED_MEDIA } from '../common/Constants';

const DOMAIN: number = 0x0000;
const TAG: string = 'PlaybackPreferences';
const PREFS_NAME: string = 'playback_prefs';

const KEY_CURRENTLY_PLAYING_MEDIA_TYPE: string = 'currentlyPlayingFeedMediaType';
const KEY_CURRENTLY_PLAYING_MEDIA_ID: string = 'currentlyPlayingFeedMediaId';
const KEY_CURRENTLY_PLAYING_FEED_ID: string = 'currentlyPlayingFeedId';
const KEY_CURRENT_EPISODE_IS_STREAM: string = 'currentEpisodeIsStream';
const KEY_CURRENT_EPISODE_IS_VIDEO: string = 'currentEpisodeIsVideo';
const KEY_LAST_PLAYED_TIME: string = 'lastPlayedTime';
const KEY_CURRENT_PLAYBACK_SPEED: string = 'currentPlaybackSpeed';

const NO_MEDIA_PLAYING: number = -1;

/**
 * Tracks the currently playing media state.
 */
export class PlaybackPreferences {
  private static instance: PlaybackPreferences | undefined = undefined;
  private prefs: preferences.Preferences | undefined = undefined;

  static getInstance(): PlaybackPreferences {
    if (PlaybackPreferences.instance === undefined) {
      PlaybackPreferences.instance = new PlaybackPreferences();
    }
    return PlaybackPreferences.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.prefs !== undefined) {
      return;
    }
    hilog.info(DOMAIN, TAG, 'Initializing PlaybackPreferences...');
    this.prefs = await preferences.getPreferences(context, PREFS_NAME);
    hilog.info(DOMAIN, TAG, 'PlaybackPreferences initialized.');
  }

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

  getCurrentlyPlayingMediaType(): number {
    return this.getInt(KEY_CURRENTLY_PLAYING_MEDIA_TYPE, NO_MEDIA_PLAYING);
  }

  getCurrentlyPlayingFeedMediaId(): number {
    return this.getInt(KEY_CURRENTLY_PLAYING_MEDIA_ID, NO_MEDIA_PLAYING);
  }

  getCurrentlyPlayingFeedId(): number {
    return this.getInt(KEY_CURRENTLY_PLAYING_FEED_ID, NO_MEDIA_PLAYING);
  }

  isCurrentEpisodeStream(): boolean {
    return this.getBoolean(KEY_CURRENT_EPISODE_IS_STREAM, true);
  }

  isCurrentEpisodeVideo(): boolean {
    return this.getBoolean(KEY_CURRENT_EPISODE_IS_VIDEO, false);
  }

  getLastPlayedTime(): number {
    return this.getInt(KEY_LAST_PLAYED_TIME, 0);
  }

  getCurrentPlaybackSpeed(): number {
    return this.getFloat(KEY_CURRENT_PLAYBACK_SPEED, 1.0);
  }

  /**
   * Write the currently playing media info.
   */
  async writeMediaPlaying(feedMediaId: number, feedId: number,
    isStream: boolean, isVideo: boolean, speed: number): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_CURRENTLY_PLAYING_MEDIA_TYPE, FEED_FILE_FEED_MEDIA);
    await this.prefs.put(KEY_CURRENTLY_PLAYING_MEDIA_ID, feedMediaId);
    await this.prefs.put(KEY_CURRENTLY_PLAYING_FEED_ID, feedId);
    await this.prefs.put(KEY_CURRENT_EPISODE_IS_STREAM, isStream);
    await this.prefs.put(KEY_CURRENT_EPISODE_IS_VIDEO, isVideo);
    await this.prefs.put(KEY_CURRENT_PLAYBACK_SPEED, speed);
    await this.prefs.put(KEY_LAST_PLAYED_TIME, Date.now());
    await this.prefs.flush();
  }

  /**
   * Clear the currently playing media info.
   */
  async writeNoMediaPlaying(): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_CURRENTLY_PLAYING_MEDIA_TYPE, NO_MEDIA_PLAYING);
    await this.prefs.put(KEY_CURRENTLY_PLAYING_MEDIA_ID, NO_MEDIA_PLAYING);
    await this.prefs.put(KEY_CURRENTLY_PLAYING_FEED_ID, NO_MEDIA_PLAYING);
    await this.prefs.put(KEY_CURRENT_EPISODE_IS_STREAM, true);
    await this.prefs.put(KEY_CURRENT_EPISODE_IS_VIDEO, false);
    await this.prefs.flush();
  }
}
