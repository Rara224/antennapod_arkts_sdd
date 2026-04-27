import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'SyncCredentials';
const PREFS_NAME: string = 'sync_credentials';

const KEY_USERNAME: string = 'syncUsername';
const KEY_PASSWORD: string = 'syncPassword';
const KEY_DEVICE_ID: string = 'syncDeviceId';
const KEY_HOST_URL: string = 'syncHostUrl';

/**
 * gpodder/Nextcloud sync credentials (V2 stub).
 * All getters return empty/default values until V2 sync is implemented.
 */
export class SyncCredentials {
  private static instance: SyncCredentials | undefined = undefined;
  private prefs: preferences.Preferences | undefined = undefined;

  static getInstance(): SyncCredentials {
    if (SyncCredentials.instance === undefined) {
      SyncCredentials.instance = new SyncCredentials();
    }
    return SyncCredentials.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.prefs !== undefined) {
      return;
    }
    hilog.info(DOMAIN, TAG, 'Initializing SyncCredentials...');
    this.prefs = await preferences.getPreferences(context, PREFS_NAME);
    hilog.info(DOMAIN, TAG, 'SyncCredentials initialized.');
  }

  private getString(key: string, def: string): string {
    if (this.prefs === undefined) {
      return def;
    }
    const val = this.prefs.getSync(key, def);
    if (typeof val === 'string') {
      return val;
    }
    return def;
  }

  getUsername(): string {
    return this.getString(KEY_USERNAME, '');
  }

  async setUsername(username: string): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_USERNAME, username);
    await this.prefs.flush();
  }

  getPassword(): string {
    return this.getString(KEY_PASSWORD, '');
  }

  async setPassword(password: string): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_PASSWORD, password);
    await this.prefs.flush();
  }

  getDeviceId(): string {
    return this.getString(KEY_DEVICE_ID, '');
  }

  async setDeviceId(deviceId: string): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_DEVICE_ID, deviceId);
    await this.prefs.flush();
  }

  getHostUrl(): string {
    return this.getString(KEY_HOST_URL, '');
  }

  async setHostUrl(hostUrl: string): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.put(KEY_HOST_URL, hostUrl);
    await this.prefs.flush();
  }

  /**
   * Clear all sync credentials.
   */
  async clear(): Promise<void> {
    if (this.prefs === undefined) {
      return;
    }
    await this.prefs.clear();
    await this.prefs.flush();
  }
}
