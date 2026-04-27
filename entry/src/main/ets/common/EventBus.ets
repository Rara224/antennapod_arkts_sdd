/**
 * Event name constants
 */
export const EVENT_PLAYER_STATUS: string = 'event_player_status';
export const EVENT_PLAYBACK_POSITION: string = 'event_playback_position';
export const EVENT_PLAYBACK_SPEED: string = 'event_playback_speed';
export const EVENT_QUEUE_CHANGED: string = 'event_queue_changed';
export const EVENT_FEED_LIST_CHANGED: string = 'event_feed_list_changed';
export const EVENT_FEED_UPDATED: string = 'event_feed_updated';
export const EVENT_EPISODE_DOWNLOADED: string = 'event_episode_downloaded';
export const EVENT_DOWNLOAD_PROGRESS: string = 'event_download_progress';
export const EVENT_DOWNLOAD_FAILED: string = 'event_download_failed';
export const EVENT_UNREAD_COUNT_CHANGED: string = 'event_unread_count_changed';
export const EVENT_FAVORITES_CHANGED: string = 'event_favorites_changed';
export const EVENT_SUBSCRIPTION_ADDED: string = 'event_subscription_added';
export const EVENT_SUBSCRIPTION_REMOVED: string = 'event_subscription_removed';
export const EVENT_FEED_UPDATE_RUNNING: string = 'event_feed_update_running';
export const EVENT_SLEEP_TIMER: string = 'event_sleep_timer';
export const EVENT_PLAYBACK_HISTORY_CHANGED: string = 'event_playback_history_changed';
export const EVENT_SKIP_INTRO_END_CHANGED: string = 'event_skip_intro_end_changed';
export const EVENT_EPISODE_PLAY_STATE_CHANGED: string = 'event_episode_play_state_changed';
export const EVENT_SWIPE_ACTION: string = 'event_swipe_action';
export const EVENT_THEME_CHANGED: string = 'event_theme_changed';
export const EVENT_BUFFER_UPDATE: string = 'event_buffer_update';
export const EVENT_PLAYBACK_SERVICE: string = 'event_playback_service';
export const EVENT_PLAYER_ERROR: string = 'event_player_error';
export const EVENT_DOWNLOAD_LOG: string = 'event_download_log';
export const EVENT_STATISTICS: string = 'event_statistics';
export const EVENT_MESSAGE: string = 'event_message';
export const EVENT_SPEED_PRESET: string = 'event_speed_preset';
export const EVENT_VOLUME_ADAPTION: string = 'event_volume_adaption';
export const EVENT_INBOX_CHANGED: string = 'event_inbox_changed';

/**
 * Publish-subscribe event bus singleton
 */
export class EventBus {
  private static instance: EventBus | undefined = undefined;
  private listeners: Map<string, ((data: Object) => void)[]> = new Map();

  private constructor() {
  }

  static getInstance(): EventBus {
    if (EventBus.instance === undefined) {
      EventBus.instance = new EventBus();
    }
    return EventBus.instance;
  }

  subscribe(event: string, callback: (data: Object) => void): () => void {
    let list = this.listeners.get(event);
    if (list === undefined) {
      list = [];
      this.listeners.set(event, list);
    }
    list.push(callback);
    return (): void => {
      this.unsubscribe(event, callback);
    };
  }

  unsubscribe(event: string, callback: (data: Object) => void): void {
    const list = this.listeners.get(event);
    if (list === undefined) {
      return;
    }
    const index = list.indexOf(callback);
    if (index >= 0) {
      list.splice(index, 1);
    }
  }

  publish(event: string, data: Object): void {
    const list = this.listeners.get(event);
    if (list === undefined) {
      return;
    }
    for (let i = 0; i < list.length; i++) {
      list[i](data);
    }
  }

  clear(event: string): void {
    this.listeners.delete(event);
  }

  clearAll(): void {
    this.listeners.clear();
  }
}
