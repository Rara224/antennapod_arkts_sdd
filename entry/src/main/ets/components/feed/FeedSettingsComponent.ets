import { FeedSettingsParam } from '../../common/AppRouter';
import { FeedDao } from '../../database/FeedDao';
import { FeedPreferences } from '../../models/FeedPreferences';
import { promptAction } from '@kit.ArkUI';
import {
  AUTO_DL_DISABLED,
  AUTO_DL_GLOBAL,
  AUTO_DL_ENABLED,
  AUTO_DEL_DISABLED,
  AUTO_DEL_GLOBAL,
  AUTO_DEL_ENABLED,
  NEW_EP_ACTION_GLOBAL,
  NEW_EP_ACTION_ADD_TO_INBOX,
  NEW_EP_ACTION_NOTHING,
  NEW_EP_ACTION_ADD_TO_QUEUE
} from '../../common/Constants';

@Component
export struct FeedSettingsComponent {
  @State feedId: number = 0;
  @State feedTitle: string = '';
  @State isLoading: boolean = true;
  @State autoDownload: number = AUTO_DL_GLOBAL;
  @State autoDeleteAction: number = AUTO_DEL_GLOBAL;
  @State newEpisodesAction: number = NEW_EP_ACTION_GLOBAL;
  @State feedPlaybackSpeed: number = -1;
  @State feedSkipIntro: number = 0;
  @State feedSkipEnding: number = 0;
  @State keepUpdated: boolean = true;
  @State episodeNotification: boolean = false;
  @State customTitle: string = '';
  private feedDao: FeedDao = new FeedDao();
  private prefs: FeedPreferences = new FeedPreferences();

  private async loadData(): Promise<void> {
    this.isLoading = true;
    const feed = await this.feedDao.getFeed(this.feedId);
    if (feed !== null) {
      this.feedTitle = feed.getDisplayTitle();
      this.customTitle = feed.customTitle;
      this.prefs = feed.preferences;
      this.autoDownload = this.prefs.autoDownload;
      this.autoDeleteAction = this.prefs.autoDeleteAction;
      this.newEpisodesAction = this.prefs.newEpisodesAction;
      this.feedPlaybackSpeed = this.prefs.feedPlaybackSpeed;
      this.feedSkipIntro = this.prefs.feedSkipIntro;
      this.feedSkipEnding = this.prefs.feedSkipEnding;
      this.keepUpdated = this.prefs.keepUpdated;
      this.episodeNotification = this.prefs.episodeNotification;
    }
    this.isLoading = false;
  }

  private async savePrefs(): Promise<void> {
    this.prefs.autoDownload = this.autoDownload;
    this.prefs.autoDeleteAction = this.autoDeleteAction;
    this.prefs.newEpisodesAction = this.newEpisodesAction;
    this.prefs.feedPlaybackSpeed = this.feedPlaybackSpeed;
    this.prefs.feedSkipIntro = this.feedSkipIntro;
    this.prefs.feedSkipEnding = this.feedSkipEnding;
    this.prefs.keepUpdated = this.keepUpdated;
    this.prefs.episodeNotification = this.episodeNotification;
    await this.feedDao.setFeedPreferences(this.prefs, this.feedId);
  }

  private getSpeedLabel(): string {
    if (this.feedPlaybackSpeed < 0) {
      return 'Global default';
    }
    return this.feedPlaybackSpeed.toFixed(1) + 'x';
  }

  private getAutoSkipLabel(): string {
    if (this.feedSkipIntro === 0 && this.feedSkipEnding === 0) {
      return 'Off';
    }
    let parts: string[] = [];
    if (this.feedSkipIntro > 0) {
      parts.push('Intro: ' + this.feedSkipIntro.toString() + 's');
    }
    if (this.feedSkipEnding > 0) {
      parts.push('Ending: ' + this.feedSkipEnding.toString() + 's');
    }
    return parts.join(', ');
  }

