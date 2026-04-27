import { hilog } from '@kit.PerformanceAnalysisKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { wantAgent } from '@kit.AbilityKit';
import { avSession } from '@kit.AVSessionKit';
import { GlobalState } from '../common/GlobalState';

const DOMAIN: number = 0x0000;
const TAG: string = 'BackgroundPlaybackManager';

export interface PlaybackCallbacks {
  onPlay: () => Promise<void>;
  onPause: () => Promise<void>;
  onSeek: (timeMs: number) => Promise<void>;
  onFastForward: () => Promise<void>;
  onRewind: () => Promise<void>;
  onNext: () => Promise<void>;
  onPrevious: () => Promise<void>;
}

export class BackgroundPlaybackManager {
  private static instance: BackgroundPlaybackManager | undefined = undefined;
  private session: avSession.AVSession | undefined = undefined;
  private isBackgroundRunning: boolean = false;

  static getInstance(): BackgroundPlaybackManager {
    if (BackgroundPlaybackManager.instance === undefined) {
      BackgroundPlaybackManager.instance = new BackgroundPlaybackManager();
    }
    return BackgroundPlaybackManager.instance;
  }

  async start(callbacks: PlaybackCallbacks): Promise<void> {
    if (this.isBackgroundRunning) {
      return;
    }
    const context = GlobalState.getContext();
    try {
      // 1. Create WantAgent for notification tap
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: 'com.example.antennapod_arkts',
            abilityName: 'EntryAbility'
          }
        ],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };
      const agent = await wantAgent.getWantAgent(wantAgentInfo);

      // 2. Start background running
      await backgroundTaskManager.startBackgroundRunning(context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, agent);

      // 3. Create AVSession
      this.session = await avSession.createAVSession(context, 'AntennaPod', 'audio');

      // 4. Activate session
      await this.session.activate();

      // 5. Register playback commands
      this.session.on('play', () => {
        callbacks.onPlay();
      });
      this.session.on('pause', () => {
        callbacks.onPause();
      });
      this.session.on('seek', (time: number) => {
        callbacks.onSeek(time);
      });
      this.session.on('fastForward', () => {
        callbacks.onFastForward();
      });
      this.session.on('rewind', () => {
        callbacks.onRewind();
      });
      this.session.on('playNext', () => {
        callbacks.onNext();
      });
      this.session.on('playPrevious', () => {
        callbacks.onPrevious();
      });

      this.isBackgroundRunning = true;
      hilog.info(DOMAIN, TAG, 'Background playback started');
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to start background playback: %{public}s', JSON.stringify(e));
    }
  }

  async stop(): Promise<void> {
    if (!this.isBackgroundRunning) {
      return;
    }
    try {
      if (this.session !== undefined) {
        this.session.off('play');
        this.session.off('pause');
        this.session.off('seek');
        this.session.off('fastForward');
        this.session.off('rewind');
        this.session.off('playNext');
        this.session.off('playPrevious');
        await this.session.deactivate();
        await this.session.destroy();
        this.session = undefined;
      }
      const context = GlobalState.getContext();
      await backgroundTaskManager.stopBackgroundRunning(context);
      this.isBackgroundRunning = false;
      hilog.info(DOMAIN, TAG, 'Background playback stopped');
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to stop background playback: %{public}s', JSON.stringify(e));
    }
  }

  async updateMetadata(title: string, artist: string, durationMs: number): Promise<void> {
    if (this.session === undefined) {
      return;
    }
    try {
      const metadata: avSession.AVMetadata = {
        assetId: '0',
        title: title,
        artist: artist,
        duration: durationMs
      };
      await this.session.setAVMetadata(metadata);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to update metadata: %{public}s', JSON.stringify(e));
    }
  }

  async updatePlaybackState(isPlaying: boolean, positionMs: number): Promise<void> {
    if (this.session === undefined) {
      return;
    }
    try {
      const pos: avSession.PlaybackPosition = {
        elapsedTime: positionMs,
        updateTime: Date.now()
      };
      const playbackState: avSession.AVPlaybackState = {
        state: isPlaying ? avSession.PlaybackState.PLAYBACK_STATE_PLAY :
          avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
        position: pos
      };
      await this.session.setAVPlaybackState(playbackState);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to update playback state: %{public}s', JSON.stringify(e));
    }
  }
}
