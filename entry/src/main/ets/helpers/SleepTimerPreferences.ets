import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'SleepTimerPreferences';
const PREFS_NAME: string = 'sleep_timer_prefs';

const KEY_LAST_TIMER_VALUE: string = 'lastTimerValue';
const KEY_SHAKE_TO_RESET: string = 'shakeToReset';
const KEY_VIBRATE: string = 'vibrate';
const KEY_AUTO_ENABLE: string = 'autoEnable';
const KEY_TIMER_LAST_START: string = 'timerLastStart';

/**
 * Sleep timer preferences.
 */
export class SleepTimerPreferences {
  private static instance: SleepTimerPreferences | undefined = undefined;
  private prefs: preferences.Preferences | undefined = undefined;

  static getInstance(): SleepTimerPreferences {
    if (SleepTimerPreferences.instance === undefined) {
      SleepTimerPreferences.instance = new SleepTimerPreferences();
    }
    return SleepTimerPreferences.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.prefs !== undefined) {
      return;
    }
    hilog.info(DOMAIN, TAG, 'Initializing SleepTimerPreferences...');
    this.prefs = await preferences.getPreferences(context, PREFS_NAME);
    hilog.info(DOMAIN, TAG, 'SleepTimerPreferences initialized.');
  }

  private getInt(key: string, def: number): number {
    if (this.prefs === undefined) {
      return def;
    }
    const val = this.prefs.getSync(key, def);
    if (typeof val === 'number') {
      return val;
    }
    return def;
  }

  private getBoolean(key: string, def: boolean): boolean {
    if (this.prefs === undefined) {
      return def;
    }
    const val = this.prefs.getSync(key, def);
    if (typeof val === 'boolean') {
      return val;
    }
    return def;
  }

  /** Last timer value in minutes */
  getLastTimerValue(): number {
    return this.getInt(KEY_LAST_TIMER_VALUE, 15);
  }

  async setLastTimerValue(minutes: number): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_LAST_TIMER_VALUE, minutes);
    await this.prefs.flush();
  }

  isShakeToReset(): boolean {
    return this.getBoolean(KEY_SHAKE_TO_RESET, true);
  }

  async setShakeToReset(value: boolean): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_SHAKE_TO_RESET, value);
    await this.prefs.flush();
  }

  isVibrate(): boolean {
    return this.getBoolean(KEY_VIBRATE, true);
  }

  async setVibrate(value: boolean): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_VIBRATE, value);
    await this.prefs.flush();
  }

  isAutoEnable(): boolean {
    return this.getBoolean(KEY_AUTO_ENABLE, false);
  }

  async setAutoEnable(value: boolean): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_AUTO_ENABLE, value);
    await this.prefs.flush();
  }

  /** Timestamp of last timer start */
  getTimerLastStart(): number {
    return this.getInt(KEY_TIMER_LAST_START, 0);
  }

  async setTimerLastStart(timestamp: number): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_TIMER_LAST_START, timestamp);
    await this.prefs.flush();
  }
}
