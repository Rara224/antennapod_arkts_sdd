import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FeedItemDao } from '../database/FeedItemDao';
import { FeedMediaDao } from '../database/FeedMediaDao';
import { FeedDao } from '../database/FeedDao';
import { QueueDao } from '../database/QueueDao';
import { FeedItem } from '../models/FeedItem';
import { FeedMedia } from '../models/FeedMedia';
import { Feed } from '../models/Feed';
import { PlaybackPreferences } from '../helpers/PlaybackPreferences';
import {
  EventBus,
  EVENT_PLAYER_STATUS,
  EVENT_PLAYBACK_POSITION,
  EVENT_PLAYBACK_SPEED,
  EVENT_PLAYER_ERROR,
  EVENT_PLAYBACK_SERVICE,
  EVENT_QUEUE_CHANGED,
  EVENT_EPISODE_PLAY_STATE_CHANGED,
  EVENT_PLAYBACK_HISTORY_CHANGED
} from '../common/EventBus';
import {
  PlayerStatusData,
  PlaybackPositionData,
  SpeedChangedData,
  PlayerErrorData,
  PlaybackServiceData,
  EpisodePlayStateData
} from '../common/EventData';
import {
  PLAYER_STATUS_STOPPED,
  PLAYER_STATUS_PLAYING,
  PLAYER_STATUS_PAUSED,
  PLAYER_STATUS_PREPARING,
  PLAY_STATE_PLAYED
} from '../common/Constants';
import { BackgroundPlaybackManager, PlaybackCallbacks } from './BackgroundPlaybackManager';
import { SleepTimer } from './SleepTimer';

const DOMAIN: number = 0x0000;
const TAG: string = 'PlaybackController';
const POSITION_SAVE_INTERVAL_MS: number = 5000;

export class PlaybackController {
  private static instance: PlaybackController | undefined = undefined;
  private avPlayer: media.AVPlayer | undefined = undefined;
  private status: number = PLAYER_STATUS_STOPPED;
  private currentItem: FeedItem | undefined = undefined;
  private currentMedia: FeedMedia | undefined = undefined;
  private currentFeed: Feed | undefined = undefined;
  private positionSaveTimerId: number = -1;
  private currentSpeed: number = 1.0;
  private isStream: boolean = false;
  private localFileFd: number = -1;
  private feedItemDao: FeedItemDao = new FeedItemDao();
  private feedMediaDao: FeedMediaDao = new FeedMediaDao();
  private feedDao: FeedDao = new FeedDao();
  private queueDao: QueueDao = new QueueDao();
  private backgroundManager: BackgroundPlaybackManager = BackgroundPlaybackManager.getInstance();
  private sleepTimer: SleepTimer = SleepTimer.getInstance();
  private preparingEpisodeId: number = -1;

  static getInstance(): PlaybackController {
    if (PlaybackController.instance === undefined) {
      PlaybackController.instance = new PlaybackController();
    }
    return PlaybackController.instance;
  }

  private constructor() {
    this.sleepTimer.setOnTimerExpired(async (): Promise<void> => {
      hilog.info(DOMAIN, TAG, 'Sleep timer expired, pausing playback');
      await this.pause();
    });
  }

