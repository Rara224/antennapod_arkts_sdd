/**
 * Feed subscription states
 */
export const FEED_STATE_SUBSCRIBED: number = 1;
export const FEED_STATE_NOT_SUBSCRIBED: number = 0;
export const FEED_STATE_ARCHIVED: number = 2;

/**
 * FeedItem play states
 */
export const PLAY_STATE_NEW: number = -1;
export const PLAY_STATE_UNPLAYED: number = 0;
export const PLAY_STATE_PLAYED: number = 1;

/**
 * Sort orders
 */
export const SORT_DATE_NEW_OLD: number = 1;
export const SORT_DATE_OLD_NEW: number = 2;
export const SORT_TITLE_A_Z: number = 3;
export const SORT_TITLE_Z_A: number = 4;
export const SORT_DURATION_SHORT_LONG: number = 5;
export const SORT_DURATION_LONG_SHORT: number = 6;
export const SORT_FEED_TITLE_A_Z: number = 7;
export const SORT_FEED_TITLE_Z_A: number = 8;
export const SORT_RANDOM: number = 9;
export const SORT_SMART_SHUFFLE_OLD_NEW: number = 10;
export const SORT_SMART_SHUFFLE_NEW_OLD: number = 11;
export const SORT_SIZE_SMALL_LARGE: number = 12;
export const SORT_SIZE_LARGE_SMALL: number = 13;
export const SORT_COMPLETION_DATE_NEW_OLD: number = 14;
export const SORT_COMPLETION_DATE_OLD_NEW: number = 15;
export const SORT_EPISODE_NUMBER_DESCENDING: number = 16;

/**
 * Auto-download policy
 */
export const AUTO_DL_DISABLED: number = 0;
export const AUTO_DL_GLOBAL: number = 1;
export const AUTO_DL_ENABLED: number = 2;

/**
 * Auto-delete policy
 */
export const AUTO_DEL_DISABLED: number = 0;
export const AUTO_DEL_GLOBAL: number = 1;
export const AUTO_DEL_ENABLED: number = 2;

/**
 * New episode action
 */
export const NEW_EP_ACTION_GLOBAL: number = 0;
export const NEW_EP_ACTION_ADD_TO_INBOX: number = 1;
export const NEW_EP_ACTION_NOTHING: number = 2;
export const NEW_EP_ACTION_ADD_TO_QUEUE: number = 3;

/**
 * Tab indices (matches Android: Home / Queue / Inbox / Subscriptions / More)
 */
export const TAB_INDEX_HOME: number = 0;
export const TAB_INDEX_QUEUE: number = 1;
export const TAB_INDEX_INBOX: number = 2;
export const TAB_INDEX_SUBSCRIPTIONS: number = 3;
export const TAB_INDEX_MORE: number = 4;

/**
 * Database constants
 */
export const DB_NAME: string = 'antennapod.db';
export const DB_VERSION: number = 1;

/**
 * Player status
 */
export const PLAYER_STATUS_STOPPED: number = 0;
export const PLAYER_STATUS_PLAYING: number = 1;
export const PLAYER_STATUS_PAUSED: number = 2;
export const PLAYER_STATUS_PREPARING: number = 3;

/**
 * Download error codes
 */
export const DOWNLOAD_ERROR_SUCCESS: number = 0;
export const DOWNLOAD_ERROR_UNKNOWN: number = 1;
export const DOWNLOAD_ERROR_IO: number = 2;
export const DOWNLOAD_ERROR_UNAUTHORIZED: number = 3;
export const DOWNLOAD_ERROR_HTTP_DATA: number = 4;
export const DOWNLOAD_ERROR_DEVICE_NOT_FOUND: number = 5;
export const DOWNLOAD_ERROR_CONNECTION: number = 6;
export const DOWNLOAD_ERROR_NOT_ENOUGH_SPACE: number = 7;

/**
 * Feed file types
 */
export const FEED_FILE_FEED: number = 0;
export const FEED_FILE_FEED_MEDIA: number = 2;

/**
 * Volume adaption
 */
export const VOLUME_ADAPTION_OFF: number = 0;
export const VOLUME_ADAPTION_LIGHT_REDUCTION: number = 1;
export const VOLUME_ADAPTION_HEAVY_REDUCTION: number = 2;
export const VOLUME_ADAPTION_LIGHT_BOOST: number = 3;
export const VOLUME_ADAPTION_MEDIUM_BOOST: number = 4;
export const VOLUME_ADAPTION_HEAVY_BOOST: number = 5;

/**
 * Skip silence
 */
export const SKIP_SILENCE_OFF: number = 0;
export const SKIP_SILENCE_GLOBAL: number = 1;
export const SKIP_SILENCE_AGGRESSIVE: number = 2;

/**
 * Feed types
 */
export const FEED_TYPE_RSS: string = 'RSS2';
export const FEED_TYPE_ATOM: string = 'Atom';

/**
 * Table names
 */
export const TABLE_FEEDS: string = 'Feeds';
export const TABLE_FEED_ITEMS: string = 'FeedItems';
export const TABLE_FEED_MEDIA: string = 'FeedMedia';
export const TABLE_SIMPLE_CHAPTERS: string = 'SimpleChapters';
export const TABLE_DOWNLOAD_LOG: string = 'DownloadLog';
export const TABLE_QUEUE: string = 'Queue';
export const TABLE_FAVORITES: string = 'Favorites';

/**
 * Enqueue location
 */
export const ENQUEUE_AT_FRONT: number = 0;
export const ENQUEUE_AT_BACK: number = 1;
export const ENQUEUE_AFTER_CURRENT: number = 2;

/**
 * Theme modes
 */
export const THEME_SYSTEM: number = 0;
export const THEME_LIGHT: number = 1;
export const THEME_DARK: number = 2;
