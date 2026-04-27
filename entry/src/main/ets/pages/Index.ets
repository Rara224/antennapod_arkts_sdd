import { GlobalState } from '../common/GlobalState';
import { PlaybackController } from '../playback/PlaybackController';
import { DefaultFeedInitializer } from '../network/DefaultFeedInitializer';
import { RouteName } from '../common/AppRouter';
import { HomeComponent } from '../components/home/HomeComponent';
import { SubscriptionComponent } from '../components/subscription/SubscriptionComponent';
import { QueueComponent } from '../components/queue/QueueComponent';
import { InboxComponent } from '../components/episodes/InboxComponent';
// MoreComponent is now a popup menu, no longer a separate page
import { AllEpisodesComponent } from '../components/episodes/AllEpisodesComponent';
import { SearchComponent } from '../components/search/SearchComponent';
import { FeedDetailComponent } from '../components/feed/FeedDetailComponent';
import { EpisodeDetailComponent } from '../components/episodes/EpisodeDetailComponent';
import { FeedSettingsComponent } from '../components/feed/FeedSettingsComponent';
import { FeedInfoComponent } from '../components/feed/FeedInfoComponent';
import { AddFeedComponent } from '../components/discovery/AddFeedComponent';
import { OnlineFeedViewComponent } from '../components/discovery/OnlineFeedViewComponent';
import { PlaybackHistoryComponent } from '../components/playback/PlaybackHistoryComponent';
import { DownloadsComponent } from '../components/episodes/DownloadsComponent';
import { SettingsComponent } from '../components/preferences/SettingsComponent';
import { SettingsDetailComponent } from '../components/preferences/SettingsDetailComponent';
import { SettingsSearchComponent } from '../components/preferences/SettingsSearchComponent';
import { VideoPlayerComponent } from '../components/playback/VideoPlayerComponent';
import { OpmlImportComponent } from '../components/common/OpmlImportComponent';
import { StatisticsComponent } from '../components/statistics/StatisticsComponent';
import { FullPlayerComponent } from '../components/playback/FullPlayerComponent';
import { SearchPodcastsComponent } from '../components/discovery/SearchPodcastsComponent';
import { CustomizeNavigationDialog, NavigationItem } from '../components/common/CustomizeNavigationDialog';

@Entry
@Component
struct Index {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('currentTabIndex') currentTabIndex: number = 0;
  @StorageLink('isPlayerVisible') isPlayerVisible: boolean = false;
  @StorageLink('isPlaying') isPlaying: boolean = false;
  @StorageLink('currentEpisodeTitle') currentEpisodeTitle: string = '';
  @StorageLink('currentFeedTitle') currentFeedTitle: string = '';
  @StorageLink('playbackPosition') playbackPosition: number = 0;
  @StorageLink('playbackDuration') playbackDuration: number = 0;
  @StorageLink('currentCoverUrl') currentCoverUrl: string = '';
  @StorageLink('isFullPlayerVisible') isFullPlayerVisible: boolean = false;
  @StorageLink('isSettingsVisible') isSettingsVisible: boolean = false;
  @StorageLink('isPreparing') isPreparing: boolean = false;
  @StorageLink('dbReady') dbReady: boolean = false;
  @State showMoreMenu: boolean = false;
  @State showCustomizeNavigationDialog: boolean = false;

  aboutToAppear(): void {
    GlobalState.init(getContext(this)).then(async () => {
      PlaybackController.getInstance().restoreLastPlayedEpisode();
      await DefaultFeedInitializer.initDefaultFeedsIfEmpty();
    });
  }

