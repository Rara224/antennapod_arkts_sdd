import { FeedDetailParam, EpisodeDetailParam, FeedInfoParam, FeedSettingsParam, RouteName } from '../../common/AppRouter';
import { FeedDetailViewModel, EpisodeFilter } from '../../viewmodels/FeedDetailViewModel';
import { StringUtils } from '../../helpers/StringUtils';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import {
  EventBus,
  EVENT_FEED_UPDATED,
  EVENT_EPISODE_DOWNLOADED,
  EVENT_FAVORITES_CHANGED,
  EVENT_EPISODE_PLAY_STATE_CHANGED,
  EVENT_SUBSCRIPTION_REMOVED
} from '../../common/EventBus';
import { FeedItem } from '../../models/FeedItem';
import { FeedEventData } from '../../common/EventData';
import { EmptyStateView } from '../common/EmptyStateView';
import { PlaybackController } from '../../playback/PlaybackController';

@Component
export struct FeedDetailComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  private vm: FeedDetailViewModel = new FeedDetailViewModel();
  @State feedId: number = 0;
  @State feedTitle: string = '';
  @State author: string = '';
  @State feedImageUrl: string = '';
  @State description: string = '';
  @State feedLink: string = '';
  @State feedDownloadUrl: string = '';
  @State episodeCount: number = 0;
  @State isLoading: boolean = true;
  @State showFilterSheet: boolean = false;
  private filter: EpisodeFilter = new EpisodeFilter();
  // Filter toggle states (for UI reactivity)
  @State fPlayed: boolean = false;
  @State fNotPlayed: boolean = false;
  @State fPaused: boolean = false;
  @State fNotPaused: boolean = false;
  @State fHasMedia: boolean = false;
  @State fNoMedia: boolean = false;
  @State fDownloaded: boolean = false;
  @State fNotDownloaded: boolean = false;
  @State sortOrder: number = 0;
  @State isRefreshing: boolean = false;
  private unsubscribers: (() => void)[] = [];

  private showSortMenu(): void {
    promptAction.showActionMenu({
      title: 'Sort',
      buttons: [
        { text: 'Date \u2193 (newest)', color: this.sortOrder === 0 ? '#007DFF' : '#333333' },
        { text: 'Date \u2191 (oldest)', color: this.sortOrder === 1 ? '#007DFF' : '#333333' },
        { text: 'Title A \u2192 Z', color: this.sortOrder === 2 ? '#007DFF' : '#333333' },
        { text: 'Duration \u2191 (short)', color: this.sortOrder === 3 ? '#007DFF' : '#333333' },
        { text: 'Duration \u2193 (long)', color: this.sortOrder === 4 ? '#007DFF' : '#333333' }
      ]
    }).then((result: promptAction.ActionMenuSuccessResponse) => {
      this.sortOrder = result.index;
      this.vm.sortEpisodes(this.sortOrder);
      this.episodeCount = this.vm.episodeDataSource.totalCount();
    }).catch(() => {});
  }

  private openBrowser(url: string): void {
    const context = getContext(this) as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    context.startAbility(want)
      .then(() => {
        hilog.info(0xFF00, 'FeedDetail', 'Opened browser to %{public}s', url);
      })
      .catch((err: BusinessError) => {
        hilog.error(0xFF00, 'FeedDetail', 'Failed to open browser: %{public}s, code: %{public}d', err.message, err.code);
        promptAction.showToast({ message: url, duration: 3000 });
      });
  }

  private async onRefreshFeed(): Promise<void> {
    this.isRefreshing = true;
    try {
      await this.vm.refreshFeed(this.feedId);
      this.feedTitle = this.vm.feedTitle;
      this.author = this.vm.author;
      this.feedImageUrl = this.vm.imageUrl;
      this.description = StringUtils.htmlToPlainText(this.vm.description);
      this.feedLink = this.vm.link;
      this.feedDownloadUrl = this.vm.downloadUrl;
      this.episodeCount = this.vm.episodeCount;
      promptAction.showToast({ message: 'Refreshed' });
    } catch (e) {
      promptAction.showToast({ message: 'Refresh failed' });
    } finally {
      this.isRefreshing = false;
    }
  }

  private async onRemoveAllFromInbox(): Promise<void> {
    await this.vm.removeAllFromInbox(this.feedId);
    this.episodeCount = this.vm.episodeCount;
    promptAction.showToast({ message: 'Removed all from inbox' });
  }

  private showUnsubscribeDialog(): void {
    AlertDialog.show({
      title: 'Unsubscribe / archive',
      message: 'What do you want to do with "' + this.feedTitle + '"?',
      primaryButton: {
        value: 'Archive',
        action: () => {
          this.vm.archiveFeed(this.feedId).then(() => {
            EventBus.getInstance().publish(EVENT_SUBSCRIPTION_REMOVED, new Object());
            promptAction.showToast({ message: 'Archived' });
            this.navPathStack.pop();
          });
        }
      },
      secondaryButton: {
        value: 'Unsubscribe',
        fontColor: '#FF5252',
        action: () => {
          this.vm.deleteFeed(this.feedId).then(() => {
            EventBus.getInstance().publish(EVENT_SUBSCRIPTION_REMOVED, new Object());
            promptAction.showToast({ message: 'Unsubscribed' });
            this.navPathStack.pop();
          });
        }
      }
    });
  }

  private setupEventSubscriptions(): void {
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_FEED_UPDATED, (data: Object) => {
      if (data instanceof FeedEventData) {
        const feedEvent: FeedEventData = data;
        if (feedEvent.feedId === this.feedId) {
          this.loadData();
        }
      } else {
        this.loadData();
      }
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_DOWNLOADED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_FAVORITES_CHANGED, () => {
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
    await this.vm.loadFeed(this.feedId);
    this.feedTitle = this.vm.feedTitle;
    this.author = this.vm.author;
    this.feedImageUrl = this.vm.imageUrl;
    this.description = StringUtils.htmlToPlainText(this.vm.description);
    this.feedLink = this.vm.link;
    this.feedDownloadUrl = this.vm.downloadUrl;
    this.episodeCount = this.vm.episodeCount;
    this.isLoading = false;
  }

  // Format time for progress display: always HH:MM:SS
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
  filterChip(label: string, selected: boolean, onTap: (v: boolean) => void) {
    Text(label)
      .fontSize(14)
      .fontColor(selected ? Color.White : '#333333')
      .textAlign(TextAlign.Center)
      .height(38)
      .layoutWeight(1)
      .borderRadius(19)
      .border({ width: 1, color: selected ? '#1565C0' : '#CCCCCC' })
      .backgroundColor(selected ? '#1565C0' : Color.Transparent)
      .onClick(() => {
        onTap(!selected);
      })
  }

  @Builder
  filterRow(leftLabel: string, leftSel: boolean, rightLabel: string, rightSel: boolean,
    onLeft: (v: boolean) => void, onRight: (v: boolean) => void) {
    Row({ space: 10 }) {
      this.filterChip(leftLabel, leftSel, onLeft)
      this.filterChip(rightLabel, rightSel, onRight)
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .width('100%')
        } else {
          // Dark header with blurred cover background (matching Android)
          Stack() {
            // Layer 1: Blurred cover image
            if (this.feedImageUrl.length > 0) {
              Image(this.feedImageUrl)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .blur(60)
            }

            // Layer 2: Dark overlay
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#80000000')

            // Layer 3: Content
            Column() {
              // Top bar: back + search + more (matching Android)
              Row() {
                SymbolGlyph($r('sys.symbol.arrow_left'))
                  .fontSize(22)
                  .fontColor([Color.White])
                  .width(40)
                  .height(40)
                  .onClick(() => {
                    this.navPathStack.pop();
                  })

                Blank()

                // Search icon (matching Android)
                SymbolGlyph($r('sys.symbol.magnifyingglass'))
                  .fontSize(22)
                  .fontColor([Color.White])
                  .margin({ right: 12 })
                  .onClick(() => {
                    this.navPathStack.pushPathByName(RouteName.SEARCH, new Object());
                  })

                // Overflow menu (matching Android: Sort, Refresh, Visit website, Share, Remove all from inbox, Unsubscribe / archive)
                Text('\u22EE')
                  .fontSize(24)
                  .fontColor(Color.White)
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)
                  .bindMenu([
                    {
                      value: 'Sort',
                      action: () => {
                        this.showSortMenu();
                      }
                    },
                    {
                      value: 'Refresh',
                      action: () => {
                        this.onRefreshFeed();
                      }
                    },
                    {
                      value: 'Visit website',
                      action: () => {
                        if (this.feedLink.length > 0) {
                          this.openBrowser(this.feedLink);
                        }
                      }
                    },
                    {
                      value: 'Share',
                      action: () => {
                        promptAction.showToast({ message: 'Share: ' + this.feedTitle });
                      }
                    },
                    {
                      value: 'Remove all from inbox',
                      action: () => {
                        this.onRemoveAllFromInbox();
                      }
                    },
                    {
                      value: 'Unsubscribe / archive',
                      action: () => {
                        this.showUnsubscribeDialog();
                      }
                    }
                  ])
              }
              .width('100%')
              .padding({ left: 4, right: 4 })

              // Cover image + Feed info
              Row() {
                if (this.feedImageUrl.length > 0) {
                  Image(this.feedImageUrl)
                    .width(110)
                    .height(110)
                    .borderRadius(12)
                    .objectFit(ImageFit.Cover)
                } else {
                  Column() {
                    Text(this.feedTitle.length > 0 ? this.feedTitle.charAt(0).toUpperCase() : '?')
                      .fontSize(48)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.White)
                  }
                  .width(130)
                  .height(130)
                  .borderRadius(12)
                  .backgroundColor('#9E9E9E')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                }

                Column() {
                  Text(this.feedTitle)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  if (this.author.length > 0) {
                    Text(this.author)
                      .fontSize(14)
                      .fontColor('#CCFFFFFF')
                      .margin({ top: 4 })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 16 })
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 12 })

              // Action icons row inside dark header (matching Android)
              Row({ space: 24 }) {
                // Info
                Image($r('app.media.ic_info_white'))
                  .width(22)
                  .height(22)
                  .onClick(() => {
                    const param = new FeedInfoParam();
                    param.feedId = this.feedId;
                    this.navPathStack.pushPathByName(RouteName.FEED_INFO, param);
                  })

                // Filter
                Image($r('app.media.ic_filter_white'))
                  .width(22)
                  .height(22)
                  .onClick(() => {
                    this.showFilterSheet = !this.showFilterSheet;
                  })

                // Settings
                Image($r('app.media.ic_settings_feed_white'))
                  .width(22)
                  .height(22)
                  .onClick(() => {
                    const param = new FeedSettingsParam();
                    param.feedId = this.feedId;
                    this.navPathStack.pushPathByName(RouteName.FEED_SETTINGS, param);
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ bottom: 12 })
            }
            .width('100%')
            .height('100%')
          }
          .width('100%')
          .height(210)

          // Episode list (matching Android layout)
          if (this.vm.episodeDataSource.totalCount() === 0) {
            EmptyStateView({
              icon: '\uD83C\uDFA7',
              message: 'No episodes'
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
                          Text(this.feedTitle.length > 0 ? this.feedTitle.charAt(0).toUpperCase() : '?')
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

                        // Duration or progress bar (matching Android)
                        if (item.media !== null && item.media.position > 0 && item.media.duration > 0) {
                          // Progress: time + bar + total
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

                      // Action button: play (if downloaded) or download (matching Android)
                      if (item.media !== null) {
                        if (item.media.isDownloaded()) {
                          // Play button
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
                          // Download button
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
                      param.feedId = this.feedId;
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
          }
        }
      }
      .width('100%')
      .height('100%')

      // Filter bottom sheet (matching Android)
      if (this.showFilterSheet) {
        // Dimmed backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#40000000')
          .onClick(() => {
            this.showFilterSheet = false;
          })

        // Filter panel
        Column() {
          // Filter toggle grid: 6 rows × 2 columns
          this.filterRow('Played', this.fPlayed, 'Not played', this.fNotPlayed,
            (v: boolean) => { this.fPlayed = v; },
            (v: boolean) => { this.fNotPlayed = v; })
          this.filterRow('Paused', this.fPaused, 'Not paused', this.fNotPaused,
            (v: boolean) => { this.fPaused = v; },
            (v: boolean) => { this.fNotPaused = v; })
          this.filterRow('Is favorite', false, 'Not favorite', false,
            (_v: boolean) => { },
            (_v: boolean) => { })
          this.filterRow('Has media', this.fHasMedia, 'No media', this.fNoMedia,
            (v: boolean) => { this.fHasMedia = v; },
            (v: boolean) => { this.fNoMedia = v; })
          this.filterRow('Queued', false, 'Not queued', false,
            (_v: boolean) => { },
            (_v: boolean) => { })
          this.filterRow('Downloaded', this.fDownloaded, 'Not downloaded', this.fNotDownloaded,
            (v: boolean) => { this.fDownloaded = v; },
            (v: boolean) => { this.fNotDownloaded = v; })

          // Reset + Confirm buttons
          Row() {
            Text('Reset')
              .fontSize(16)
              .fontColor('#1565C0')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .height(44)
              .onClick(() => {
                this.fPlayed = false;
                this.fNotPlayed = false;
                this.fPaused = false;
                this.fNotPaused = false;
                this.fHasMedia = false;
                this.fNoMedia = false;
                this.fDownloaded = false;
                this.fNotDownloaded = false;
                this.filter.reset();
                this.vm.applyFilter(this.filter);
                this.showFilterSheet = false;
              })

            Text('Confirm')
              .fontSize(16)
              .fontColor('#1565C0')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .height(44)
              .onClick(() => {
                this.filter.played = this.fPlayed;
                this.filter.notPlayed = this.fNotPlayed;
                this.filter.paused = this.fPaused;
                this.filter.notPaused = this.fNotPaused;
                this.filter.hasMedia = this.fHasMedia;
                this.filter.noMedia = this.fNoMedia;
                this.filter.downloaded = this.fDownloaded;
                this.filter.notDownloaded = this.fNotDownloaded;
                this.vm.applyFilter(this.filter);
                this.showFilterSheet = false;
              })
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 20 })
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .shadow({ radius: 8, color: '#33000000', offsetY: -2 })
      }
      }
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      if (ctx.pathInfo.param instanceof FeedDetailParam) {
        const p: FeedDetailParam = ctx.pathInfo.param;
        this.feedId = p.feedId;
        this.loadData();
        this.setupEventSubscriptions();
      }
    })
  }
}
