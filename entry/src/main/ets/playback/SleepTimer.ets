import { hilog } from '@kit.PerformanceAnalysisKit';
import { EventBus, EVENT_SLEEP_TIMER } from '../common/EventBus';
import { SleepTimerData } from '../common/EventData';
import { SleepTimerPreferences } from '../helpers/SleepTimerPreferences';

const DOMAIN: number = 0x0000;
const TAG: string = 'SleepTimer';
const TICK_INTERVAL_MS: number = 1000;

export class SleepTimer {
  private static instance: SleepTimer | undefined = undefined;
  private timerId: number = -1;
  private endTimeMs: number = 0;
  private running: boolean = false;
  private onTimerExpired: (() => Promise<void>) | undefined = undefined;

  static getInstance(): SleepTimer {
    if (SleepTimer.instance === undefined) {
      SleepTimer.instance = new SleepTimer();
    }
    return SleepTimer.instance;
  }

  setOnTimerExpired(callback: () => Promise<void>): void {
    this.onTimerExpired = callback;
  }

  start(minutes: number): void {
    this.cancel();
    this.endTimeMs = Date.now() + minutes * 60 * 1000;
    this.running = true;
    SleepTimerPreferences.getInstance().setLastTimerValue(minutes);
    SleepTimerPreferences.getInstance().setTimerLastStart(Date.now());
    this.timerId = setInterval((): void => {
      this.tick();
    }, TICK_INTERVAL_MS);
    hilog.info(DOMAIN, TAG, 'Sleep timer started: %{public}d minutes', minutes);
    this.publishState();
  }

  extend(minutes: number): void {
    if (!this.running) {
      this.start(minutes);
      return;
    }
    this.endTimeMs += minutes * 60 * 1000;
    hilog.info(DOMAIN, TAG, 'Sleep timer extended by %{public}d minutes', minutes);
    this.publishState();
  }

  cancel(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.running = false;
    this.endTimeMs = 0;
    this.publishState();
  }

  getTimeLeft(): number {
    if (!this.running) {
      return 0;
    }
    const left = this.endTimeMs - Date.now();
    return left > 0 ? left : 0;
  }

  isRunning(): boolean {
    return this.running;
  }

  private tick(): void {
    const timeLeft = this.getTimeLeft();
    this.publishState();
    if (timeLeft <= 0) {
      hilog.info(DOMAIN, TAG, 'Sleep timer expired');
      this.cancel();
      if (this.onTimerExpired !== undefined) {
        this.onTimerExpired();
      }
    }
  }

  private publishState(): void {
    EventBus.getInstance().publish(
      EVENT_SLEEP_TIMER,
      new SleepTimerData(this.getTimeLeft(), this.running)
    );
  }
}
