import { media } from '@kit.MediaKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FeedItemDao } from '../database/FeedItemDao';
import { FeedItem } from '../models/FeedItem';
import { FeedMedia } from '../models/FeedMedia';
import { PLAYER_STATUS_STOPPED, PLAYER_STATUS_PLAYING, PLAYER_STATUS_PAUSED, PLAYER_STATUS_PREPARING } from '../common/Constants';

const DOMAIN: number = 0x0000;
const TAG: string = 'VideoPlayerViewModel';

export class VideoPlayerViewModel {
  private feedItemDao: FeedItemDao = new FeedItemDao();
  avPlayer: media.AVPlayer | undefined = undefined;
  item: FeedItem | null = null;
  feedMedia: FeedMedia | null = null;
  status: number = PLAYER_STATUS_STOPPED;
  position: number = 0;
  duration: number = 0;

  async loadEpisode(episodeId: number): Promise<boolean> {
    const item = await this.feedItemDao.getFeedItem(episodeId);
    if (item === null || item.media === null) {
      hilog.error(DOMAIN, TAG, 'Episode or media not found: %{public}d', episodeId);
      return false;
    }
    this.item = item;
    this.feedMedia = item.media;
    this.duration = item.media.duration;
    this.position = item.media.position;
    return true;
  }

  async createPlayer(surfaceId: string): Promise<void> {
    this.avPlayer = await media.createAVPlayer();
    this.avPlayer.surfaceId = surfaceId;

    const player = this.avPlayer;
    const vm = this;

    player.on('stateChange', (state: string) => {
      if (state === 'initialized') {
        player.prepare();
      } else if (state === 'prepared') {
        vm.status = PLAYER_STATUS_PAUSED;
        vm.duration = player.duration > 0 ? player.duration : vm.duration;
        if (vm.position > 0) {
          player.seek(vm.position);
        }
        player.play();
      } else if (state === 'playing') {
        vm.status = PLAYER_STATUS_PLAYING;
      } else if (state === 'paused') {
        vm.status = PLAYER_STATUS_PAUSED;
      } else if (state === 'completed') {
        vm.status = PLAYER_STATUS_STOPPED;
        vm.position = 0;
      } else if (state === 'error') {
        hilog.error(DOMAIN, TAG, 'AVPlayer error state');
        vm.status = PLAYER_STATUS_STOPPED;
      }
    });

    player.on('timeUpdate', (time: number) => {
      vm.position = time;
    });

    // Set source URL
    if (this.feedMedia !== null) {
      if (this.feedMedia.isDownloaded()) {
        player.url = 'file://' + this.feedMedia.localFileUrl;
      } else {
        player.url = this.feedMedia.downloadUrl;
      }
    }

    this.status = PLAYER_STATUS_PREPARING;
  }

  async playPause(): Promise<void> {
    if (this.avPlayer === undefined) {
      return;
    }
    if (this.status === PLAYER_STATUS_PLAYING) {
      this.avPlayer.pause();
    } else if (this.status === PLAYER_STATUS_PAUSED) {
      this.avPlayer.play();
    }
  }

  async seekTo(positionMs: number): Promise<void> {
    if (this.avPlayer === undefined) {
      return;
    }
    let safePos = positionMs;
    if (safePos < 0) {
      safePos = 0;
    }
    if (this.duration > 0 && safePos > this.duration) {
      safePos = this.duration;
    }
    this.avPlayer.seek(safePos);
  }

  async release(): Promise<void> {
    if (this.avPlayer !== undefined) {
      try {
        this.avPlayer.off('stateChange');
        this.avPlayer.off('timeUpdate');
        await this.avPlayer.reset();
        await this.avPlayer.release();
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'Error releasing AVPlayer: %{public}s', JSON.stringify(e));
      }
      this.avPlayer = undefined;
    }
    this.status = PLAYER_STATUS_STOPPED;
  }
}