  @Builder
  routerMap(name: string) {
    if (name === RouteName.FEED_DETAIL) {
      FeedDetailComponent()
    } else if (name === RouteName.EPISODE_DETAIL) {
      EpisodeDetailComponent()
    } else if (name === RouteName.FEED_SETTINGS) {
      FeedSettingsComponent()
    } else if (name === RouteName.FEED_INFO) {
      FeedInfoComponent()
    } else if (name === RouteName.ONLINE_FEED_VIEW) {
      OnlineFeedViewComponent()
    } else if (name === RouteName.ADD_FEED) {
      AddFeedComponent()
    } else if (name === RouteName.PLAYBACK_HISTORY) {
      PlaybackHistoryComponent()
    } else if (name === RouteName.DOWNLOADS) {
      NavDestination() {
        DownloadsComponent()
      }
      .hideTitleBar(true)
    } else if (name === RouteName.STATISTICS) {
      StatisticsComponent()
    } else if (name === RouteName.SETTINGS) {
      SettingsComponent()
    } else if (name === RouteName.SETTINGS_DETAIL) {
      SettingsDetailComponent()
    } else if (name === RouteName.SETTINGS_SEARCH) {
      SettingsSearchComponent()
    } else if (name === RouteName.VIDEO_PLAYER) {
      VideoPlayerComponent()
    } else if (name === RouteName.OPML_IMPORT) {
      OpmlImportComponent()
    } else if (name === RouteName.FULL_PLAYER) {
      FullPlayerComponent()
    } else if (name === RouteName.SEARCH_PODCASTS) {
      SearchPodcastsComponent()
    } else if (name === RouteName.EPISODES) {
      NavDestination() {
        AllEpisodesComponent()
      }
      .hideTitleBar(true)
    } else if (name === RouteName.INBOX) {
      NavDestination() {
        InboxComponent({ showBackButton: true })
      }
      .hideTitleBar(true)
    } else if (name === RouteName.SUBSCRIPTIONS) {
      NavDestination() {
        SubscriptionComponent({ showBackButton: true })
      }
      .hideTitleBar(true)
    } else if (name === RouteName.SEARCH) {
      SearchComponent()
    } else if (name === RouteName.QUEUE) {
      NavDestination() {
        QueueComponent({ showBackButton: true })
      }
      .hideTitleBar(true)
    }
  }

