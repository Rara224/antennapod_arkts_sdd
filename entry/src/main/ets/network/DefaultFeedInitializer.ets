import { hilog } from '@kit.PerformanceAnalysisKit';
import { FeedDao } from '../database/FeedDao';
import { FeedUpdateService } from './FeedUpdateService';

const DOMAIN: number = 0x0000;
const TAG: string = 'DefaultFeedInitializer';

/**
 * On first launch (empty database), subscribe to a set of default podcasts
 * so the user has immediate content to explore — matching the Android version.
 */
export class DefaultFeedInitializer {
  private static readonly DEFAULT_FEEDS: string[] = [
    // 三杯过后
    'https://feed.xyzfm.space/j8yp8gxkmgqr'
  ];

  static async initDefaultFeedsIfEmpty(): Promise<void> {
    const feedDao = new FeedDao();
    const existingFeeds = await feedDao.getAllFeeds();
    if (existingFeeds.length > 0) {
      hilog.info(DOMAIN, TAG, 'Database already has %{public}d feeds, skipping defaults',
        existingFeeds.length);
      return;
    }

    hilog.info(DOMAIN, TAG, 'No feeds found, subscribing to %{public}d default feeds',
      DefaultFeedInitializer.DEFAULT_FEEDS.length);

    const service = new FeedUpdateService();
    for (let i = 0; i < DefaultFeedInitializer.DEFAULT_FEEDS.length; i++) {
      const url = DefaultFeedInitializer.DEFAULT_FEEDS[i];
      try {
        await service.subscribeFeed(url);
        hilog.info(DOMAIN, TAG, 'Subscribed to default feed: %{public}s', url);
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'Failed to subscribe default feed %{public}s: %{public}s',
          url, JSON.stringify(e));
      }
    }

    hilog.info(DOMAIN, TAG, 'Default feed initialization complete');
  }
}
