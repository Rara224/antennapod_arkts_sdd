/**
 * Route name constants for Navigation
 */
export class RouteName {
  static readonly HOME: string = 'home';
  static readonly SUBSCRIPTIONS: string = 'subscriptions';
  static readonly QUEUE: string = 'queue';
  static readonly EPISODES: string = 'episodes';
  static readonly SEARCH: string = 'search';
  static readonly FEED_DETAIL: string = 'feedDetail';
  static readonly EPISODE_DETAIL: string = 'episodeDetail';
  static readonly FEED_SETTINGS: string = 'feedSettings';
  static readonly FEED_INFO: string = 'feedInfo';
  static readonly ONLINE_FEED_VIEW: string = 'onlineFeedView';
  static readonly ADD_FEED: string = 'addFeed';
  static readonly PLAYBACK_HISTORY: string = 'playbackHistory';
  static readonly DOWNLOADS: string = 'downloads';
  static readonly STATISTICS: string = 'statistics';
  static readonly SETTINGS: string = 'settings';
  static readonly VIDEO_PLAYER: string = 'videoPlayer';
  static readonly OPML_IMPORT: string = 'opmlImport';
  static readonly FULL_PLAYER: string = 'fullPlayer';
  static readonly INBOX: string = 'inbox';
  static readonly SETTINGS_DETAIL: string = 'settingsDetail';
  static readonly SETTINGS_SEARCH: string = 'settingsSearch';
  static readonly SEARCH_PODCASTS: string = 'searchPodcasts';
}

/**
 * Navigation parameter types
 */
export class FeedDetailParam {
  feedId: number = 0;
}

export class EpisodeDetailParam {
  episodeId: number = 0;
  feedId: number = 0;
}

export class FeedSettingsParam {
  feedId: number = 0;
}

export class FeedInfoParam {
  feedId: number = 0;
}

export class OnlineFeedViewParam {
  feedUrl: string = '';
}

export class VideoPlayerParam {
  episodeId: number = 0;
}

export class OpmlImportParam {
  filePath: string = '';
}

export class FullPlayerParam {
  // No params needed — reads from AppStorage
}

export class SettingsDetailParam {
  category: string = '';
}

export class SearchPodcastsParam {
  provider: number = 0; // 0=Apple, 1=fyyd, 2=Podcast Index
}