  private getAutoDownloadLabel(): string {
    if (this.autoDownload === AUTO_DL_DISABLED) {
      return 'Never';
    } else if (this.autoDownload === AUTO_DL_ENABLED) {
      return 'Always';
    }
    return 'Global default';
  }

  private getAutoDeleteLabel(): string {
    if (this.autoDeleteAction === AUTO_DEL_DISABLED) {
      return 'Never';
    } else if (this.autoDeleteAction === AUTO_DEL_ENABLED) {
      return 'Always';
    }
    return 'Global default';
  }

  private getNewEpisodeLabel(): string {
    if (this.newEpisodesAction === NEW_EP_ACTION_ADD_TO_INBOX) {
      return 'Add to Inbox';
    } else if (this.newEpisodesAction === NEW_EP_ACTION_NOTHING) {
      return 'Nothing';
    } else if (this.newEpisodesAction === NEW_EP_ACTION_ADD_TO_QUEUE) {
      return 'Add to Queue';
    }
    return 'Global default';
  }

  private cycleAutoDownload(): void {
    if (this.autoDownload === AUTO_DL_GLOBAL) {
      this.autoDownload = AUTO_DL_ENABLED;
    } else if (this.autoDownload === AUTO_DL_ENABLED) {
      this.autoDownload = AUTO_DL_DISABLED;
    } else {
      this.autoDownload = AUTO_DL_GLOBAL;
    }
    this.savePrefs();
  }

  private cycleAutoDelete(): void {
    if (this.autoDeleteAction === AUTO_DEL_GLOBAL) {
      this.autoDeleteAction = AUTO_DEL_ENABLED;
    } else if (this.autoDeleteAction === AUTO_DEL_ENABLED) {
      this.autoDeleteAction = AUTO_DEL_DISABLED;
    } else {
      this.autoDeleteAction = AUTO_DEL_GLOBAL;
    }
    this.savePrefs();
  }

  private cycleNewEpisodeAction(): void {
    if (this.newEpisodesAction === NEW_EP_ACTION_GLOBAL) {
      this.newEpisodesAction = NEW_EP_ACTION_ADD_TO_INBOX;
    } else if (this.newEpisodesAction === NEW_EP_ACTION_ADD_TO_INBOX) {
      this.newEpisodesAction = NEW_EP_ACTION_ADD_TO_QUEUE;
    } else if (this.newEpisodesAction === NEW_EP_ACTION_ADD_TO_QUEUE) {
      this.newEpisodesAction = NEW_EP_ACTION_NOTHING;
    } else {
      this.newEpisodesAction = NEW_EP_ACTION_GLOBAL;
    }
    this.savePrefs();
  }

  private cyclePlaybackSpeed(): void {
    if (this.feedPlaybackSpeed < 0) {
      this.feedPlaybackSpeed = 1.0;
    } else {
      let next = this.feedPlaybackSpeed + 0.1;
      if (next > 2.0) {
        this.feedPlaybackSpeed = -1;
      } else {
        this.feedPlaybackSpeed = Math.round(next * 10) / 10;
      }
    }
    this.savePrefs();
  }

