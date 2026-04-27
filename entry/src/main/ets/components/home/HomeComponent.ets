import { HomeViewModel } from '../../viewmodels/HomeViewModel';
import {
  EventBus,
  EVENT_FEED_LIST_CHANGED,
  EVENT_FEED_UPDATED,
  EVENT_SUBSCRIPTION_ADDED,
  EVENT_SUBSCRIPTION_REMOVED,
  EVENT_EPISODE_PLAY_STATE_CHANGED
} from '../../common/EventBus';
import { FeedItem } from '../../models/FeedItem';
import { Feed } from '../../models/Feed';
import { EpisodeDetailParam, FeedDetailParam, RouteName } from '../../common/AppRouter';
import { SectionHeader } from '../common/SectionHeader';
import { EmptyStateView } from '../common/EmptyStateView';
import { HorizontalEpisodeCard } from './HorizontalEpisodeCard';
import { TAB_INDEX_QUEUE, TAB_INDEX_INBOX, TAB_INDEX_SUBSCRIPTIONS } from '../../common/Constants';
import { UserPreferences } from '../../helpers/UserPreferences';

@Component
export struct HomeComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @StorageLink('currentTabIndex') currentTabIndex: number = 0;
  private vm: HomeViewModel = new HomeViewModel();
  @State subscriptionCount: number = 0;
  @State isLoading: boolean = true;
  @State continueCount: number = 0;
  @State newCount: number = 0;
  @State recentCount: number = 0;
  @State surpriseCount: number = 0;
  @State classicCount: number = 0;
  @State downloadCount: number = 0;
  @State showConfigSheet: boolean = false;
  @State hiddenSections: Set<string> = new Set<string>();
  @State configDraft: Set<string> = new Set<string>();
  private unsubscribers: (() => void)[] = [];

  private readonly SECTION_CONTINUE: string = 'continue_listening';
  private readonly SECTION_NEW: string = 'see_whats_new';
  private readonly SECTION_SURPRISE: string = 'get_surprised';
  private readonly SECTION_CLASSICS: string = 'check_classics';
  private readonly SECTION_DOWNLOADS: string = 'manage_downloads';

  aboutToAppear(): void {
    this.hiddenSections = UserPreferences.getInstance().getHiddenHomeSections();
    this.loadData();
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_FEED_LIST_CHANGED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_FEED_UPDATED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_SUBSCRIPTION_ADDED, () => {
      this.loadData();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_SUBSCRIPTION_REMOVED, () => {
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
    await this.vm.loadData();
    this.subscriptionCount = this.vm.subscriptionCount;
    this.continueCount = this.vm.continueListening.totalCount();
    this.newCount = this.vm.newEpisodeCount;
    this.recentCount = this.vm.recentEpisodes.totalCount();
    this.surpriseCount = this.vm.surpriseEpisodes.totalCount();
    this.classicCount = this.vm.classicFeeds.totalCount();
    this.downloadCount = this.vm.downloadedEpisodes.totalCount();
    this.isLoading = false;
  }

  private navigateToEpisode(item: FeedItem): void {
    const param = new EpisodeDetailParam();
    param.episodeId = item.id;
    param.feedId = item.feedId;
    this.navPathStack.pushPathByName(RouteName.EPISODE_DETAIL, param);
  }

  private isSectionVisible(key: string): boolean {
    return !this.hiddenSections.has(key);
  }

  private toggleConfigDraft(key: string): void {
    const next = new Set<string>(this.configDraft);
    if (next.has(key)) {
      next.delete(key);
    } else {
      next.add(key);
    }
    this.configDraft = next;
  }

  private getProgressPercent(item: FeedItem): number {
    if (item.media !== null && item.media.duration > 0 && item.media.position > 0) {
      return Math.round(item.media.position * 100 / item.media.duration);
    }
    return 0;
  }

  @Builder
  newEpisodeItem(item: FeedItem) {
    Row() {
      // Cover image
      if (item.getImageLocation().length > 0) {
        Image(item.getImageLocation())
          .width(56)
          .height(56)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text(item.feed !== null && item.feed.getDisplayTitle().length > 0 ?
            item.feed.getDisplayTitle().charAt(0).toUpperCase() : '?')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(56)
        .height(56)
        .borderRadius(6)
        .backgroundColor('#BDBDBD')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // Content column
      Column() {
        // Meta: date · size (matching Android)
        Row() {
          Text(item.getShortPubDateStr())
            .fontSize(12)
            .fontColor('#99000000')
          if (item.media !== null && item.media.getSizeStr().length > 0) {
            Text(' \u00B7 ' + item.media.getSizeStr())
              .fontSize(12)
              .fontColor('#99000000')
          }
        }
        .alignItems(VerticalAlign.Center)

        // Title
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
          .width('100%')

        // Duration
        if (item.media !== null) {
          Text(item.media.getDurationStr())
            .fontSize(12)
            .fontColor('#99000000')
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // Download button (matching Android: ic_download with circle border)
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
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.navigateToEpisode(item);
    })
  }

  @Builder
  downloadedItem(item: FeedItem) {
    Row() {
      // Cover image
      if (item.getImageLocation().length > 0) {
        Image(item.getImageLocation())
          .width(56)
          .height(56)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text(item.feed !== null && item.feed.getDisplayTitle().length > 0 ?
            item.feed.getDisplayTitle().charAt(0).toUpperCase() : '?')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(56)
        .height(56)
        .borderRadius(6)
        .backgroundColor('#BDBDBD')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // Content column
      Column() {
        // Meta: date · size (matching Android)
        Row() {
          Text(item.getShortPubDateStr())
            .fontSize(12)
            .fontColor('#99000000')
          if (item.media !== null && item.media.getSizeStr().length > 0) {
            Text(' \u00B7 ' + item.media.getSizeStr())
              .fontSize(12)
              .fontColor('#99000000')
          }
        }
        .alignItems(VerticalAlign.Center)

        // Title
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
          .width('100%')

        // Duration with progress bar
        if (item.media !== null) {
          if (item.media.position > 0 && item.media.duration > 0) {
            Row() {
              Text(item.media.getPositionStr())
                .fontSize(11)
                .fontColor('#99000000')
              Progress({
                value: this.getProgressPercent(item),
                total: 100,
                type: ProgressType.Linear
              })
                .layoutWeight(1)
                .height(3)
                .margin({ left: 6, right: 6 })
                .color('#1565C0')
                .backgroundColor('#E0E0E0')
              Text(item.media.getDurationStr())
                .fontSize(11)
                .fontColor('#99000000')
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 4 })
          } else {
            Text(item.media.getDurationStr())
              .fontSize(12)
              .fontColor('#99000000')
              .margin({ top: 2 })
          }
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // Play button (outlined circle)
      Column() {
        SymbolGlyph($r('sys.symbol.play_fill'))
          .fontSize(18)
          .fontColor(['#333333'])
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor('#333333')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.navigateToEpisode(item);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
    Column() {
      // Title bar: "Home" + search icon + overflow menu
      Row() {
        Text('Home')
          .fontSize(22)
          .fontWeight(FontWeight.Normal)
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
              value: 'Refresh',
              action: () => {
                this.loadData();
              }
            },
            {
              value: 'Configure home screen',
              action: () => {
                this.configDraft = new Set<string>(this.hiddenSections);
                this.showConfigSheet = true;
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
      } else if (this.subscriptionCount === 0) {
        // Welcome page (matching Android)
        Column() {
          Blank().layoutWeight(1)

          // AntennaPod logo (from Android project)
          Image($r('app.media.ic_launcher_foreground'))
            .width(100)
            .height(100)
            .objectFit(ImageFit.Contain)

          Text('Welcome to AntennaPod!')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
            .textAlign(TextAlign.Center)

          Text('You are not subscribed to any podcasts yet. Open the menu to add a podcast.')
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
        Scroll() {
          Column() {
            // ===== Continue Listening (horizontal cards) =====
            if (this.continueCount > 0 && this.isSectionVisible(this.SECTION_CONTINUE)) {
              SectionHeader({
                title: 'Continue listening',
                showMore: true,
                moreText: 'Queue \u00BB',
                onMoreClick: () => {
                  this.navPathStack.pushPathByName(RouteName.QUEUE, new Object());
                }
              })
              List({ space: 8 }) {
                ForEach(this.vm.continueListening.getAll(), (item: FeedItem) => {
                  ListItem() {
                    HorizontalEpisodeCard({
                      title: item.title,
                      pubDate: item.getShortPubDateStr(),
                      imageUrl: item.getImageLocation(),
                      showPlayButton: item.media !== null && item.media.isDownloaded(),
                      onButtonClick: () => {
                        this.navigateToEpisode(item);
                      },
                      onCardClick: () => {
                        this.navigateToEpisode(item);
                      }
                    })
                  }
                }, (item: FeedItem) => item.id.toString() + '_' + item.state.toString() +
                  '_' + (item.media !== null ? item.media.localFileUrl : ''))
              }
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
              .padding({ left: 12, right: 12 })
              .height(200)
              .width('100%')
              .alignListItem(ListItemAlign.Start)
            }

            // ===== See what's new (list items with download button) =====
            if (this.isSectionVisible(this.SECTION_NEW)) {
              SectionHeader({
                title: "See what's new",
                showMore: true,
                moreText: 'Inbox \u00BB',
                badgeCount: this.newCount,
                onMoreClick: () => {
                  this.navPathStack.pushPathByName(RouteName.INBOX, new Object());
                }
              })
              if (this.newCount > 0) {
                ForEach(this.vm.newEpisodes.getAll(), (item: FeedItem) => {
                  this.newEpisodeItem(item)
                }, (item: FeedItem) => 'new_' + item.id.toString())
              } else {
                Text('New episodes will show up here. You can then decide whether you are interested in them.')
                  .fontSize(14)
                  .fontColor('#666666')
                  .textAlign(TextAlign.Center)
                  .padding({ left: 32, right: 32, top: 8, bottom: 16 })
                  .width('100%')
              }
            }

            // ===== Get surprised (horizontal cards with download overlay) =====
            if (this.surpriseCount > 0 && this.isSectionVisible(this.SECTION_SURPRISE)) {
              SectionHeader({
                title: 'Get surprised',
                showMore: true,
                moreText: 'Episodes \u00BB',
                showShuffleIcon: true,
                onMoreClick: () => {
                  this.navPathStack.pushPathByName(RouteName.EPISODES, new Object());
                }
              })
              List({ space: 8 }) {
                ForEach(this.vm.surpriseEpisodes.getAll(), (item: FeedItem) => {
                  ListItem() {
                    HorizontalEpisodeCard({
                      title: item.title,
                      pubDate: item.getShortPubDateStr(),
                      imageUrl: item.getImageLocation(),
                      showPlayButton: false,
                      onButtonClick: () => {
                        this.navigateToEpisode(item);
                      },
                      onCardClick: () => {
                        this.navigateToEpisode(item);
                      }
                    })
                  }
                }, (item: FeedItem) => 'surprise_' + item.id.toString() + '_' + item.state.toString())
              }
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
              .padding({ left: 12, right: 12 })
              .width('100%')
              .height(200)
              .alignListItem(ListItemAlign.Start)
            }

            // ===== Check your classics (horizontal feed covers) =====
            if (this.classicCount > 0 && this.isSectionVisible(this.SECTION_CLASSICS)) {
              SectionHeader({
                title: 'Check your classics',
                showMore: true,
                moreText: 'Subscriptions \u00BB',
                onMoreClick: () => {
                  this.navPathStack.pushPathByName(RouteName.SUBSCRIPTIONS, new Object());
                }
              })
              List({ space: 8 }) {
                ForEach(this.vm.classicFeeds.getAll(), (feed: Feed) => {
                  ListItem() {
                    if (feed.imageUrl.length > 0) {
                      Image(feed.imageUrl)
                        .width(100)
                        .height(100)
                        .borderRadius(8)
                        .objectFit(ImageFit.Cover)
                    } else {
                      Column() {
                        Text(feed.getDisplayTitle().length > 0 ?
                          feed.getDisplayTitle().charAt(0).toUpperCase() : '?')
                          .fontSize(28)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.White)
                      }
                      .width(100)
                      .height(100)
                      .borderRadius(8)
                      .backgroundColor('#9E9E9E')
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                    }
                  }
                  .onClick(() => {
                    const param = new FeedDetailParam();
                    param.feedId = feed.id;
                    this.navPathStack.pushPathByName(RouteName.FEED_DETAIL, param);
                  })
                }, (feed: Feed) => 'classic_' + feed.id.toString())
              }
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Off)
              .padding({ left: 12, right: 12 })
              .height(108)
              .width('100%')
              .alignListItem(ListItemAlign.Start)
            }

            // ===== Manage downloads (list items with play button) =====
            if (this.isSectionVisible(this.SECTION_DOWNLOADS)) {
              SectionHeader({
                title: 'Manage downloads',
                showMore: true,
                moreText: 'Downloads \u00BB',
                onMoreClick: () => {
                  this.navPathStack.pushPathByName(RouteName.DOWNLOADS, new Object());
                }
              })
              if (this.downloadCount > 0) {
                ForEach(this.vm.downloadedEpisodes.getAll(), (item: FeedItem) => {
                  this.downloadedItem(item)
                }, (item: FeedItem) => 'dl_' + item.id.toString() +
                  '_' + (item.media !== null ? item.media.position.toString() : '0'))
              } else {
                Text('You can download any episode to listen to it offline.')
                  .fontSize(14)
                  .fontColor('#666666')
                  .textAlign(TextAlign.Center)
                  .padding({ left: 32, right: 32, top: 8, bottom: 16 })
                  .width('100%')
              }
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')

    // Centered dialog overlay
    if (this.showConfigSheet) {
      // Dimmed backdrop
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#40000000')
        .onClick(() => {
          this.showConfigSheet = false;
        })

      // Dialog panel
      Column() {
        this.configSheetContent()
      }
      .width('85%')
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 16, color: '#30000000', offsetY: 4 })
    }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  configItemRow(label: string, key: string) {
    Row() {
      // 6-dot drag handle
      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Circle().width(4).height(4).fill('#99000000')
          Circle().width(4).height(4).fill('#99000000')
        }
        Row({ space: 6 }) {
          Circle().width(4).height(4).fill('#99000000')
          Circle().width(4).height(4).fill('#99000000')
        }
        Row({ space: 6 }) {
          Circle().width(4).height(4).fill('#99000000')
          Circle().width(4).height(4).fill('#99000000')
        }
      }
      .width(32)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(label)
        .fontSize(16)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 24, top: 14, bottom: 14 })
    .onClick(() => {
      this.toggleConfigDraft(key);
    })
  }

  private getAllSectionKeys(): string[] {
    return [
      this.SECTION_CONTINUE,
      this.SECTION_NEW,
      this.SECTION_SURPRISE,
      this.SECTION_CLASSICS,
      this.SECTION_DOWNLOADS
    ];
  }

  private getSectionLabel(key: string): string {
    if (key === this.SECTION_CONTINUE) {
      return 'Continue listening';
    } else if (key === this.SECTION_NEW) {
      return "See what's new";
    } else if (key === this.SECTION_SURPRISE) {
      return 'Get surprised';
    } else if (key === this.SECTION_CLASSICS) {
      return 'Check your classics';
    } else {
      return 'Manage downloads';
    }
  }

  @Builder
  configSheetContent() {
    Column() {
      // Title
      Text('Configure home screen')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 24, top: 20, bottom: 12 })
        .width('100%')

      // "Shown" header
      Text('Shown')
        .fontSize(13)
        .fontColor('#99000000')
        .padding({ left: 24, top: 8, bottom: 8 })
        .width('100%')
        .backgroundColor('#F8F8F8')

      // Shown items
      ForEach(this.getAllSectionKeys(), (key: string) => {
        if (!this.configDraft.has(key)) {
          this.configItemRow(this.getSectionLabel(key), key)
          Divider().color('#F0F0F0').margin({ left: 48 })
        }
      }, (key: string) => 'shown_' + key + '_' + (this.configDraft.has(key) ? '1' : '0'))

      // "Hidden" header
      Text('Hidden')
        .fontSize(13)
        .fontColor('#99000000')
        .padding({ left: 24, top: 8, bottom: 8 })
        .width('100%')
        .backgroundColor('#F8F8F8')

      // Hidden items
      ForEach(this.getAllSectionKeys(), (key: string) => {
        if (this.configDraft.has(key)) {
          Row() {
            Text(this.getSectionLabel(key))
              .fontSize(16)
              .fontColor('#99000000')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 48, right: 24, top: 14, bottom: 14 })
          .onClick(() => {
            this.toggleConfigDraft(key);
          })

          Divider().color('#F0F0F0').margin({ left: 48 })
        }
      }, (key: string) => 'hidden_' + key + '_' + (this.configDraft.has(key) ? '1' : '0'))

      // Bottom buttons
      Row() {
        Text('Reset')
          .fontSize(15)
          .fontColor('#007DFF')
          .onClick(() => {
            this.configDraft = new Set<string>();
          })

        Blank()

        Text('Cancel')
          .fontSize(15)
          .fontColor('#007DFF')
          .margin({ right: 24 })
          .onClick(() => {
            this.showConfigSheet = false;
          })
        Text('OK')
          .fontSize(15)
          .fontColor('#007DFF')
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.hiddenSections = new Set<string>(this.configDraft);
            UserPreferences.getInstance().setHiddenHomeSections(this.hiddenSections);
            this.showConfigSheet = false;
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 8 })
    }
    .width('100%')
  }
}