  @Builder
  tabBarItem(index: number, title: Resource, icon: Resource) {
    Column() {
      // Pill-shaped gray background for selected tab icon (Material 3 style)
      Column() {
        SymbolGlyph(icon)
          .fontSize(22)
          .fontColor(this.currentTabIndex === index ?
            [Color.Black] : ['#99182431'])
      }
      .width(48)
      .height(28)
      .borderRadius(14)
      .backgroundColor(this.currentTabIndex === index ? '#1F000000' : '#00000000')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(title)
        .fontSize(10)
        .fontColor(this.currentTabIndex === index ? '#182431' : '#99182431')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .onClick(() => {
      if (this.navPathStack.size() > 0) {
        this.navPathStack.clear();
      }
      this.currentTabIndex = index;
    })
  }

  private navigateFromMore(route: string): void {
    this.showMoreMenu = false;
    this.navPathStack.pushPathByName(route, new Object());
  }

  private openCustomizeNavigation(): void {
    this.showMoreMenu = false;
    this.showCustomizeNavigationDialog = true;
  }

  private closeCustomizeNavigation(): void {
    this.showCustomizeNavigationDialog = false;
  }

  private confirmCustomizeNavigation(_items: NavigationItem[]): void {
    this.closeCustomizeNavigation();
  }

  @Builder
  moreMenuRow(icon: Resource, label: string) {
    Row() {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor('#333333')
        .margin({ right: 16 })
      Text(label)
        .fontSize(15)
    }
    .width('100%')
    .padding({ left: 20, right: 24, top: 13, bottom: 13 })
  }

  private getProgressPercent(): number {
    if (this.playbackDuration > 0 && this.playbackPosition > 0) {
      return Math.round(this.playbackPosition * 100 / this.playbackDuration);
    }
    return 0;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // Content area: Navigation + tab content
        Navigation(this.navPathStack) {
        if (this.dbReady) {
          // Tab content — show based on currentTabIndex
          if (this.currentTabIndex === 0) {
            HomeComponent()
          } else if (this.currentTabIndex === 1) {
            QueueComponent()
          } else if (this.currentTabIndex === 2) {
            InboxComponent()
          } else {
            SubscriptionComponent()
          }
        } else {
          Column() {
            LoadingProgress().width(48).height(48)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }
      .navDestination(this.routerMap)
      .hideTitleBar(true)
      .mode(NavigationMode.Stack)
      .width('100%')
      .layoutWeight(1)

      // MiniPlayer — hidden when FullPlayer or Settings is open
      if (this.isPlayerVisible && !this.isFullPlayerVisible && !this.isSettingsVisible) {
        Column() {
          Row() {
            if (this.currentCoverUrl.length > 0) {
              Image(this.currentCoverUrl)
                .width(40)
                .height(40)
                .borderRadius(6)
                .objectFit(ImageFit.Cover)
                .margin({ right: 10 })
            } else {
              Column() {
                Text(this.currentFeedTitle.length > 0 ? this.currentFeedTitle.charAt(0).toUpperCase() : '?')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
              .width(40)
              .height(40)
              .borderRadius(6)
              .backgroundColor('#BDBDBD')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ right: 10 })
            }

            Column() {
              Text(this.currentEpisodeTitle.length > 0 ? this.currentEpisodeTitle : 'No episode playing')
                .fontSize(14)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              if (this.currentFeedTitle.length > 0) {
                Text(this.currentFeedTitle)
                  .fontSize(12)
                  .fontColor('#99000000')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column() {
              if (this.isPreparing) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color('#333333')
              } else {
                SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
                  .fontSize(20)
                  .fontColor(['#333333'])
              }
            }
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor('#E8E8E8')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 8 })
            .onClick(() => {
              PlaybackController.getInstance().playPause();
            })
          }
          .padding({ left: 12, right: 16, top: 8, bottom: 8 })
          .width('100%')

          Progress({ value: this.getProgressPercent(), total: 100, type: ProgressType.Linear })
            .height(2)
            .width('100%')
            .color('#007DFF')
            .backgroundColor('#E0E0E0')
        }
        .width('100%')
        .backgroundColor('#FAFAFA')
        .shadow({ radius: 4, color: '#1A000000', offsetY: -2 })
        .onClick(() => {
          this.navPathStack.pushPathByName(RouteName.FULL_PLAYER, new Object());
        })
      }

      // Custom tab bar — hidden when Settings is open
      if (!this.isSettingsVisible) {
        Row() {
          this.tabBarItem(0, $r('app.string.tab_home'), $r('sys.symbol.house'))
          this.tabBarItem(1, $r('app.string.tab_queue'), $r('sys.symbol.list_bullet'))
          this.tabBarItem(2, $r('app.string.tab_inbox'), $r('sys.symbol.envelope'))
          this.tabBarItem(3, $r('app.string.tab_subscriptions'), $r('sys.symbol.square_grid_2x2'))
          // More tab — toggles popup menu instead of switching page
          Column() {
            Column() {
              Text('\u22EE')
                .fontSize(22)
                .fontColor(this.showMoreMenu ? '#182431' : '#99182431')
            }
            .width(48)
            .height(28)
            .borderRadius(14)
            .backgroundColor(this.showMoreMenu ? '#1F000000' : '#00000000')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text($r('app.string.tab_more'))
              .fontSize(10)
              .fontColor(this.showMoreMenu ? '#182431' : '#99182431')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .height('100%')
          .onClick(() => {
            this.showMoreMenu = !this.showMoreMenu;
          })
        }
        .width('100%')
        .height(56)
        .backgroundColor(Color.White)
        .border({ width: { top: 0.5 }, color: '#E0E0E0' })
      }
      }
      .width('100%')
      .height('100%')

      // More menu overlay
      if (this.showMoreMenu) {
        // Dismiss layer
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#00000000')
          .onClick(() => {
            this.showMoreMenu = false;
          })

        // Menu panel positioned at bottom-end
        Column() {
          Row() {
            this.moreMenuRow($r('app.media.ic_feed'), 'Episodes')
          }.onClick(() => { this.navigateFromMore(RouteName.EPISODES); })

          Row() {
            this.moreMenuRow($r('app.media.ic_download'), 'Downloads')
          }.onClick(() => { this.navigateFromMore(RouteName.DOWNLOADS); })

          Row() {
            this.moreMenuRow($r('app.media.ic_history'), 'Playback history')
          }.onClick(() => { this.navigateFromMore(RouteName.PLAYBACK_HISTORY); })

          Row() {
            this.moreMenuRow($r('app.media.ic_chart_box'), 'Statistics')
          }.onClick(() => { this.navigateFromMore(RouteName.STATISTICS); })

          Row() {
            this.moreMenuRow($r('app.media.ic_add'), 'Add podcast')
          }.onClick(() => { this.navigateFromMore(RouteName.ADD_FEED); })

          Row() {
            this.moreMenuRow($r('app.media.ic_pencil'), 'Customize navigation')
          }.onClick(() => { this.openCustomizeNavigation(); })

          Row() {
            this.moreMenuRow($r('app.media.ic_settings'), 'Settings')
          }.onClick(() => { this.navigateFromMore(RouteName.SETTINGS); })
        }
        .width(220)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({ radius: 12, color: '#30000000', offsetY: 2 })
        .margin({ bottom: 60, right: 8 })
      }

      if (this.showCustomizeNavigationDialog) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#33000000')
          .onClick(() => {
            this.closeCustomizeNavigation();
          })

        Column() {
          CustomizeNavigationDialog({
            onCancel: () => {
              this.closeCustomizeNavigation();
            },
            onConfirm: (items: NavigationItem[]) => {
              this.confirmCustomizeNavigation(items);
            }
          })
            .width('88%')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
