import { WorkSchedulerExtensionAbility, workScheduler } from '@kit.BackgroundTasksKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FeedUpdateService } from '../network/FeedUpdateService';

const DOMAIN: number = 0x0000;
const TAG: string = 'FeedUpdateWorkAbility';

export default class FeedUpdateWorkAbility extends WorkSchedulerExtensionAbility {
  onWorkStart(work: workScheduler.WorkInfo): void {
    hilog.info(DOMAIN, TAG, 'Feed update work started, workId=%{public}d', work.workId);
    const service = new FeedUpdateService();
    service.refreshAllFeeds().then(() => {
      hilog.info(DOMAIN, TAG, 'Feed update work completed');
    }).catch((e: Error) => {
      hilog.error(DOMAIN, TAG, 'Feed update work failed: %{public}s', e.message);
    });
  }

  onWorkStop(work: workScheduler.WorkInfo): void {
    hilog.info(DOMAIN, TAG, 'Feed update work stopped, workId=%{public}d', work.workId);
  }
}
