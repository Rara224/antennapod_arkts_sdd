import {
  AUTO_DL_GLOBAL,
  AUTO_DEL_GLOBAL,
  NEW_EP_ACTION_GLOBAL,
  SKIP_SILENCE_GLOBAL,
  VOLUME_ADAPTION_OFF
} from '../common/Constants';

/**
 * Per-feed preferences. Stored in the Feeds table alongside Feed columns.
 */
export class FeedPreferences {
  /** -1 = use global playback speed */
  feedPlaybackSpeed: number = -1;
  /** 0=OFF, 1=GLOBAL, 2=AGGRESSIVE */
  feedSkipSilence: number = SKIP_SILENCE_GLOBAL;
  volumeAdaptionSetting: number = VOLUME_ADAPTION_OFF;
  /** 0=DISABLED, 1=GLOBAL, 2=ENABLED */
  autoDownload: number = AUTO_DL_GLOBAL;
  /** 0=GLOBAL, 1=ALWAYS, 2=NEVER */
  autoDeleteAction: number = AUTO_DEL_GLOBAL;
  /** 0=GLOBAL, 1=ADD_TO_INBOX, 2=NOTHING, 3=ADD_TO_QUEUE */
  newEpisodesAction: number = NEW_EP_ACTION_GLOBAL;
  username: string = '';
  password: string = '';
  keepUpdated: boolean = true;
  includeFilter: string = '';
  excludeFilter: string = '';
  /** -1 = disabled */
  minimalDurationFilter: number = -1;
  tags: Set<string> = new Set<string>();
  /** seconds to skip at episode start */
  feedSkipIntro: number = 0;
  /** seconds to skip at episode end */
  feedSkipEnding: number = 0;
  episodeNotification: boolean = false;
}
