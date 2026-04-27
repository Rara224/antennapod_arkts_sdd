import {
  StatisticsViewModel,
  FeedStatistics,
  YearStatistics,
  DownloadStatistics
} from '../../viewmodels/StatisticsViewModel';
import {
  EventBus,
  EVENT_EPISODE_PLAY_STATE_CHANGED,
  EVENT_PLAYBACK_HISTORY_CHANGED
} from '../../common/EventBus';
import { EmptyStateView } from '../common/EmptyStateView';
import { HalfCircleChart, ChartSegment } from './HalfCircleChart';
import { promptAction } from '@kit.ArkUI';

@Component
export struct StatisticsComponent {
  private vm: StatisticsViewModel = new StatisticsViewModel();
  @State totalPlayedTime: string = '';
  @State totalPlayedEpisodes: number = 0;
  @State totalCompletedEpisodes: number = 0;
  @State feedStatsList: FeedStatistics[] = [];
  @State chartSegments: ChartSegment[] = [];
  @State yearStatsList: YearStatistics[] = [];
  @State downloadStatsList: DownloadStatistics[] = [];
  @State totalDownloadSize: string = '0 MB';
  @State totalDownloadEpisodes: number = 0;
  @State downloadChartSegments: ChartSegment[] = [];
  @State isLoading: boolean = true;
  @State maxPlayedDuration: number = 1;
  @State currentTab: number = 0;
  @State selectedFilter: number = 0;
  private filterLabels: string[] = ['All time', 'This year', 'Last year'];
  private unsubscribers: (() => void)[] = [];

