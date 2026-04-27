import { RouteName, SettingsDetailParam } from '../../common/AppRouter';
import { promptAction } from '@kit.ArkUI';
import { GlobalState } from '../../common/GlobalState';

@Component
export struct SettingsComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @StorageLink('isSettingsVisible') isSettingsVisible: boolean = false;

  aboutToAppear(): void {
    this.isSettingsVisible = true;
  }

  aboutToDisappear(): void {
    this.isSettingsVisible = false;
  }

  private navigateToSearch(): void {
    this.navPathStack.pushPathByName(RouteName.SETTINGS_SEARCH, null);
  }

  private navigateTo(category: string): void {
    const param = new SettingsDetailParam();
    param.category = category;
    this.navPathStack.pushPathByName(RouteName.SETTINGS_DETAIL, param);
  }

  private openUrl(url: string): void {
    GlobalState.openLink(url);
  }

  @Builder
  categoryRow(icon: Resource, title: string, subtitle: string, category: string) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ left: 10, right: 10 })

      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        if (subtitle.length > 0) {
          Text(subtitle)
            .fontSize(13)
            .fontColor('#99000000')
            .margin({ top: 2 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .onClick(() => {
      this.navigateTo(category);
    })
  }

  @Builder
  projectRow(icon: Resource, title: string) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ left: 10, right: 10 })

      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .margin({ left: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
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

  build() {
    NavDestination() {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(18)
            .fontColor(['#99000000'])
            .margin({ right: 8 })
          Text('Search...')
            .fontSize(15)
            .fontColor('#99000000')
            .layoutWeight(1)
        }
        .width('100%')
        .height(44)
        .borderRadius(22)
        .backgroundColor('#F0F0F0')
        .padding({ left: 16, right: 16 })
        .margin({ left: 16, right: 16, top: 8, bottom: 4 })
        .onClick(() => {
          this.navigateToSearch();
        })

        List() {
          ListItem() {
            this.categoryRow($r('app.media.ic_appearance'), 'User interface',
              'Appearance, subscriptions, lockscreen', 'ui')
          }

          ListItem() {
            this.categoryRow($r('app.media.ic_play_24dp'), 'Playback',
              'Headphone controls, Skip intervals, Queue', 'playback')
          }

          ListItem() {
            this.categoryRow($r('app.media.ic_download'), 'Downloads',
              'Update interval, Mobile data, Automatic download, Automatic deletion', 'downloads')
          }

          ListItem() {
            this.categoryRow($r('app.media.ic_cloud'), 'Synchronization',
              'Synchronize with other devices', 'sync')
          }

          ListItem() {
            this.categoryRow($r('app.media.ic_storage'), 'Backup & restore',
              'Move subscriptions and queue to another device', 'backup')
          }

          ListItem() {
            this.categoryRow($r('app.media.ic_notifications'), 'Notifications', '', 'notifications')
          }

          ListItem() {
            Divider().color('#E0E0E0').margin({ left: 16, right: 16, top: 8, bottom: 8 })
          }

          ListItem() {
            this.sectionHeader('Project')
          }

          ListItem() {
            this.projectRow($r('app.media.ic_questionmark'), 'Documentation & support')
          }
          .onClick(() => {
            this.openUrl('https://antennapod.org/documentation');
          })

          ListItem() {
            this.projectRow($r('app.media.ic_chat'), 'User forum')
          }
          .onClick(() => {
            this.openUrl('https://forum.antennapod.org');
          })

          ListItem() {
            this.projectRow($r('app.media.ic_heart'), 'Contribute')
          }
          .onClick(() => {
            this.openUrl('https://github.com/AntennaPod/AntennaPod/blob/develop/CONTRIBUTING.md');
          })

          ListItem() {
            this.projectRow($r('app.media.ic_bug'), 'Report bug')
          }
          .onClick(() => {
            this.openUrl('https://github.com/AntennaPod/AntennaPod/issues');
          })

          ListItem() {
            this.projectRow($r('app.media.ic_info'), 'About')
          }
          .onClick(() => {
            promptAction.showDialog({
              title: 'AntennaPod',
              message: 'Version 3.0.0\n\nAntennaPod ArkTS Edition\nA podcast manager for HarmonyOS\n\nBased on AntennaPod for Android\nhttps://antennapod.org',
              buttons: [{ text: 'OK', color: '#1565C0' }]
            });
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .title('Settings')
  }
}
