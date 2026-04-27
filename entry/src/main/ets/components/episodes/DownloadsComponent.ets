import { DownloadsViewModel } from '../../viewmodels/DownloadsViewModel';
import {
  EventBus,
  EVENT_EPISODE_DOWNLOADED
} from '../../common/EventBus';
import { FeedItem } from '../../models/FeedItem';
import { EpisodeDetailParam, RouteName } from '../../common/AppRouter';
import { EmptyStateView } from '../common/EmptyStateView';
import { PlaybackController } from '../../playback/PlaybackController';
import { DownloadManager } from '../../network/DownloadManager';
import { DownloadLogDao } from '../../database/DownloadLogDao';
import { DownloadResult } from '../../models/DownloadResult';
import { promptAction } from '@kit.ArkUI';

@Component
export struct DownloadsComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  private vm: DownloadsViewModel = new DownloadsViewModel();
  @State downloadCount: number = 0;
  @State isLoading: boolean = true;
  @State showDownloadLog: boolean = false;
  @State downloadLogs: DownloadResult[] = [];
  private downloadLogDao: DownloadLogDao = new DownloadLogDao();
  private unsubscribers: (() => void)[] = [];

  aboutToAppear(): void {
    this.loadData();
    this.setupEventSubscriptions();
  }

  private setupEventSubscriptions(): void {
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_DOWNLOADED, () => {
      this.loadData();
    }));
  }

  aboutToDisappear(): void {
    for (let i = 0; i < this.unsubscribers.length; i++) {
      this.unsubscribers[i]();
    }
    this.unsubscribers = [];
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    await this.vm.loadDownloads();
    this.downloadCount = this.vm.downloadCount;
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

  private getTimeAgo(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / 60000);
    if (minutes < 60) {
      return minutes.toString() + ' minutes ago';
    }
    const hours = Math.floor(minutes / 60);
    if (hours < 24) {
      return hours.toString() + ' hours ago';
    }
    const days = Math.floor(hours / 24);
    return days.toString() + ' days ago';
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
    Column() {
      // Title bar (matching Android: back + title + search + log + overflow)
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(22)
          .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          .margin({ right: 12 })
          .onClick(() => {
            this.navPathStack.pop();
          })
        Text('Downloads')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        // Search
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(22)
          .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          .margin({ right: 16 })
          .onClick(() => {
            this.navPathStack.pushPathByName(RouteName.SEARCH, new Object());
          })

        // Download log
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(22)
          .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          .margin({ right: 16 })
          .onClick(async () => {
            this.downloadLogs = await this.downloadLogDao.getDownloadLog();
            this.showDownloadLog = true;
          })

        // Overflow menu
        Text('\u22EE')
          .fontSize(22)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .bindMenu([
            {
              value: 'Delete played',
              action: async () => {
                const items = this.vm.downloadsDataSource.getAll();
                for (let i = 0; i < items.length; i++) {
                  const item = items[i];
                  if (item.isPlayed()) {
                    await DownloadManager.getInstance().deleteDownload(item.id);
                  }
                }
                this.loadData();
                promptAction.showToast({ message: 'Played downloads deleted' });
              }
            },
            { value: 'Sort', action: () => { } },
            { value: 'Refresh', action: () => { this.loadData(); } }
          ])
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else if (this.vm.downloadsDataSource.totalCount() === 0) {
          EmptyStateView({
            icon: '\u2B07',
            message: 'No downloads'
          })
        } else {
          List() {
            LazyForEach(this.vm.downloadsDataSource,
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
                      // Metadata: date · size (matching Android)
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
                        .fontWeight(item.isPlayed() ? FontWeight.Normal : FontWeight.Medium)
                        .fontColor(item.isPlayed() ? '#99000000' : '#E6000000')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 2 })
                        .width('100%')

                      // Duration or progress bar
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

                    // Delete button (matching Android trash icon)
                    Column() {
                      Image($r('app.media.ic_delete'))
                        .width(20)
                        .height(20)
                    }
                    .width(36)
                    .height(36)
                    .borderRadius(18)
                    .border({ width: 1.5, color: '#333333' })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .margin({ left: 8 })
                    .onClick(async () => {
                      await DownloadManager.getInstance().deleteDownload(item.id);
                      promptAction.showToast({ message: 'Download deleted' });
                      this.loadData();
                    })
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

    // Download log bottom sheet
    if (this.showDownloadLog) {
      // Dismiss overlay
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showDownloadLog = false;
        })

      // Log panel
      Column() {
        // Header
        Row() {
          Text('Download log')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Image($r('app.media.ic_delete'))
            .width(22)
            .height(22)
            .onClick(async () => {
              await this.downloadLogDao.clearDownloadLog();
              this.downloadLogs = [];
              promptAction.showToast({ message: 'Download log cleared' });
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 12 })

        // Log list
        List() {
          ForEach(this.downloadLogs, (log: DownloadResult) => {
            ListItem() {
              Row() {
                Text(log.successful ? '\u2714' : '\u2718')
                  .fontSize(16)
                  .fontColor(log.successful ? '#4CAF50' : '#F44336')
                  .margin({ right: 8 })
                Column() {
                  Text(log.title)
                    .fontSize(14)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text('Media file \u00B7 ' + this.getTimeAgo(log.completionDate))
                    .fontSize(12)
                    .fontColor('#99000000')
                    .margin({ top: 2 })
                    .width('100%')
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            }
          }, (log: DownloadResult) => log.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('60%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .shadow({ radius: 8, color: '#33000000', offsetY: -2 })
    }
    }
    .width('100%')
    .height('100%')
  }
}
