import { RouteName } from '../../common/AppRouter';

@Component
export struct MoreComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;

  @Builder
  menuRow(icon: Resource, label: string, route: string) {
    Row() {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor('#333333')
        .margin({ right: 18 })
      Text(label)
        .fontSize(16)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .onClick(() => {
      this.navPathStack.pushPathByName(route, new Object());
    })
  }

  build() {
    Column() {
      // Title
      Row() {
        Text('More')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      List() {
        ListItem() {
          this.menuRow($r('app.media.ic_feed'), 'Episodes', RouteName.EPISODES)
        }

        ListItem() {
          this.menuRow($r('app.media.ic_download'), 'Downloads', RouteName.DOWNLOADS)
        }

        ListItem() {
          this.menuRow($r('app.media.ic_history'), 'Playback history', RouteName.PLAYBACK_HISTORY)
        }

        ListItem() {
          this.menuRow($r('app.media.ic_chart_box'), 'Statistics', RouteName.STATISTICS)
        }

        ListItem() {
          this.menuRow($r('app.media.ic_add'), 'Add podcast', RouteName.ADD_FEED)
        }

        ListItem() {
          Row() {
            Image($r('app.media.ic_pencil'))
              .width(22)
              .height(22)
              .fillColor('#333333')
              .margin({ right: 18 })
            Text('Customize navigation')
              .fontSize(16)
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        }

        ListItem() {
          this.menuRow($r('app.media.ic_settings'), 'Settings', RouteName.SETTINGS)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 68, endMargin: 16 })
    }
    .width('100%')
    .height('100%')
  }
}