  async playEpisode(episodeId: number): Promise<void> {
    // Guard: skip if already preparing the same episode
    if (this.status === PLAYER_STATUS_PREPARING && this.preparingEpisodeId === episodeId) {
      hilog.info(DOMAIN, TAG, 'Already preparing episode %{public}d, skipping', episodeId);
      return;
    }

    hilog.info(DOMAIN, TAG, 'playEpisode: %{public}d', episodeId);
    this.preparingEpisodeId = episodeId;

    // Show preparing state immediately for responsive UI
    this.setStatus(PLAYER_STATUS_PREPARING);

    // Load episode data
    const item = await this.feedItemDao.getFeedItem(episodeId);
    if (item === null) {
      hilog.error(DOMAIN, TAG, 'Episode not found: %{public}d', episodeId);
      return;
    }
    if (item.media === null) {
      hilog.error(DOMAIN, TAG, 'Episode has no media: %{public}d', episodeId);
      return;
    }
    const feedMedia = item.media;
    const feed = await this.feedDao.getFeed(item.feedId);

    // Stop current playback if any
    if (this.status !== PLAYER_STATUS_STOPPED) {
      await this.stopInternal(false);
    }

    this.currentItem = item;
    this.currentMedia = feedMedia;
    this.currentFeed = feed !== null ? feed : undefined;

    // Determine playback speed
    this.currentSpeed = this.determineSpeed();

    // Determine source URL
    this.isStream = !feedMedia.isDownloaded();
    let sourceUrl: string;
    if (feedMedia.isDownloaded()) {
      // HarmonyOS AVPlayer 需要用 fd:// 协议播放本地文件
      try {
        const file = fileIo.openSync(feedMedia.localFileUrl, fileIo.OpenMode.READ_ONLY);
        this.localFileFd = file.fd;
        sourceUrl = 'fd://' + file.fd.toString();
        hilog.info(DOMAIN, TAG, 'Playing local file: fd=%{public}d, path=%{public}s',
          file.fd, feedMedia.localFileUrl);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'Failed to open local file, falling back to stream: %{public}s',
          JSON.stringify(e));
        this.isStream = true;
        sourceUrl = feedMedia.downloadUrl;
      }
    } else {
      sourceUrl = feedMedia.downloadUrl;
    }

    if (sourceUrl.length === 0) {
      hilog.error(DOMAIN, TAG, 'No playback URL available');
      return;
    }

    // Update AppStorage with episode info
    AppStorage.setOrCreate<string>('currentEpisodeTitle', item.title);
    AppStorage.setOrCreate<string>('currentFeedTitle',
      this.currentFeed !== undefined ? this.currentFeed.getDisplayTitle() : '');
    AppStorage.setOrCreate<number>('currentEpisodeId', item.id);
    AppStorage.setOrCreate<string>('currentCoverUrl', item.getImageLocation());
    AppStorage.setOrCreate<boolean>('isPlayerVisible', true);
    AppStorage.setOrCreate<number>('playbackPosition', feedMedia.position);
    AppStorage.setOrCreate<number>('playbackDuration', feedMedia.duration);
    AppStorage.setOrCreate<string>('currentEpisodePubDate', item.getPubDateStr());
    AppStorage.setOrCreate<number>('currentFeedId', item.feedId);
    AppStorage.setOrCreate<string>('currentFeedLink',
      this.currentFeed !== undefined ? this.currentFeed.link : '');
    AppStorage.setOrCreate<string>('currentMediaUrl', feedMedia.downloadUrl);

    try {
      // Create AVPlayer first for fastest startup
      this.avPlayer = await media.createAVPlayer();
      this.setupAVPlayerCallbacks();

      // Set URL triggers Initialized state, then call prepare()
      this.avPlayer.url = sourceUrl;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to create AVPlayer: %{public}s', JSON.stringify(e));
      this.setStatus(PLAYER_STATUS_STOPPED);
    }