  @Builder
  titleBuilder() {
    Column() {
      Text('Podcast settings')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(this.feedTitle)
        .fontSize(14)
        .fontColor('#99000000')
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#1565C0')
      .width('100%')
      .padding({ left: 56, right: 16, top: 24, bottom: 8 })
  }

  @Builder
  settingRow(icon: Resource, title: string, subtitle: string) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ left: 8, right: 8 })

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
      .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 8, right: 16, top: 14, bottom: 14 })
  }

  @Builder
  settingToggleRow(icon: Resource, title: string, subtitle: string, isOn: boolean,
    onChange: (isOn: boolean) => void) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ left: 8, right: 8 })

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
      .margin({ left: 8 })

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
    }
    .width('100%')
    .padding({ left: 8, right: 16, top: 12, bottom: 12 })
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else {
          List() {
            // === Display Section (matching Android) ===
            ListItem() {
              this.sectionTitle('Display')
            }

            ListItem() {
              this.settingRow($r('app.media.ic_rename'), 'Rename', '')
            }
            .onClick(() => {
              promptAction.showToast({ message: 'Rename not yet implemented' });
            })

            ListItem() {
              this.settingRow($r('app.media.ic_tag'), 'Tags',
                'Change the tags of this podcast to help organize your subscriptions')
            }
            .onClick(() => {
              promptAction.showToast({ message: 'Tags not yet implemented' });
            })

            // Divider between Display and Playback
            ListItem() {
              Divider().color('#E0E0E0').margin({ left: 16, right: 16, top: 4, bottom: 4 })
            }

            // === Playback Section (matching Android) ===
            ListItem() {
              this.sectionTitle('Playback')
            }

            ListItem() {
              this.settingRow($r('app.media.ic_playback_speed'), 'Playback speed',
                'The speed to use when starting audio playback for episodes in this podcast: ' +
                this.getSpeedLabel())
            }
            .onClick(() => {
              this.cyclePlaybackSpeed();
            })

            ListItem() {
              this.settingRow($r('app.media.ic_skip_next'), 'Auto skip',
                'Skip introductions and ending credits: ' + this.getAutoSkipLabel())
            }
            .onClick(() => {
              // Cycle intro skip
              this.feedSkipIntro = this.feedSkipIntro + 5;
              if (this.feedSkipIntro > 30) {
                this.feedSkipIntro = 0;
                // Then cycle ending skip
                this.feedSkipEnding = this.feedSkipEnding + 5;
                if (this.feedSkipEnding > 30) {
                  this.feedSkipEnding = 0;
                }
              }
              this.savePrefs();
            })

            ListItem() {
              this.settingRow($r('app.media.ic_volume_adaption'), 'Volume adaptation',
                'Turn volume for episodes of this podcast up or down: No adaption')
            }

            // Divider between Playback and Automation
            ListItem() {
              Divider().color('#E0E0E0').margin({ left: 16, right: 16, top: 4, bottom: 4 })
            }

            // === Automation Section (matching Android order) ===
            ListItem() {
              this.sectionTitle('Automation')
            }

            ListItem() {
              this.settingToggleRow($r('app.media.ic_refresh'), 'Keep updated',
                'Include this podcast when (auto-)refreshing all podcasts',
                this.keepUpdated, (isOn: boolean) => {
                  this.keepUpdated = isOn;
                  this.savePrefs();
                })
            }

            ListItem() {
              this.settingToggleRow($r('app.media.ic_notifications'), 'Episode notifications',
                'Show a notification when a new episode is released',
                this.episodeNotification, (isOn: boolean) => {
                  this.episodeNotification = isOn;
                  this.savePrefs();
                })
            }

            ListItem() {
              this.settingRow($r('app.media.ic_delete'), 'Delete after playing',
                'Global default (' + this.getAutoDeleteLabel() + ')')
            }
            .onClick(() => {
              this.cycleAutoDelete();
            })

            ListItem() {
              this.settingRow($r('app.media.ic_feed'), 'New episodes action',
                'Global default (' + this.getNewEpisodeLabel() + ')')
            }
            .onClick(() => {
              this.cycleNewEpisodeAction();
            })

            ListItem() {
              this.settingRow($r('app.media.ic_download'), 'Include in auto downloads',
                'Global default (' + this.getAutoDownloadLabel() + ')')
            }
            .onClick(() => {
              this.cycleAutoDownload();
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
    }
    .title(this.titleBuilder)
    .onReady((ctx: NavDestinationContext) => {
      if (ctx.pathInfo.param instanceof FeedSettingsParam) {
        const p: FeedSettingsParam = ctx.pathInfo.param;
        this.feedId = p.feedId;
        this.loadData();
      }
    })
  }
}
