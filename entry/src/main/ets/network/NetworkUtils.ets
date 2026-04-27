import { connection } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'NetworkUtils';

export class NetworkUtils {
  static async isNetworkAvailable(): Promise<boolean> {
    try {
      const hasNet = await connection.hasDefaultNet();
      return hasNet;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'isNetworkAvailable error: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  static async isWifiConnected(): Promise<boolean> {
    try {
      const netHandle = await connection.getDefaultNet();
      const caps = await connection.getNetCapabilities(netHandle);
      if (caps.bearerTypes === undefined) {
        return false;
      }
      return caps.bearerTypes.indexOf(connection.NetBearType.BEARER_WIFI) >= 0;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'isWifiConnected error: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  static async isCellularConnected(): Promise<boolean> {
    try {
      const netHandle = await connection.getDefaultNet();
      const caps = await connection.getNetCapabilities(netHandle);
      if (caps.bearerTypes === undefined) {
        return false;
      }
      return caps.bearerTypes.indexOf(connection.NetBearType.BEARER_CELLULAR) >= 0;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'isCellularConnected error: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  static async isNetworkMetered(): Promise<boolean> {
    try {
      const isCellular = await NetworkUtils.isCellularConnected();
      return isCellular;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'isNetworkMetered error: %{public}s', JSON.stringify(e));
      return true;
    }
  }

  static async isAutoDownloadAllowed(): Promise<boolean> {
    // V1: WiFi 连接时允许自动下载
    // Phase 4 接入 UserPreferences 后可配置
    return await NetworkUtils.isWifiConnected();
  }

  static registerNetworkCallback(onChange: (available: boolean) => void): connection.NetConnection {
    const netConn = connection.createNetConnection();
    netConn.register((error) => {
      if (error) {
        hilog.error(DOMAIN, TAG, 'registerNetworkCallback error: %{public}s', JSON.stringify(error));
      }
    });
    netConn.on('netAvailable', () => {
      onChange(true);
    });
    netConn.on('netLost', () => {
      onChange(false);
    });
    return netConn;
  }
}