    // Record last played time AFTER starting AVPlayer (non-blocking)
    this.feedMediaDao.setLastPlayedTime(feedMedia.id, Date.now());
    EventBus.getInstance().publish(EVENT_PLAYBACK_HISTORY_CHANGED, new Object());
  }

  async play(): Promise<void> {
    if (this.avPlayer === undefined || this.status !== PLAYER_STATUS_PAUSED) {
      return;
    }
    this.avPlayer.play();
  }

  async pause(): Promise<void> {
    if (this.avPlayer === undefined || this.status !== PLAYER_STATUS_PLAYING) {
      return;
    }
    this.avPlayer.pause();
  }

  async playPause(): Promise<void> {
    if (this.status === PLAYER_STATUS_PREPARING) {
      // Already loading — ignore repeated clicks
      return;
    } else if (this.status === PLAYER_STATUS_PLAYING) {
      await this.pause();
    } else if (this.status === PLAYER_STATUS_PAUSED) {
      await this.play();
    } else if (this.status === PLAYER_STATUS_STOPPED) {
      // Re-play the current episode when player is stopped (e.g. after restore)
      const currentEpisodeId = AppStorage.get<number>('currentEpisodeId');
      if (currentEpisodeId !== undefined && currentEpisodeId > 0) {
        await this.playEpisode(currentEpisodeId);
      }
    }
  }

  async stop(): Promise<void> {
    await this.stopInternal(true);
  }

  async seekTo(positionMs: number): Promise<void> {
    if (this.avPlayer === undefined) {
      return;
    }
    if (this.status !== PLAYER_STATUS_PLAYING && this.status !== PLAYER_STATUS_PAUSED) {
      return;
    }
    let safePos = positionMs;
    if (safePos < 0) {
      safePos = 0;
    }
    const duration = AppStorage.get<number>('playbackDuration');
    if (duration !== undefined && duration > 0 && safePos > duration) {
      safePos = duration;
    }
    this.avPlayer.seek(safePos);
  }

  async rewind(): Promise<void> {
    const rewindSecs = AppStorage.get<number>('rewindSecs');
    const secs = rewindSecs !== undefined ? rewindSecs : 10;
    const pos = AppStorage.get<number>('playbackPosition');
    const currentPos = pos !== undefined ? pos : 0;
    await this.seekTo(currentPos - secs * 1000);
  }

  async fastForward(): Promise<void> {
    const ffSecs = AppStorage.get<number>('fastForwardSecs');
    const secs = ffSecs !== undefined ? ffSecs : 30;
    const pos = AppStorage.get<number>('playbackPosition');
    const currentPos = pos !== undefined ? pos : 0;
    await this.seekTo(currentPos + secs * 1000);
  }

  async skipToNext(): Promise<void> {
    const nextItem = await this.getNextQueueItem();
    if (nextItem !== null) {
      await this.playEpisode(nextItem.id);
    } else {
      await this.stop();
    }
  }

  async skipToPrevious(): Promise<void> {
    // Restart current episode from beginning
    await this.seekTo(0);
  }

  async setSpeed(speed: number): Promise<void> {
    const snapped = this.snapToValidSpeed(speed);
    this.currentSpeed = snapped;
    if (this.avPlayer !== undefined &&
        (this.status === PLAYER_STATUS_PLAYING || this.status === PLAYER_STATUS_PAUSED)) {
      this.avPlayer.setSpeed(this.mapToPlaybackSpeed(snapped));
    }
    AppStorage.setOrCreate<number>('playbackSpeed', snapped);
    EventBus.getInstance().publish(EVENT_PLAYBACK_SPEED, new SpeedChangedData(snapped));
  }

  async release(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Releasing PlaybackController resources');
    await this.stopInternal(true);
    this.sleepTimer.cancel();
  }

  async restoreLastPlayedEpisode(): Promise<void> {
    const prefs = PlaybackPreferences.getInstance();
    const mediaId = prefs.getCurrentlyPlayingFeedMediaId();
    if (mediaId <= 0) {
      return;
    }

    const feedMedia = await this.feedMediaDao.getFeedMedia(mediaId);
    if (feedMedia === null) {
      return;
    }

    const item = await this.feedItemDao.getFeedItem(feedMedia.itemId);
    if (item === null) {
      return;
    }

    const feed = await this.feedDao.getFeed(item.feedId);
    const feedTitle = feed !== null ? feed.getDisplayTitle() : '';

    // Populate AppStorage for UI display — do not auto-play
    AppStorage.setOrCreate<string>('currentEpisodeTitle', item.title);
    AppStorage.setOrCreate<string>('currentFeedTitle', feedTitle);
    AppStorage.setOrCreate<number>('currentEpisodeId', item.id);
    AppStorage.setOrCreate<string>('currentCoverUrl', item.getImageLocation());
    AppStorage.setOrCreate<number>('playbackPosition', feedMedia.position);
    AppStorage.setOrCreate<number>('playbackDuration', feedMedia.duration);
    AppStorage.setOrCreate<boolean>('isPlayerVisible', true);
    AppStorage.setOrCreate<number>('playbackSpeed', prefs.getCurrentPlaybackSpeed());
    AppStorage.setOrCreate<string>('currentEpisodePubDate', item.getPubDateStr());
    AppStorage.setOrCreate<number>('currentFeedId', item.feedId);
    AppStorage.setOrCreate<string>('currentFeedLink', feed !== null ? feed.link : '');

    hilog.info(DOMAIN, TAG, 'Restored last played: %{public}s', item.title);
  }

  getStatus(): number {
    return this.status;
  }

  getCurrentEpisodeId(): number {
    if (this.currentItem !== undefined) {
      return this.currentItem.id;
    }
    return -1;
  }

  // ==================== Private Methods ====================

  private setupAVPlayerCallbacks(): void {
    if (this.avPlayer === undefined) {
      return;
    }
    const player = this.avPlayer;

    player.on('stateChange', (state: string) => {
      this.onStateChange(state);
    });

    player.on('timeUpdate', (time: number) => {
      AppStorage.setOrCreate<number>('playbackPosition', time);
      EventBus.getInstance().publish(EVENT_PLAYBACK_POSITION,
        new PlaybackPositionData(time, AppStorage.get<number>('playbackDuration') ?? 0));
    });

    player.on('seekDone', (seekPos: number) => {
      AppStorage.setOrCreate<number>('playbackPosition', seekPos);
      this.backgroundManager.updatePlaybackState(
        this.status === PLAYER_STATUS_PLAYING, seekPos);
    });

    player.on('error', () => {
      hilog.error(DOMAIN, TAG, 'AVPlayer error');
      EventBus.getInstance().publish(EVENT_PLAYER_ERROR,
        new PlayerErrorData('Playback error'));
      this.resetPlayer();
      this.setStatus(PLAYER_STATUS_STOPPED);
    });
  }

  private onStateChange(state: string): void {
    hilog.info(DOMAIN, TAG, 'AVPlayer state: %{public}s', state);

    if (state === 'initialized') {
      // After URL is set, call prepare
      if (this.avPlayer !== undefined) {
        this.avPlayer.prepare();
      }
    } else if (state === 'prepared') {
      this.onPrepared();
    } else if (state === 'playing') {
      this.onPlaying();
    } else if (state === 'paused') {
      this.onPaused();
    } else if (state === 'completed') {
      this.onCompleted();
    } else if (state === 'stopped') {
      // AVPlayer stopped state
    } else if (state === 'released') {
      // AVPlayer released
    } else if (state === 'error') {
      hilog.error(DOMAIN, TAG, 'AVPlayer entered error state');
      EventBus.getInstance().publish(EVENT_PLAYER_ERROR,
        new PlayerErrorData('AVPlayer error state'));
      this.resetPlayer();
      this.setStatus(PLAYER_STATUS_STOPPED);
    }
  }

  private onPrepared(): void {
    if (this.avPlayer === undefined || this.currentMedia === undefined) {
      return;
    }

    // Update duration from AVPlayer
    const duration = this.avPlayer.duration;
    if (duration > 0) {
      AppStorage.setOrCreate<number>('playbackDuration', duration);
      this.currentMedia.duration = duration;
      this.feedMediaDao.setDuration(this.currentMedia.id, duration);
      this.backgroundManager.updateMetadata(
        this.currentItem !== undefined ? this.currentItem.title : '',
        this.currentFeed !== undefined ? this.currentFeed.getDisplayTitle() : '',
        duration
      );
    }

    // Set speed
    this.avPlayer.setSpeed(this.mapToPlaybackSpeed(this.currentSpeed));

    // Determine start position
    let startPos = this.currentMedia.position;

    // Skip intro for first play
    if (this.currentFeed !== undefined && startPos === 0) {
      const skipIntro = this.currentFeed.preferences.feedSkipIntro;
      if (skipIntro > 0) {
        startPos = skipIntro * 1000;
        hilog.info(DOMAIN, TAG, 'Skipping intro: %{public}d seconds', skipIntro);
      }
    }

    // Seek to saved position, then play
    if (startPos > 0) {
      this.avPlayer.seek(startPos);
    }

    // Start playback
    this.avPlayer.play();

    // Start background playback
    const callbacks: PlaybackCallbacks = {
      onPlay: async (): Promise<void> => {
        await this.play();
      },
      onPause: async (): Promise<void> => {
        await this.pause();
      },
      onSeek: async (timeMs: number): Promise<void> => {
        await this.seekTo(timeMs);
      },
      onFastForward: async (): Promise<void> => {
        await this.fastForward();
      },
      onRewind: async (): Promise<void> => {
        await this.rewind();
      },
      onNext: async (): Promise<void> => {
        await this.skipToNext();
      },
      onPrevious: async (): Promise<void> => {
        await this.skipToPrevious();
      }
    };
    this.backgroundManager.start(callbacks);

    // Write playback preferences
    if (this.currentItem !== undefined) {
      PlaybackPreferences.getInstance().writeMediaPlaying(
        this.currentMedia.id,
        this.currentItem.feedId,
        this.isStream,
        false,
        this.currentSpeed
      );
    }
  }

  private onPlaying(): void {
    this.preparingEpisodeId = -1;
    this.setStatus(PLAYER_STATUS_PLAYING);
    AppStorage.setOrCreate<boolean>('isPlaying', true);
    this.startPositionSaveTimer();
    this.backgroundManager.updatePlaybackState(true,
      AppStorage.get<number>('playbackPosition') ?? 0);
    EventBus.getInstance().publish(EVENT_PLAYBACK_SERVICE,
      new PlaybackServiceData(PlaybackServiceData.ACTION_START));
  }

  private onPaused(): void {
    this.setStatus(PLAYER_STATUS_PAUSED);
    AppStorage.setOrCreate<boolean>('isPlaying', false);
    this.stopPositionSaveTimer();
    this.savePosition();
    this.backgroundManager.updatePlaybackState(false,
      AppStorage.get<number>('playbackPosition') ?? 0);
  }

  private async onCompleted(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Playback completed');

    // Mark episode as played
    if (this.currentItem !== undefined) {
      await this.feedItemDao.markItemPlayed(this.currentItem.id, PLAY_STATE_PLAYED);
      EventBus.getInstance().publish(EVENT_EPISODE_PLAY_STATE_CHANGED,
        new EpisodePlayStateData(this.currentItem.id, PLAY_STATE_PLAYED));
    }

    // Set completion date
    if (this.currentMedia !== undefined) {
      await this.feedMediaDao.setPlaybackCompletionDate(this.currentMedia.id, Date.now());
      await this.feedMediaDao.setPosition(this.currentMedia.id, 0);
      EventBus.getInstance().publish(EVENT_PLAYBACK_HISTORY_CHANGED, new Object());
    }

    // Remove from queue
    if (this.currentItem !== undefined) {
      await this.queueDao.removeFromQueue(this.currentItem.id);
      EventBus.getInstance().publish(EVENT_QUEUE_CHANGED, new Object());
    }

    // Try to play next in queue
    const nextItem = await this.getNextQueueItem();
    if (nextItem !== null) {
      await this.playEpisode(nextItem.id);
    } else {
      await this.stopInternal(true);
    }
  }

  private async stopInternal(clearUI: boolean): Promise<void> {
    this.stopPositionSaveTimer();
    this.savePosition();

    if (this.avPlayer !== undefined) {
      try {
        this.avPlayer.off('stateChange');
        this.avPlayer.off('timeUpdate');
        this.avPlayer.off('seekDone');
        this.avPlayer.off('error');
        await this.avPlayer.reset();
        await this.avPlayer.release();
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'Error releasing AVPlayer: %{public}s', JSON.stringify(e));
      }
      this.avPlayer = undefined;
    }

    // 关闭本地文件描述符
    if (this.localFileFd >= 0) {
      try {
        fileIo.closeSync(this.localFileFd);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'Failed to close local file fd: %{public}s', JSON.stringify(e));
      }
      this.localFileFd = -1;
    }

    await this.backgroundManager.stop();

    this.setStatus(PLAYER_STATUS_STOPPED);
    AppStorage.setOrCreate<boolean>('isPlaying', false);

    if (clearUI) {
      AppStorage.setOrCreate<boolean>('isPlayerVisible', false);
      AppStorage.setOrCreate<string>('currentEpisodeTitle', '');
      AppStorage.setOrCreate<string>('currentFeedTitle', '');
      AppStorage.setOrCreate<number>('currentEpisodeId', -1);
      AppStorage.setOrCreate<string>('currentCoverUrl', '');
      AppStorage.setOrCreate<number>('playbackPosition', 0);
      AppStorage.setOrCreate<number>('playbackDuration', 0);
      AppStorage.setOrCreate<string>('currentEpisodePubDate', '');
      AppStorage.setOrCreate<number>('currentFeedId', -1);
      AppStorage.setOrCreate<string>('currentFeedLink', '');
      await PlaybackPreferences.getInstance().writeNoMediaPlaying();
    }

    this.currentItem = undefined;
    this.currentMedia = undefined;
    this.currentFeed = undefined;

    EventBus.getInstance().publish(EVENT_PLAYBACK_SERVICE,
      new PlaybackServiceData(PlaybackServiceData.ACTION_STOP));
  }

  private resetPlayer(): void {
    if (this.avPlayer !== undefined) {
      try {
        this.avPlayer.off('stateChange');
        this.avPlayer.off('timeUpdate');
        this.avPlayer.off('seekDone');
        this.avPlayer.off('error');
        this.avPlayer.reset();
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'Error resetting AVPlayer: %{public}s', JSON.stringify(e));
      }
    }
  }

  private setStatus(newStatus: number): void {
    this.status = newStatus;
    AppStorage.setOrCreate<boolean>('isPreparing', newStatus === PLAYER_STATUS_PREPARING);
    EventBus.getInstance().publish(EVENT_PLAYER_STATUS, new PlayerStatusData(newStatus));
  }

  private startPositionSaveTimer(): void {
    this.stopPositionSaveTimer();
    this.positionSaveTimerId = setInterval((): void => {
      this.savePosition();
    }, POSITION_SAVE_INTERVAL_MS);
  }

  private stopPositionSaveTimer(): void {
    if (this.positionSaveTimerId !== -1) {
      clearInterval(this.positionSaveTimerId);
      this.positionSaveTimerId = -1;
    }
  }

  private savePosition(): void {
    if (this.currentMedia === undefined) {
      return;
    }
    const pos = AppStorage.get<number>('playbackPosition');
    if (pos !== undefined && pos > 0) {
      this.currentMedia.position = pos;
      this.feedMediaDao.setPosition(this.currentMedia.id, pos);
    }
  }

  private determineSpeed(): number {
    // Per-feed speed takes priority
    if (this.currentFeed !== undefined) {
      const feedSpeed = this.currentFeed.preferences.feedPlaybackSpeed;
      if (feedSpeed > 0) {
        return this.snapToValidSpeed(feedSpeed);
      }
    }
    // Global speed
    const globalSpeed = AppStorage.get<number>('playbackSpeed');
    return this.snapToValidSpeed(globalSpeed !== undefined ? globalSpeed : 1.0);
  }

  private snapToValidSpeed(speed: number): number {
    const validSpeeds: number[] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    let closest = validSpeeds[0];
    let minDiff = Math.abs(speed - closest);
    for (let i = 1; i < validSpeeds.length; i++) {
      const diff = Math.abs(speed - validSpeeds[i]);
      if (diff < minDiff) {
        minDiff = diff;
        closest = validSpeeds[i];
      }
    }
    return closest;
  }

  private mapToPlaybackSpeed(speed: number): media.PlaybackSpeed {
    if (speed <= 0.75) {
      return media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
    } else if (speed <= 1.0) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
    } else if (speed <= 1.25) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
    } else if (speed <= 1.5) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_50_X;
    } else if (speed <= 1.75) {
      return media.PlaybackSpeed.SPEED_FORWARD_1_75_X;
    }
    return media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
  }

  private async getNextQueueItem(): Promise<FeedItem | null> {
    const queue = await this.queueDao.getQueue();
    if (queue.length === 0) {
      return null;
    }
    // If currently playing, find the next item after it
    if (this.currentItem !== undefined) {
      for (let i = 0; i < queue.length; i++) {
        if (queue[i].id === this.currentItem.id && i + 1 < queue.length) {
          return queue[i + 1];
        }
      }
    }
    // Default to first item in queue
    return queue[0];
  }
}
