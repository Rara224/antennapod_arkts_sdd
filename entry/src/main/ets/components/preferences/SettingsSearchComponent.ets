import { RouteName, SettingsDetailParam } from '../../common/AppRouter';
import { promptAction } from '@kit.ArkUI';
import { GlobalState } from '../../common/GlobalState';

interface SettingsItem {
  icon: Resource;
  title: string;
  subtitle: string;
  category: string;
  isProject: boolean;
}

@Component
export struct SettingsSearchComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @State searchText: string = '';
  @State filteredItems: SettingsItem[] = [];

  private allItems: SettingsItem[] = [
    { icon: $r('app.media.ic_appearance'), title: 'User interface',
      subtitle: 'Appearance, subscriptions, lockscreen', category: 'ui', isProject: false },
    { icon: $r('app.media.ic_play_24dp'), title: 'Playback',
      subtitle: 'Headphone controls, Skip intervals, Queue', category: 'playback', isProject: false },
    { icon: $r('app.media.ic_download'), title: 'Downloads',
      subtitle: 'Update interval, Mobile data, Automatic download, Automatic deletion', category: 'downloads', isProject: false },
    { icon: $r('app.media.ic_cloud'), title: 'Synchronization',
      subtitle: 'Synchronize with other devices', category: 'sync', isProject: false },
    { icon: $r('app.media.ic_storage'), title: 'Backup & restore',
      subtitle: 'Move subscriptions and queue to another device', category: 'backup', isProject: false },
    { icon: $r('app.media.ic_notifications'), title: 'Notifications',
      subtitle: '', category: 'notifications', isProject: false },
    { icon: $r('app.media.ic_questionmark'), title: 'Documentation & support',
      subtitle: '', category: 'docs', isProject: true },
    { icon: $r('app.media.ic_chat'), title: 'User forum',
      subtitle: '', category: 'forum', isProject: true },
    { icon: $r('app.media.ic_heart'), title: 'Contribute',
      subtitle: '', category: 'contribute', isProject: true },
    { icon: $r('app.media.ic_bug'), title: 'Report bug',
      subtitle: '', category: 'bug', isProject: true },
    { icon: $r('app.media.ic_info'), title: 'About',
      subtitle: '', category: 'about', isProject: true },
  ];

  private filterItems(query: string): void {
    if (query.length === 0) {
      this.filteredItems = [];
      return;
    }
    const lowerQuery = query.toLowerCase();
    this.filteredItems = this.allItems.filter(item =>
      item.title.toLowerCase().includes(lowerQuery) ||
      item.subtitle.toLowerCase().includes(lowerQuery)
    );
  }

  private navigateTo(category: string): void {
    const param = new SettingsDetailParam();
    param.category = category;
    this.navPathStack.pushPathByName(RouteName.SETTINGS_DETAIL, param);
  }

  private openUrl(url: string): void {
    GlobalState.openLink(url);
  }

  private handleItemClick(item: SettingsItem): void {
    switch (item.category) {
      case 'ui':
      case 'playback':
      case 'downloads':
      case 'sync':
      case 'backup':
      case 'notifications':
        this.navigateTo(item.category);
        break;
      case 'docs':
        this.openUrl('https://antennapod.org/documentation');
        break;
      case 'forum':
        this.openUrl('https://forum.antennapod.org');
        break;
      case 'contribute':
        this.openUrl('https://github.com/AntennaPod/AntennaPod/blob/develop/CONTRIBUTING.md');
        break;
      case 'bug':
        this.openUrl('https://github.com/AntennaPod/AntennaPod/issues');
        break;
      case 'about':
        promptAction.showDialog({
          title: 'AntennaPod',
          message: 'Version 3.0.0\n\nAntennaPod ArkTS Edition\nA podcast manager for HarmonyOS\n\nBased on AntennaPod for Android\nhttps://antennapod.org',
          buttons: [{ text: 'OK', color: '#1565C0' }]
        });
        break;
    }
  }

  @Builder
  resultRow(item: SettingsItem) {
    Row() {
      Image(item.icon)
        .width(24)
        .height(24)
        .margin({ left: 10, right: 10 })

      Column() {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        if (item.subtitle.length > 0) {
          Text(item.subtitle)
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
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(18)
            .fontColor(['#99000000'])
            .margin({ right: 8 })
          TextInput({ placeholder: 'Search settings...', text: this.searchText })
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .fontSize(15)
            .onChange((value: string) => {
              this.searchText = value;
              this.filterItems(value);
            })
        }
        .width('100%')
        .height(44)
        .borderRadius(22)
        .backgroundColor('#F0F0F0')
        .padding({ left: 16, right: 16 })
        .margin({ left: 16, right: 16, top: 8, bottom: 8 })

        if (this.searchText.length === 0) {
          Column() {
            Text('Enter text to search settings')
              .fontSize(16)
              .fontColor('#99000000')
              .margin({ top: 40 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)
        } else if (this.filteredItems.length === 0) {
          Column() {
            Text('No results found')
              .fontSize(16)
              .fontColor('#99000000')
              .margin({ top: 40 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)
        } else {
          List() {
            ForEach(this.filteredItems, (item: SettingsItem) => {
              ListItem() {
                this.resultRow(item)
              }
              .onClick(() => {
                this.handleItemClick(item);
              })
            }, (item: SettingsItem, index: number) => item.category + index.toString())
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('Search settings')
  }
}
