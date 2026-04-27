import { SettingsDetailParam } from '../../common/AppRouter';
import { UserPreferences } from '../../helpers/UserPreferences';
import {
  THEME_SYSTEM,
  THEME_LIGHT,
  THEME_DARK,
  ENQUEUE_AT_FRONT,
  ENQUEUE_AT_BACK,
  ENQUEUE_AFTER_CURRENT
} from '../../common/Constants';

@Component
export struct SettingsDetailComponent {
  @State category: string = '';
  @State pageTitle: string = '';
  @StorageLink('themeMode') themeMode: number = THEME_SYSTEM;
  @StorageLink('useEpisodeCover') useEpisodeCover: boolean = true;
  @StorageLink('playbackSpeed') playbackSpeed: number = 1.0;
  @StorageLink('fastForwardSecs') fastForwardSecs: number = 30;
  @StorageLink('rewindSecs') rewindSecs: number = 10;
  @StorageLink('skipSilence') skipSilence: boolean = false;
  @StorageLink('streamOverDownload') streamOverDownload: boolean = false;
  @StorageLink('enqueueDownloaded') enqueueDownloaded: boolean = true;
  @StorageLink('enqueueLocation') enqueueLocation: number = ENQUEUE_AT_BACK;
  @StorageLink('showRemainTime') showRemainTime: boolean = false;
  @State autoDownload: boolean = false;
  @State deleteWhenPlayed: boolean = false;

  aboutToAppear(): void {
    const prefs = UserPreferences.getInstance();
    this.autoDownload = prefs.isEnableAutodownload();
    this.deleteWhenPlayed = prefs.isDeleteWhenPlayed();
  }

  private getThemeLabel(): string {
    if (this.themeMode === THEME_LIGHT) {
      return 'Light';
    } else if (this.themeMode === THEME_DARK) {
      return 'Dark';
    }
    return 'System';
  }

  private getEnqueueLabel(): string {
    if (this.enqueueLocation === ENQUEUE_AT_FRONT) {
      return 'Front';
    } else if (this.enqueueLocation === ENQUEUE_AFTER_CURRENT) {
      return 'After current';
    }
    return 'Back';
  }

  @Builder
  settingValue(title: string, value: string, onClick: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor('#1565C0')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(onClick)
  }

