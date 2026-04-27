import { PlaybackHistoryViewModel } from '../../viewmodels/PlaybackHistoryViewModel';
import {
  EventBus,
  EVENT_PLAYBACK_HISTORY_CHANGED
} from '../../common/EventBus';
import { FeedItem } from '../../models/FeedItem';
import { EpisodeDetailParam, RouteName } from '../../common/AppRouter';
import { EmptyStateView } from '../common/EmptyStateView';
import { PlaybackController } from '../../playback/PlaybackController';
import { promptAction } from '@kit.ArkUI';

@Component
export struct PlaybackHistoryComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  private vm: PlaybackHistoryViewModel = new PlaybackHistoryViewModel();
  @State historyCount: number = 0;
  @State isLoading: boolean = true;
  private unsubscribers: (() => void)[] = [];

  private setupEventSubscriptions(): void {
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_PLAYBACK_HISTORY_CHANGED, () => {
      this.loadData();
    }));
  }

  aboutToDisappear(): void {
    for (let i = 0; i < this.unsubscribers.length; i++) {
      this.unsubscribers[i]();
    }
    this.unsubscribers = [];
  }

  private confirmClearHistory(): void {
    promptAction.showDialog({
      title: 'Clear history',
      message: 'Clear all playback history?',
      buttons: [
        { text: 'Cancel', color: '#666666' },
        { text: 'Clear', color: '#FF4444' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        this.vm.clearHistory().then(() => {
          this.historyCount = 0;
        });
      }
    }).catch(() => {
      // Cancelled
    });
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    await this.vm.loadHistory();
    this.historyCount = this.vm.historyCount;
    this.isLoading = false;
  }

  private formatTime(ms: number): string {
    if (ms <= 0) {
      return '00:00:00';
    }
    const totalSeconds = Math.floor(ms / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    return pad(hours) + ':' + pad(minutes) + ':' + pad(seconds);
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
        } else if (this.vm.historyDataSource.totalCount() === 0) {
          EmptyStateView({
            icon: '\uD83D\uDD52',
            message: 'No playback history'
          })
        } else {
          List() {
            LazyForEach(this.vm.historyDataSource,
              (item: FeedItem) => {
                ListItem() {
                  Row() {
                    // Cover image
                    if (item.getImageLocation().length > 0) {
                      Image(item.getImageLocation())
                        .width(56)
                        .height(56)
                        .borderRadius(6)
                        .objectFit(ImageFit.Cover)
                        .margin({ right: 12 })
                    } else {
                      Column() {
                        Text('?')
                          .fontSize(22)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.White)
                      }
                      .width(56)
                      .height(56)
                      .borderRadius(6)
                      .backgroundColor('#BDBDBD')
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .margin({ right: 12 })
                    }

                    // Content
                    Column() {
                      // Metadata: date · size
                      Row() {
                        Text(item.getShortPubDateStr())
                          .fontSize(12)
                          .fontColor('#99000000')
                        if (item.media !== null && item.media.size > 0) {
                          Text(' \u00B7 ' + item.media.getSizeStr())
                            .fontSize(12)
                            .fontColor('#99000000')
                        }
                      }
                      .width('100%')

                      // Title
                      Text(item.title)
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#E6000000')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 2 })
                        .width('100%')

                      // Duration or progress
                      if (item.media !== null && item.media.position > 0 && item.media.duration > 0) {
                        Row() {
                          Text(this.formatTime(item.media.position))
                            .fontSize(11)
                            .fontColor('#99000000')
                          Progress({
                            value: Math.round(item.media.position * 100 / item.media.duration),
                            total: 100,
                            type: ProgressType.Linear
                          })
                            .layoutWeight(1)
                            .height(3)
                            .margin({ left: 6, right: 6 })
                            .color('#1565C0')
                            .backgroundColor('#E0E0E0')
                          Text(this.formatTime(item.media.duration))
                            .fontSize(11)
                            .fontColor('#99000000')
                        }
                        .width('100%')
                        .margin({ top: 4 })
                        .alignItems(VerticalAlign.Center)
                      } else if (item.media !== null) {
                        Text(item.media.getDurationStr())
                          .fontSize(12)
                          .fontColor('#99000000')
                          .margin({ top: 2 })
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    // Play button (matching Android)
                    if (item.media !== null) {
                      Column() {
                        SymbolGlyph($r('sys.symbol.play_fill'))
                          .fontSize(20)
                          .fontColor(['#333333'])
                      }
                      .width(36)
                      .height(36)
                      .borderRadius(18)
                      .border({ width: 1.5, color: '#333333' })
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .margin({ left: 8 })
                      .onClick(() => {
                        PlaybackController.getInstance().playEpisode(item.id);
                      })
                    }
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .alignItems(VerticalAlign.Top)
                  .onClick(() => {
                    const param = new EpisodeDetailParam();
                    param.episodeId = item.id;
                    param.feedId = item.feedId;
                    this.navPathStack.pushPathByName(RouteName.EPISODE_DETAIL, param);
                  })
                }
              },
              (item: FeedItem) => item.id.toString()
            )
          }
          .layoutWeight(1)
          .width('100%')
          .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 84, endMargin: 16 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('Playback history')
    .menus([
      {
        value: 'Delete',
        icon: $r('app.media.ic_delete'),
        action: () => {
          this.confirmClearHistory();
        }
      }
    ])
    .onReady(() => {
      this.loadData();
      this.setupEventSubscriptions();
    })
  }
}
