import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { PlaybackController } from '../playback/PlaybackController';
import { FeedUpdateWorker } from '../workers/FeedUpdateWorker';
import { GlobalState } from '../common/GlobalState';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'AntennaPod', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'AntennaPod', '%{public}s', 'Ability onCreate');

    // Store UIAbilityContext for openLink support
    GlobalState.setAbilityContext(this.context);

    // Register periodic feed refresh (every 2 hours)
    FeedUpdateWorker.registerPeriodicRefresh();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'AntennaPod', '%{public}s', 'Ability onDestroy');
    PlaybackController.getInstance().release();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'AntennaPod', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'AntennaPod', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'AntennaPod', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'AntennaPod', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'AntennaPod', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'AntennaPod', '%{public}s', 'Ability onBackground');
  }
}