  @Builder
  settingToggle(title: string, subtitle: string, isOn: boolean, onChange: (v: boolean) => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#333333')
        if (subtitle.length > 0) {
          Text(subtitle)
            .fontSize(13)
            .fontColor('#99000000')
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  sectionHeader(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#1565C0')
      .padding({ left: 16, top: 20, bottom: 8 })
      .width('100%')
  }

  @Builder
  uiSettings() {
    ListItem() {
      this.settingValue('Theme', this.getThemeLabel(), () => {
        let next: number = THEME_SYSTEM;
        if (this.themeMode === THEME_SYSTEM) {
          next = THEME_LIGHT;
        } else if (this.themeMode === THEME_LIGHT) {
          next = THEME_DARK;
        }
        this.themeMode = next;
        UserPreferences.getInstance().setThemeMode(next);
      })
    }

    ListItem() {
      this.settingToggle('Show Episode Cover', 'Display episode-specific artwork', this.useEpisodeCover,
        (isOn: boolean) => {
          this.useEpisodeCover = isOn;
          UserPreferences.getInstance().setUseEpisodeCover(isOn);
        })
    }

    ListItem() {
      this.settingToggle('Show Remaining Time', 'Show remaining time instead of total duration',
        this.showRemainTime, (isOn: boolean) => {
          this.showRemainTime = isOn;
          UserPreferences.getInstance().setShowRemainTime(isOn);
        })
    }
  }

  @Builder
  playbackSettings() {
    ListItem() {
      this.settingValue('Playback Speed', this.playbackSpeed.toFixed(1) + 'x', () => {
        let next = this.playbackSpeed + 0.1;
        if (next > 2.0) {
          next = 0.5;
        }
        const rounded = Math.round(next * 10) / 10;
        this.playbackSpeed = rounded;
        UserPreferences.getInstance().setPlaybackSpeed(rounded);
      })
    }

    ListItem() {
      this.settingValue('Fast Forward (seconds)', this.fastForwardSecs.toString() + 's', () => {
        let next = this.fastForwardSecs + 5;
        if (next > 60) {
          next = 10;
        }
        this.fastForwardSecs = next;
        UserPreferences.getInstance().setFastForwardSecs(next);
      })
    }

    ListItem() {
      this.settingValue('Rewind (seconds)', this.rewindSecs.toString() + 's', () => {
        let next = this.rewindSecs + 5;
        if (next > 60) {
          next = 5;
        }
        this.rewindSecs = next;
        UserPreferences.getInstance().setRewindSecs(next);
      })
    }

    ListItem() {
      this.settingToggle('Skip Silence', 'Automatically skip silent parts in audio', this.skipSilence,
        (isOn: boolean) => {
          this.skipSilence = isOn;
          UserPreferences.getInstance().setSkipSilence(isOn);
        })
    }

    ListItem() {
      this.sectionHeader('Queue')
    }

    ListItem() {
      this.settingValue('Enqueue Position', this.getEnqueueLabel(), () => {
        let next: number = ENQUEUE_AT_BACK;
        if (this.enqueueLocation === ENQUEUE_AT_BACK) {
          next = ENQUEUE_AT_FRONT;
        } else if (this.enqueueLocation === ENQUEUE_AT_FRONT) {
          next = ENQUEUE_AFTER_CURRENT;
        }
        this.enqueueLocation = next;
        UserPreferences.getInstance().setEnqueueLocation(next);
      })
    }

    ListItem() {
      this.settingToggle('Enqueue Downloaded', 'Automatically add downloaded episodes to queue',
        this.enqueueDownloaded, (isOn: boolean) => {
          this.enqueueDownloaded = isOn;
          UserPreferences.getInstance().setEnqueueDownloaded(isOn);
        })
    }
  }

  @Builder
  downloadSettings() {
    ListItem() {
      this.settingToggle('Prefer Streaming', 'Stream episodes instead of downloading',
        this.streamOverDownload, (isOn: boolean) => {
          this.streamOverDownload = isOn;
          UserPreferences.getInstance().setStreamOverDownload(isOn);
        })
    }

    ListItem() {
      this.settingToggle('Auto Download', 'Automatically download new episodes', this.autoDownload,
        (isOn: boolean) => {
          this.autoDownload = isOn;
          UserPreferences.getInstance().setEnableAutodownload(isOn);
        })
    }

    ListItem() {
      this.settingToggle('Delete After Playing', 'Remove downloaded episodes after playback',
        this.deleteWhenPlayed, (isOn: boolean) => {
          this.deleteWhenPlayed = isOn;
          UserPreferences.getInstance().setDeleteWhenPlayed(isOn);
        })
    }
  }

  @Builder
  syncSettings() {
    ListItem() {
      Row() {
        Text('Synchronization is not yet available in this version.')
          .fontSize(14)
          .fontColor('#99000000')
      }
      .width('100%')
      .padding(16)
    }
  }

  @Builder
  backupSettings() {
    ListItem() {
      Row() {
        Text('Backup & restore is not yet available in this version.')
          .fontSize(14)
          .fontColor('#99000000')
      }
      .width('100%')
      .padding(16)
    }
  }

  @Builder
  notificationSettings() {
    ListItem() {
      Row() {
        Text('Notification settings are not yet available in this version.')
          .fontSize(14)
          .fontColor('#99000000')
      }
      .width('100%')
      .padding(16)
    }
  }

  build() {
    NavDestination() {
      List() {
        if (this.category === 'ui') {
          this.uiSettings()
        } else if (this.category === 'playback') {
          this.playbackSettings()
        } else if (this.category === 'downloads') {
          this.downloadSettings()
        } else if (this.category === 'sync') {
          this.syncSettings()
        } else if (this.category === 'backup') {
          this.backupSettings()
        } else if (this.category === 'notifications') {
          this.notificationSettings()
        }
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 16, endMargin: 16 })
    }
    .title(this.pageTitle)
    .onReady((ctx: NavDestinationContext) => {
      if (ctx.pathInfo.param instanceof SettingsDetailParam) {
        const p: SettingsDetailParam = ctx.pathInfo.param;
        this.category = p.category;
        const titles: Record<string, string> = {
          'ui': 'User interface',
          'playback': 'Playback',
          'downloads': 'Downloads',
          'sync': 'Synchronization',
          'backup': 'Backup & restore',
          'notifications': 'Notifications'
        };
        this.pageTitle = titles[this.category] !== undefined ? titles[this.category] : 'Settings';
      }
    })
  }
}
