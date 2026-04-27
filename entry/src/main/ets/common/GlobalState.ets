import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { PodDatabase } from '../database/PodDatabase';
import { UserPreferences } from '../helpers/UserPreferences';
import { PlaybackPreferences } from '../helpers/PlaybackPreferences';
import { SleepTimerPreferences } from '../helpers/SleepTimerPreferences';
import { SyncCredentials } from '../helpers/SyncCredentials';

const DOMAIN: number = 0x0000;
const TAG: string = 'GlobalState';

export class GlobalState {
  private static initialized: boolean = false;
  private static appContext: Context | undefined = undefined;
  private static abilityContext: common.UIAbilityContext | undefined = undefined;
  static filesDir: string = '';
  static cacheDir: string = '';
  static downloadDir: string = '';

  static getContext(): Context {
    if (GlobalState.appContext === undefined) {
      throw new Error('GlobalState not initialized');
    }
    return GlobalState.appContext;
  }

  static setAbilityContext(context: common.UIAbilityContext): void {
    GlobalState.abilityContext = context;
  }

  static async openLink(url: string): Promise<void> {
    if (GlobalState.abilityContext !== undefined) {
      try {
        await GlobalState.abilityContext.openLink(url);
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'Failed to open link: %{public}s', JSON.stringify(err));
      }
    }
  }

  static async init(context: Context): Promise<void> {
    if (GlobalState.initialized) {
      return;
    }
    hilog.info(DOMAIN, TAG, 'Initializing GlobalState...');
    GlobalState.appContext = context;
    GlobalState.filesDir = context.filesDir;
    GlobalState.cacheDir = context.cacheDir;
    GlobalState.downloadDir = context.filesDir + '/downloads';
    GlobalState.initAppStorage();

    // Initialize database
    await PodDatabase.getInstance().init(context);

    // Initialize preferences
    await UserPreferences.getInstance().init(context);
    await PlaybackPreferences.getInstance().init(context);
    await SleepTimerPreferences.getInstance().init(context);
    await SyncCredentials.getInstance().init(context);

    // Sync preferences to AppStorage for UI binding
    UserPreferences.getInstance().syncToAppStorage();

    GlobalState.initialized = true;
    AppStorage.setOrCreate<boolean>('dbReady', true);
    hilog.info(DOMAIN, TAG, 'GlobalState initialized.');
  }

  private static initAppStorage(): void {
    // Database readiness flag
    AppStorage.setOrCreate<boolean>('dbReady', false);

    // Player state
    AppStorage.setOrCreate<boolean>('isPlaying', false);
    AppStorage.setOrCreate<string>('currentEpisodeTitle', '');
    AppStorage.setOrCreate<string>('currentFeedTitle', '');
    AppStorage.setOrCreate<number>('currentEpisodeId', -1);
    AppStorage.setOrCreate<number>('currentFeedId', -1);
    AppStorage.setOrCreate<string>('currentFeedLink', '');
    AppStorage.setOrCreate<string>('currentMediaUrl', '');
    AppStorage.setOrCreate<string>('currentCoverUrl', '');
    AppStorage.setOrCreate<number>('playbackPosition', 0);
    AppStorage.setOrCreate<number>('playbackDuration', 0);

    // UI state
    AppStorage.setOrCreate<number>('currentTabIndex', 0);
    AppStorage.setOrCreate<boolean>('isPlayerVisible', false);
    AppStorage.setOrCreate<boolean>('isFullPlayerVisible', false);
    AppStorage.setOrCreate<boolean>('isSettingsVisible', false);
    AppStorage.setOrCreate<boolean>('isPreparing', false);

    // App state
    AppStorage.setOrCreate<boolean>('isFeedUpdateRunning', false);
    AppStorage.setOrCreate<number>('themeMode', 0);

    // Preferences-driven UI state (defaults, overwritten by syncToAppStorage)
    AppStorage.setOrCreate<boolean>('enqueueDownloaded', true);
    AppStorage.setOrCreate<number>('enqueueLocation', 1);
    AppStorage.setOrCreate<number>('playbackSpeed', 1.0);
    AppStorage.setOrCreate<number>('fastForwardSecs', 30);
    AppStorage.setOrCreate<number>('rewindSecs', 10);
    AppStorage.setOrCreate<boolean>('skipSilence', false);
    AppStorage.setOrCreate<boolean>('showRemainTime', false);
    AppStorage.setOrCreate<boolean>('streamOverDownload', false);
    AppStorage.setOrCreate<boolean>('useEpisodeCover', true);

    // Episode pub date for FullPlayer display
    AppStorage.setOrCreate<string>('currentEpisodePubDate', '');
  }
}
