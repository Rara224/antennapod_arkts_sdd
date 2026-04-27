import {
  InboxViewModel,
  INBOX_SORT_DURATION_ASC,
  INBOX_SORT_DURATION_DESC,
  INBOX_SORT_DOWNLOAD_DATE_ASC,
  INBOX_SORT_DOWNLOAD_DATE_DESC
} from '../../viewmodels/InboxViewModel';
import {
  EventBus,
  EVENT_FEED_UPDATED,
  EVENT_SUBSCRIPTION_ADDED,
  EVENT_EPISODE_PLAY_STATE_CHANGED,
  EVENT_INBOX_CHANGED
} from '../../common/EventBus';
import { FeedItem } from '../../models/FeedItem';
import { EpisodeDetailParam, RouteName } from '../../common/AppRouter';
import { EmptyStateView } from '../common/EmptyStateView';
import { PlaybackController } from '../../playback/PlaybackController';
import { SortDialog, SortOption } from '../common/SortDialog';

@Component
export struct InboxComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @Prop showBackButton: boolean = false;
  private vm: InboxViewModel = new InboxViewModel();
  @State isLoading: boolean = true;
  @State hasMore: boolean = false;
  @State episodeCount: number = 0;
  @State currentSort: number = INBOX_SORT_DURATION_DESC;
  private unsubscribers: (() => void)[] = [];

  private showSortDialog(): void {
    let ref: CustomDialogController | undefined;
    const ctrl = new CustomDialogController({
      builder: SortDialog({
        sortOptions: this.getSortOptions(),
        currentSort: this.currentSort,
        onSortSelected: (sort: number): void => {
          this.currentSort = sort;
          this.vm.currentSort = sort;
          this.loadData();
        },
        onClose: (): void => {
          ref?.close();
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: false
    });
    ref = ctrl;
    ctrl.open();
  }

  private getSortOptions(): SortOption[] {
    const options: SortOption[] = [];
    const o1 = new SortOption();
    o1.value = INBOX_SORT_DURATION_DESC;
    o1.label = 'Duration (longest first)';
    options.push(o1);
    const o2 = new SortOption();
    o2.value = INBOX_SORT_DURATION_ASC;
    o2.label = 'Duration (shortest first)';
    options.push(o2);
    const o3 = new SortOption();
    o3.value = INBOX_SORT_DOWNLOAD_DATE_DESC;
    o3.label = 'Download date (newest first)';
    options.push(o3);
    const o4 = new SortOption();
    o4.value = INBOX_SORT_DOWNLOAD_DATE_ASC;
    o4.label = 'Download date (oldest first)';
    options.push(o4);
    return options;
  }

  aboutToAppear(): void {
    this.loadData();
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_FEED_UPDATED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_SUBSCRIPTION_ADDED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_PLAY_STATE_CHANGED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_INBOX_CHANGED, () => {
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
    this.episodeCount = this.vm.episodeDataSource.totalCount();
  }

  private async removeFromInbox(item: FeedItem, index: number): Promise<void> {
    await this.vm.removeFromInbox(item.id);
    this.vm.episodeDataSource.removeItem(index);
    this.episodeCount = this.vm.episodeDataSource.totalCount();
    EventBus.getInstance().publish(EVENT_INBOX_CHANGED, new Object());
  }

  private async removeAllFromInbox(): Promise<void> {
    await this.vm.removeAllFromInbox();
    this.episodeCount = 0;
    EventBus.getInstance().publish(EVENT_INBOX_CHANGED, new Object());
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

  @Builder
  removeButton(item: FeedItem, index: number) {
    Row() {
      Button('Remove')
        .fontSize(14)
        .backgroundColor('#FF5252')
        .fontColor(Color.White)
        .height('100%')
        .onClick(() => {
          this.removeFromInbox(item, index);
        })
    }
    .height('100%')
    .padding({ left: 4, right: 4 })
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      // Title bar (matching Android)
      Row() {
        if (this.showBackButton) {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(22)
            .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            .margin({ right: 12 })
            .onClick(() => {
              this.navPathStack.pop();
            })
        }
        Text('Inbox')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(22)
          .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          .margin({ right: 16 })
          .onClick(() => {
            this.navPathStack.pushPathByName(RouteName.SEARCH, new Object());
          })

        Text('\u22EE')
          .fontSize(22)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .bindMenu([
            {
              value: 'Sort',
              action: () => {
                this.showSortDialog();
              }
            },
            {
              value: 'Refresh',
              action: () => {
                this.loadData();
              }
            },
            {
              value: 'Remove all from inbox',
              action: () => {
                this.removeAllFromInbox();
              }
            }
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
        // Empty state (matching Android)
        Column() {
          Blank().layoutWeight(1)

          Image($r('app.media.ic_inbox'))
            .width(36)
            .height(36)

          Text('No episodes in the inbox')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)

          Text('When new episodes arrive, they will be shown here. You can then decide if you are interested in them or not.')
            .fontSize(14)
            .fontColor('#99000000')
            .margin({ top: 8 })
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })

          Blank().layoutWeight(2)
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          LazyForEach(this.vm.episodeDataSource,
            (item: FeedItem, index: number) => {
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
                    // Metadata: new dot + date · size
                    Row() {
                      Circle()
                        .width(6)
                        .height(6)
                        .fill('#2196F3')
                        .margin({ right: 4, top: 5 })
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

                    // Duration
                    if (item.media !== null) {
                      Text(this.formatTime(item.media.duration))
                        .fontSize(12)
                        .fontColor('#99000000')
                        .margin({ top: 2 })
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  // Download button (matching Android)
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
              .swipeAction({ end: this.removeButton(item, index) })
            },
            (item: FeedItem) => 'inbox_' + item.id.toString()
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
