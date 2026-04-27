import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'PermissionHelper';

export class PermissionHelper {
  static checkPermission(permission: Permissions): boolean {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const tokenId = bundleInfo.appInfo.accessTokenId;
      const atManager = abilityAccessCtrl.createAtManager();
      const result = atManager.checkAccessTokenSync(tokenId, permission);
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'checkPermission error: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  static async requestPermissions(
    context: common.UIAbilityContext,
    permissions: Permissions[]
  ): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      for (let i = 0; i < result.authResults.length; i++) {
        if (result.authResults[i] !== 0) {
          hilog.warn(DOMAIN, TAG, 'Permission denied: %{public}s', permissions[i]);
          return false;
        }
      }
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'requestPermissions error: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  static async checkAndRequest(
    context: common.UIAbilityContext,
    permissions: Permissions[]
  ): Promise<boolean> {
    const notGranted: Permissions[] = [];
    for (let i = 0; i < permissions.length; i++) {
      if (!PermissionHelper.checkPermission(permissions[i])) {
        notGranted.push(permissions[i]);
      }
    }
    if (notGranted.length === 0) {
      return true;
    }
    return await PermissionHelper.requestPermissions(context, notGranted);
  }
}
