// ==================== 播放器相关 ====================

export class PlaybackPositionData {
  position: number = 0;
  duration: number = 0;

  constructor(position: number, duration: number) {
    this.position = position;
    this.duration = duration;
  }
}

export class SpeedChangedData {
  newSpeed: number = 1.0;

  constructor(newSpeed: number) {
    this.newSpeed = newSpeed;
  }
}

export class BufferUpdateData {
  progress: number = 0;

  constructor(progress: number) {
    this.progress = progress;
  }
}

export class PlayerErrorData {
  message: string = '';

  constructor(message: string) {
    this.message = message;
  }
}

export class SleepTimerData {
  timeLeft: number = 0;
  isRunning: boolean = false;

  constructor(timeLeft: number, isRunning: boolean) {
    this.timeLeft = timeLeft;
    this.isRunning = isRunning;
  }
}

export class PlaybackServiceData {
  action: number = 0;
  static readonly ACTION_START: number = 0;
  static readonly ACTION_STOP: number = 1;

  constructor(action: number) {
    this.action = action;
  }
}

// ==================== Feed/Episode 相关 ====================

export class FeedListUpdateData {
  feedIds: number[] = [];

  constructor(feedIds: number[]) {
    this.feedIds = feedIds;
  }
}

export class FeedItemData {
  itemIds: number[] = [];

  constructor(itemIds: number[]) {
    this.itemIds = itemIds;
  }
}

export class FeedEventData {
  action: number = 0;
  feedId: number = 0;

  constructor(action: number, feedId: number) {
    this.action = action;
    this.feedId = feedId;
  }
}

export class QueueEventData {
  action: number = 0;
  itemId: number = 0;
  position: number = 0;
  static readonly ACTION_ADDED: number = 0;
  static readonly ACTION_REMOVED: number = 1;
  static readonly ACTION_SORTED: number = 2;
  static readonly ACTION_MOVED: number = 3;

  constructor(action: number, itemId: number, position: number) {
    this.action = action;
    this.itemId = itemId;
    this.position = position;
  }
}

export class UnreadCountData {
  count: number = 0;

  constructor(count: number) {
    this.count = count;
  }
}

export class FavoritesChangedData {
  itemId: number = 0;
  isFavorite: boolean = false;

  constructor(itemId: number, isFavorite: boolean) {
    this.itemId = itemId;
    this.isFavorite = isFavorite;
  }
}

export class SubscriptionAddedData {
  feedId: number = 0;

  constructor(feedId: number) {
    this.feedId = feedId;
  }
}

export class SubscriptionRemovedData {
  feedId: number = 0;

  constructor(feedId: number) {
    this.feedId = feedId;
  }
}

// ==================== 下载相关 ====================

export class EpisodeDownloadData {
  downloadUrls: Map<string, number> = new Map();

  constructor(downloadUrls: Map<string, number>) {
    this.downloadUrls = downloadUrls;
  }
}

export class DownloadProgressData {
  episodeId: number = 0;
  percent: number = 0;

  constructor(episodeId: number, percent: number) {
    this.episodeId = episodeId;
    this.percent = percent;
  }
}

export class DownloadFailedData {
  episodeId: number = 0;
  errorCode: number = 0;

  constructor(episodeId: number, errorCode: number) {
    this.episodeId = episodeId;
    this.errorCode = errorCode;
  }
}

export class DownloadLogData {
  episodeId: number = 0;
  success: boolean = false;

  constructor(episodeId: number, success: boolean) {
    this.episodeId = episodeId;
    this.success = success;
  }
}

// ==================== 设置相关 ====================

export class SkipIntroEndData {
  skipIntro: number = 0;
  skipEnding: number = 0;
  feedId: number = 0;

  constructor(skipIntro: number, skipEnding: number, feedId: number) {
    this.skipIntro = skipIntro;
    this.skipEnding = skipEnding;
    this.feedId = feedId;
  }
}

export class SpeedPresetData {
  speed: number = 1.0;
  skipSilence: boolean = false;
  feedId: number = 0;

  constructor(speed: number, skipSilence: boolean, feedId: number) {
    this.speed = speed;
    this.skipSilence = skipSilence;
    this.feedId = feedId;
  }
}

export class VolumeAdaptionData {
  setting: number = 0;
  feedId: number = 0;

  constructor(setting: number, feedId: number) {
    this.setting = setting;
    this.feedId = feedId;
  }
}

// ==================== UI/消息 ====================

export class MessageEventData {
  message: string = '';
  actionText: string = '';

  constructor(message: string, actionText: string) {
    this.message = message;
    this.actionText = actionText;
  }
}

export class EpisodePlayStateData {
  itemId: number = 0;
  playState: number = 0;

  constructor(itemId: number, playState: number) {
    this.itemId = itemId;
    this.playState = playState;
  }
}

export class FeedUpdateRunningData {
  isRunning: boolean = false;

  constructor(isRunning: boolean) {
    this.isRunning = isRunning;
  }
}

export class SwipeActionData {
  itemId: number = 0;
  action: number = 0;

  constructor(itemId: number, action: number) {
    this.itemId = itemId;
    this.action = action;
  }
}

export class ThemeChangedData {
  themeMode: number = 0;

  constructor(themeMode: number) {
    this.themeMode = themeMode;
  }
}

export class StatisticsData {
  static readonly ACTION_REFRESH: number = 0;

  action: number = 0;

  constructor(action: number) {
    this.action = action;
  }
}

export class PlaybackHistoryData {
  static readonly ACTION_REFRESH: number = 0;

  action: number = 0;

  constructor(action: number) {
    this.action = action;
  }
}

export class PlayerStatusData {
  status: number = 0;

  constructor(status: number) {
    this.status = status;
  }
}
