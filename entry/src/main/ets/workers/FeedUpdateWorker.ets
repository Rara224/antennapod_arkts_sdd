import { workScheduler } from '@kit.BackgroundTasksKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'FeedUpdateWorker';
const WORK_ID: number = 1001;
const REPEAT_CYCLE_MS: number = 2 * 60 * 60 * 1000; // 2 hours

export class FeedUpdateWorker {
  static registerPeriodicRefresh(): void {
    const workInfo: workScheduler.WorkInfo = {
      workId: WORK_ID,
      bundleName: 'com.example.antennapod_arkts',
      abilityName: 'FeedUpdateWorkAbility',
      isRepeat: true,
      repeatCycleTime: REPEAT_CYCLE_MS,
      networkType: workScheduler.NetworkType.NETWORK_TYPE_ANY,
      isPersisted: true
    };

    try {
      workScheduler.startWork(workInfo);
      hilog.info(DOMAIN, TAG, 'Periodic feed refresh registered, cycle=%{public}d ms', REPEAT_CYCLE_MS);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to register periodic refresh: %{public}s', JSON.stringify(e));
    }
  }

  static cancelPeriodicRefresh(): void {
    try {
      workScheduler.stopWork({ workId: WORK_ID, bundleName: 'com.example.antennapod_arkts',
        abilityName: 'FeedUpdateWorkAbility' });
      hilog.info(DOMAIN, TAG, 'Periodic feed refresh cancelled');
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Failed to cancel periodic refresh: %{public}s', JSON.stringify(e));
    }
  }
}
