import { AllEpisodesViewModel } from '../../viewmodels/AllEpisodesViewModel';
import {
  EventBus,
  EVENT_FEED_UPDATED,
  EVENT_EPISODE_DOWNLOADED,
  EVENT_EPISODE_PLAY_STATE_CHANGED,
  EVENT_SUBSCRIPTION_ADDED,
  EVENT_SUBSCRIPTION_REMOVED,
  EVENT_FEED_LIST_CHANGED
} from '../../common/EventBus';
import { FeedItem } from '../../models/FeedItem';
import { EpisodeDetailParam, RouteName } from '../../common/AppRouter';
import { EmptyStateView } from '../common/EmptyStateView';
import { PlaybackController } from '../../playback/PlaybackController';

@Component
export struct AllEpisodesComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  private vm: AllEpisodesViewModel = new AllEpisodesViewModel();
  @State isLoading: boolean = true;
  @State hasMore: boolean = false;
  @State episodeCount: number = 0;
  @State isFavoriteFilter: boolean = false;
  private unsubscribers: (() => void)[] = [];

  aboutToAppear(): void {
    this.loadData();
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_SUBSCRIPTION_ADDED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_SUBSCRIPTION_REMOVED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_FEED_LIST_CHANGED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_FEED_UPDATED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_DOWNLOADED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_PLAY_STATE_CHANGED, () => {
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
    await this.vm.loadInitial();
    this.hasMore = this.vm.hasMore;
    this.episodeCount = this.vm.episodeDataSource.totalCount();
    this.isLoading = false;
  }

  private async loadMore(): Promise<void> {
    await this.vm.loadMore();
    this.hasMore = this.vm.hasMore;
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
    Column() {
      // Title bar (matching Android: back + title + search + favorite + overflow)
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(22)
          .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          .margin({ right: 12 })
          .onClick(() => {
            this.navPathStack.pop();
          })
        Text('Episodes')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        // Search button
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(22)
          .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          .margin({ right: 16 })
          .onClick(() => {
            this.navPathStack.pushPathByName(RouteName.SEARCH, new Object());
          })

        // Favorite filter toggle
        Image(this.isFavoriteFilter ? $r('app.media.ic_heart') : $r('app.media.ic_star_border'))
          .width(22)
          .height(22)
          .fillColor($r('sys.color.ohos_id_color_text_primary'))
          .margin({ right: 16 })
          .onClick(() => {
            this.isFavoriteFilter = !this.isFavoriteFilter;
            this.isLoading = true;
            this.vm.loadEpisodes(this.isFavoriteFilter).then(() => {
              this.episodeCount = this.vm.episodeDataSource.totalCount();
              this.hasMore = this.vm.hasMore;
              this.isLoading = false;
            });
          })

        // Overflow menu
        Text('\u22EE')
          .fontSize(22)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .bindMenu([
            { value: 'Refresh', action: () => { this.loadData(); } },
            { value: 'Filter', action: () => { } },
            { value: 'Sort', action: () => { } }
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
        } else if (this.episodeCount === 0) {
          EmptyStateView({
            icon: '\uD83C\uDFA7',
            message: 'No episodes yet. Subscribe to a podcast to get started!',
            actionLabel: 'Add Podcast',
            onAction: () => {
              this.navPathStack.pushPathByName(RouteName.ADD_FEED, new Object());
            }
          })
        } else {
          List() {
            LazyForEach(this.vm.episodeDataSource,
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
                      // Metadata line: status + date · size (matching Android)
                      Row() {
                        if (item.isNew()) {
                          Circle()
                            .width(6)
                            .height(6)
                            .fill('#2196F3')
                            .margin({ right: 4, top: 5 })
                        }
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

                      // Episode title
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

                    // Action button: play or download (matching Android)
                    if (item.media !== null) {
                      if (item.media.isDownloaded()) {
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
                      } else {
                        Column() {
                          Image($r('app.media.ic_download'))
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
                      }
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
              (item: FeedItem) => item.id.toString() + '_' + item.state.toString()
            )
          }
          .layoutWeight(1)
          .width('100%')
          .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 84, endMargin: 16 })
          .onReachEnd(() => {
            if (this.hasMore) {
              this.loadMore();
            }
          })
        }
    }
    .width('100%')
    .height('100%')
  }
}