  aboutToAppear(): void {
    this.loadSubscriptionsTab();
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_PLAY_STATE_CHANGED, () => {
      this.loadSubscriptionsTab();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_PLAYBACK_HISTORY_CHANGED, () => {
      this.loadSubscriptionsTab();
    }));
  }

  aboutToDisappear(): void {
    for (let i = 0; i < this.unsubscribers.length; i++) {
      this.unsubscribers[i]();
    }
    this.unsubscribers = [];
  }

  private async loadSubscriptionsTab(): Promise<void> {
    this.isLoading = true;
    await this.vm.loadStatistics();
    this.totalPlayedTime = this.vm.formatDuration(this.vm.totalPlayedTime);
    this.totalPlayedEpisodes = this.vm.totalPlayedEpisodes;
    this.totalCompletedEpisodes = this.vm.totalCompletedEpisodes;
    this.feedStatsList = this.vm.feedStatsList;
    this.chartSegments = this.vm.chartSegments;
    this.maxPlayedDuration = 1;
    for (let i = 0; i < this.feedStatsList.length; i++) {
      if (this.feedStatsList[i].totalPlayedDuration > this.maxPlayedDuration) {
        this.maxPlayedDuration = this.feedStatsList[i].totalPlayedDuration;
      }
    }
    this.isLoading = false;
  }

  private async loadYearsTab(): Promise<void> {
    this.isLoading = true;
    await this.vm.loadYearStatistics();
    this.yearStatsList = this.vm.yearStatsList;
    this.isLoading = false;
  }

  private async loadDownloadsTab(): Promise<void> {
    this.isLoading = true;
    await this.vm.loadDownloadStatistics();
    this.downloadStatsList = this.vm.downloadStatsList;

    // Calculate totals and chart segments for downloads
    let totalSize = 0;
    let totalEps = 0;
    const dlSegments: ChartSegment[] = [];
    for (let i = 0; i < this.downloadStatsList.length; i++) {
      totalSize += this.downloadStatsList[i].totalSize;
      totalEps += this.downloadStatsList[i].downloadedCount;
    }
    this.totalDownloadSize = this.vm.formatSize(totalSize);
    this.totalDownloadEpisodes = totalEps;

    // Build chart segments by size proportion
    const colors: string[] = ['#1565C0', '#36A2EB', '#4BC0C0', '#9966FF', '#FF9F40',
      '#FF6384', '#FFCE56', '#7BC225', '#E74C3C', '#3498DB'];
    for (let i = 0; i < this.downloadStatsList.length && i < 10; i++) {
      const stat = this.downloadStatsList[i];
      if (stat.totalSize > 0 && totalSize > 0) {
        const seg = new ChartSegment();
        seg.color = colors[i % colors.length];
        seg.percentage = Math.round(stat.totalSize * 100 / totalSize);
        seg.label = stat.feedTitle;
        dlSegments.push(seg);
      }
    }
    this.downloadChartSegments = dlSegments;
    this.isLoading = false;
  }

  private confirmResetStatistics(): void {
    promptAction.showDialog({
      title: 'Reset statistics',
      message: 'This will reset all playback statistics. Continue?',
      buttons: [
        { text: 'Cancel', color: '#666666' },
        { text: 'Reset', color: '#FF4444' }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        this.vm.resetStatistics().then(() => {
          this.loadSubscriptionsTab();
        });
      }
    }).catch(() => {});
  }

  build() {
    NavDestination() {
      Column() {
        // Tab bar
        Tabs({ index: this.currentTab }) {
          TabContent() {
            this.subscriptionsContent()
          }
          .tabBar('Subscriptions')

          TabContent() {
            this.yearsContent()
          }
          .tabBar('Years')

          TabContent() {
            this.downloadsContent()
          }
          .tabBar('Downloads')
        }
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.currentTab = index;
          if (index === 0) {
            this.loadSubscriptionsTab();
          } else if (index === 1) {
            this.loadYearsTab();
          } else if (index === 2) {
            this.loadDownloadsTab();
          }
        })
      }
      .width('100%')
      .height('100%')
    }
    .title('Statistics')
    .menus([
      {
        value: this.filterLabels[this.selectedFilter],
        icon: $r('app.media.ic_filter'),
        action: () => {
          promptAction.showActionMenu({
            title: 'Time range',
            buttons: [
              { text: 'All time', color: this.selectedFilter === 0 ? '#1565C0' : '#333333' },
              { text: 'This year', color: this.selectedFilter === 1 ? '#1565C0' : '#333333' },
              { text: 'Last year', color: this.selectedFilter === 2 ? '#1565C0' : '#333333' }
            ]
          }).then((result: promptAction.ActionMenuSuccessResponse) => {
            this.selectedFilter = result.index;
            this.loadSubscriptionsTab();
          }).catch(() => {});
        }
      },
      {
        value: 'More',
        icon: $r('app.media.ic_more_vert'),
        action: () => {
          this.confirmResetStatistics();
        }
      }
    ])
  }

  private getMaxYearDuration(): number {
    let max = 1;
    for (let i = 0; i < this.yearStatsList.length; i++) {
      if (this.yearStatsList[i].totalDuration > max) {
        max = this.yearStatsList[i].totalDuration;
      }
    }
    return max;
  }

  private getDateRangeText(): string {
    const now = new Date();
    const months: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentMonth = months[now.getMonth()];
    const currentYear = now.getFullYear().toString();
    return 'Played between ' + currentMonth + ' ' + currentYear + ' and ' + currentMonth + ' ' + currentYear;
  }

  @Builder
  subscriptionsContent() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else {
        Scroll() {
          Column() {
            // Half circle chart with subtitle (matching Android)
            HalfCircleChart({
              segments: this.chartSegments,
              centerText: this.totalPlayedTime,
              subtitleText: this.getDateRangeText()
            })

            Divider().margin({ left: 16, right: 16 }).color('#F0F0F0')

            // Feed list (matching Android: cover + title + colored dot + hours)
            if (this.feedStatsList.length === 0) {
              EmptyStateView({
                icon: '\uD83D\uDCCA',
                message: 'No statistics yet'
              })
            } else {
              ForEach(this.feedStatsList, (stat: FeedStatistics, index: number) => {
                Row() {
                  if (stat.imageUrl.length > 0) {
                    Image(stat.imageUrl)
                      .width(48)
                      .height(48)
                      .borderRadius(6)
                      .objectFit(ImageFit.Cover)
                      .margin({ right: 12 })
                  } else {
                    Column() {
                      Text('\uD83C\uDFA7')
                        .fontSize(24)
                    }
                    .width(48)
                    .height(48)
                    .borderRadius(6)
                    .backgroundColor('#F5F5F5')
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .margin({ right: 12 })
                  }

                  Column() {
                    Text(stat.feedTitle)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')

                    // Colored dot + duration (matching Android)
                    Row() {
                      Circle()
                        .width(8)
                        .height(8)
                        .fill(index < 10 ? this.chartSegments[index]?.color ?? '#36A2EB' : '#36A2EB')
                        .margin({ right: 6, top: 3 })
                      Text(this.vm.formatDuration(stat.totalPlayedDuration))
                        .fontSize(13)
                        .fontColor('#99000000')
                    }
                    .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              }, (stat: FeedStatistics) => 'sub_' + stat.feedId.toString())
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  yearsContent() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.yearStatsList.length === 0) {
        EmptyStateView({
          icon: '\uD83D\uDCC5',
          message: 'No yearly statistics yet'
        })
      } else {
        Scroll() {
          Column() {
            // Bar chart area (matching Android)
            Column() {
              // Bars
              Row() {
                ForEach(this.yearStatsList, (stat: YearStatistics) => {
                  Column() {
                    // Bar
                    Column()
                      .width(40)
                      .height(stat.totalDuration > 0
                        ? Math.max(8, Math.round(stat.totalDuration * 120 / this.getMaxYearDuration())).toString() + 'vp'
                        : '8vp')
                      .backgroundColor('#1565C0')
                      .borderRadius({ topLeft: 4, topRight: 4 })
                  }
                  .layoutWeight(1)
                  .justifyContent(FlexAlign.End)
                  .height(140)
                }, (stat: YearStatistics) => 'bar_' + stat.year.toString())
              }
              .width('100%')
              .padding({ left: 32, right: 32 })

              // Baseline dashed + "0" label
              Row() {
                Text('0')
                  .fontSize(12)
                  .fontColor('#99000000')
                  .margin({ right: 8 })
                Column()
                  .layoutWeight(1)
                  .height(1)
                  .backgroundColor('#CCCCCC')
              }
              .width('100%')
              .padding({ left: 16, right: 32 })
              .alignItems(VerticalAlign.Center)

              // Label
              Text('Time played per month')
                .fontSize(13)
                .fontColor('#99000000')
                .margin({ top: 8 })
                .textAlign(TextAlign.Center)
                .width('100%')
            }
            .padding({ top: 16, bottom: 16 })

            Divider().color('#F0F0F0').margin({ left: 16, right: 16 })

            // Year list (matching Android)
            ForEach(this.yearStatsList, (stat: YearStatistics) => {
              Column() {
                Text(stat.year.toString())
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                Text(this.vm.formatDuration(stat.totalDuration))
                  .fontSize(14)
                  .fontColor('#99000000')
                  .margin({ top: 4 })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .alignItems(HorizontalAlign.Start)
            }, (stat: YearStatistics) => 'yearRow_' + stat.year.toString())
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  downloadsContent() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .width('100%')
      } else if (this.downloadStatsList.length === 0) {
        EmptyStateView({
          icon: '\u2B07',
          message: 'No download statistics yet'
        })
      } else {
        Scroll() {
          Column() {
            // Half circle chart (matching Android)
            HalfCircleChart({
              segments: this.downloadChartSegments,
              centerText: this.totalDownloadSize,
              subtitleText: 'Total size of ' + this.totalDownloadEpisodes.toString() +
                ' episodes on the device'
            })

            Divider().color('#F0F0F0').margin({ left: 16, right: 16 })

            // Feed list (matching Android: cover + title + dot + size · episodes)
            ForEach(this.downloadStatsList, (stat: DownloadStatistics, index: number) => {
              Row() {
                if (stat.imageUrl.length > 0) {
                  Image(stat.imageUrl)
                    .width(48)
                    .height(48)
                    .borderRadius(6)
                    .objectFit(ImageFit.Cover)
                    .margin({ right: 12 })
                } else {
                  Column() {
                    Text('\u2B07')
                      .fontSize(24)
                  }
                  .width(48)
                  .height(48)
                  .borderRadius(6)
                  .backgroundColor('#F5F5F5')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                  .margin({ right: 12 })
                }

                Column() {
                  Text(stat.feedTitle)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  // Colored dot + size · episodes (matching Android)
                  Row() {
                    Circle()
                      .width(8)
                      .height(8)
                      .fill(index < this.downloadChartSegments.length
                        ? this.downloadChartSegments[index].color : '#36A2EB')
                      .margin({ right: 6, top: 3 })
                    Text(this.vm.formatSize(stat.totalSize) + ' \u00B7 ' +
                      stat.downloadedCount.toString() + ' episodes')
                      .fontSize(13)
                      .fontColor('#99000000')
                  }
                  .margin({ top: 4 })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            }, (stat: DownloadStatistics) => 'dl_' + stat.feedId.toString())
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }

}
