import { EpisodeDetailParam, FeedDetailParam, RouteName } from '../../common/AppRouter';
import { EpisodeDetailViewModel } from '../../viewmodels/EpisodeDetailViewModel';
import { PlaybackController } from '../../playback/PlaybackController';
import { StringUtils, RichTextSegment } from '../../helpers/StringUtils';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  EventBus,
  EVENT_FAVORITES_CHANGED,
  EVENT_QUEUE_CHANGED,
  EVENT_EPISODE_DOWNLOADED,
  EVENT_EPISODE_PLAY_STATE_CHANGED,
  EVENT_DOWNLOAD_PROGRESS,
  EVENT_DOWNLOAD_FAILED
} from '../../common/EventBus';
import { PLAY_STATE_PLAYED } from '../../common/Constants';
import { Chapter } from '../../models/Chapter';
import { DownloadManager } from '../../network/DownloadManager';
import { DownloadProgressData, DownloadFailedData, DownloadLogData } from '../../common/EventData';
import { promptAction } from '@kit.ArkUI';

@Component
export struct EpisodeDetailComponent {
  private vm: EpisodeDetailViewModel = new EpisodeDetailViewModel();
  @State episodeId: number = 0;
  @State feedId: number = 0;
  @State title: string = '';
  @State feedTitle: string = '';
  @State pubDate: string = '';
  @State durationStr: string = '';
  @State descSegments: RichTextSegment[] = [];
  @State isFavorite: boolean = false;
  @State isInQueue: boolean = false;
  @State isDownloaded: boolean = false;
  @State isLoading: boolean = true;
  @State episodeState: number = 0;
  @State downloadProgress: number = -1;
  @State imageUrl: string = '';
  @StorageLink('currentEpisodeId') currentEpisodeId: number = -1;
  @StorageLink('isPlaying') isPlaying: boolean = false;
  private navContext: NavDestinationContext | undefined = undefined;
  private unsubscribers: (() => void)[] = [];

  private setupEventSubscriptions(): void {
    const bus = EventBus.getInstance();
    this.unsubscribers.push(bus.subscribe(EVENT_FAVORITES_CHANGED, () => {
      this.reloadEpisode();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_QUEUE_CHANGED, () => {
      this.reloadEpisode();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_DOWNLOADED, (data: Object) => {
      if (data instanceof DownloadLogData && data.episodeId === this.episodeId) {
        this.downloadProgress = -1;
        this.reloadEpisode();
      }
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_EPISODE_PLAY_STATE_CHANGED, () => {
      this.reloadEpisode();
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_DOWNLOAD_PROGRESS, (data: Object) => {
      if (data instanceof DownloadProgressData) {
        const progressData: DownloadProgressData = data;
        if (progressData.episodeId === this.episodeId) {
          this.downloadProgress = progressData.percent;
        }
      }
    }));
    this.unsubscribers.push(bus.subscribe(EVENT_DOWNLOAD_FAILED, (data: Object) => {
      if (data instanceof DownloadFailedData) {
        const failedData: DownloadFailedData = data;
        if (failedData.episodeId === this.episodeId) {
          this.downloadProgress = -1;
          promptAction.showToast({ message: 'Download failed' });
        }
      }
    }));
  }

  aboutToDisappear(): void {
    for (let i = 0; i < this.unsubscribers.length; i++) {
      this.unsubscribers[i]();
    }
    this.unsubscribers = [];
  }

  private async reloadEpisode(): Promise<void> {
    await this.vm.loadEpisode(this.episodeId);
    this.syncFromVm();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    await this.vm.loadEpisode(this.episodeId);
    this.syncFromVm();
    this.isLoading = false;
  }

  private syncFromVm(): void {
    this.title = this.vm.title;
    this.feedTitle = this.vm.feedTitle;
    this.pubDate = this.vm.pubDate;
    this.durationStr = this.vm.durationStr;
    this.descSegments = StringUtils.parseHtmlToSegments(this.vm.description);
    this.isFavorite = this.vm.isFavorite;
    this.isInQueue = this.vm.isInQueue;
    this.isDownloaded = this.vm.isDownloaded;
    this.episodeState = this.vm.state;
    this.imageUrl = this.vm.imageUrl;
  }

  private navigateToFeed(): void {
    if (this.feedId > 0 && this.navContext !== undefined) {
      const param = new FeedDetailParam();
      param.feedId = this.feedId;
      this.navContext.pathStack.pushPathByName(RouteName.FEED_DETAIL, param);
    }
  }

  private openUrl(url: string): void {
    const context = getContext(this) as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    context.startAbility(want)
      .then(() => {
        hilog.info(0xFF00, 'EpisodeDetail', 'Opened browser to %{public}s', url);
      })
      .catch((err: BusinessError) => {
        hilog.error(0xFF00, 'EpisodeDetail', 'Failed to open browser: %{public}s, code: %{public}d', err.message, err.code);
        promptAction.showToast({ message: url, duration: 3000 });
      });
  }

  private showOverflowMenu(): void {
    promptAction.showActionMenu({
      title: '',
      buttons: [
        {
          text: 'Skip episode',
          color: '#333333'
        },
        {
          text: this.episodeState === PLAY_STATE_PLAYED ? 'Mark as unplayed' : 'Mark as played',
          color: '#333333'
        },
        {
          text: this.isInQueue ? 'Remove from queue' : 'Add to queue',
          color: '#333333'
        },
        {
          text: 'Reset playback position',
          color: '#333333'
        },
        {
          text: this.isFavorite ? 'Remove from favorites' : 'Add to favorites',
          color: '#333333'
        },
        {
          text: 'Share',
          color: '#333333'
        }
      ]
    }).then((result: promptAction.ActionMenuSuccessResponse) => {
      if (result.index === 0) {
        // Skip episode — mark as played and go back
        this.vm.markPlayed().then(() => {
          this.episodeState = this.vm.state;
          if (this.navContext !== undefined) {
            this.navContext.pathStack.pop();
          }
        });
      } else if (result.index === 1) {
        this.vm.markPlayed().then(() => {
          this.episodeState = this.vm.state;
        });
      } else if (result.index === 2) {
        this.vm.toggleQueue().then(() => {
          this.isInQueue = this.vm.isInQueue;
        });
      } else if (result.index === 3) {
        // Reset playback position
        this.vm.resetPlaybackPosition().then(() => {
          this.reloadEpisode();
        });
      } else if (result.index === 4) {
        this.vm.toggleFavorite().then(() => {
          this.isFavorite = this.vm.isFavorite;
        });
      } else if (result.index === 5) {
        promptAction.showToast({ message: 'Share: ' + this.title });
      }
    }).catch(() => {
      // User cancelled
    });
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
        } else {
          // Feed title (small, above the main header)
          Text(this.feedTitle)
            .fontSize(13)
            .fontColor('#99000000')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .padding({ left: 16, right: 16, top: 12 })

          // Episode header: image + title/date/duration
          Row() {
            if (this.imageUrl.length > 0) {
              Image(this.imageUrl)
                .width(80)
                .height(80)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
                .onClick(() => {
                  this.navigateToFeed();
                })
            } else {
              Column() {
                Text(this.feedTitle.length > 0 ? this.feedTitle.charAt(0).toUpperCase() : '?')
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
              .width(80)
              .height(80)
              .borderRadius(12)
              .backgroundColor('#BDBDBD')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.navigateToFeed();
              })
            }

            Column() {
              Text(this.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row() {
                if (this.pubDate.length > 0) {
                  Text(this.pubDate)
                    .fontSize(12)
                    .fontColor('#99000000')
                }
                if (this.pubDate.length > 0 && this.durationStr.length > 0) {
                  Text(' \u00B7 ')
                    .fontSize(12)
                    .fontColor('#99000000')
                }
                if (this.durationStr.length > 0) {
                  Text(this.durationStr)
                    .fontSize(12)
                    .fontColor('#99000000')
                }
                if (this.isDownloaded) {
                  Text(' \u2713')
                    .fontSize(12)
                    .fontColor('#4CAF50')
                }
              }
              .margin({ top: 4 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 10, bottom: 12 })

          // Two action buttons (matching Android: simple text buttons, no fill)
          Row() {
            // Play/Pause button
            Row({ space: 6 }) {
              SymbolGlyph(this.currentEpisodeId === this.episodeId && this.isPlaying ?
                $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
                .fontSize(16)
                .fontColor(['#333333'])
              Text(this.currentEpisodeId === this.episodeId && this.isPlaying ? 'Pause' :
                this.isDownloaded ? 'Play' : 'Stream')
                .fontSize(14)
                .fontColor('#333333')
            }
            .height(44)
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (this.currentEpisodeId === this.episodeId && this.isPlaying) {
                PlaybackController.getInstance().playPause();
              } else {
                PlaybackController.getInstance().playEpisode(this.episodeId);
              }
            })

            // Divider
            Divider()
              .vertical(true)
              .height(20)
              .color('#E0E0E0')

            // Download / Delete button
            Row({ space: 6 }) {
              if (this.downloadProgress >= 0 && !this.isDownloaded) {
                Stack() {
                  Progress({ value: this.downloadProgress, total: 100, type: ProgressType.Ring })
                    .width(20)
                    .height(20)
                    .color('#007DFF')
                    .backgroundColor('#E0E0E0')
                    .style({ strokeWidth: 3 })
                  Text('\u00D7')
                    .fontSize(12)
                    .fontColor('#333333')
                }
                .width(20)
                .height(20)
                Text('Cancel')
                  .fontSize(14)
                  .fontColor('#333333')
              } else if (this.isDownloaded) {
                Image($r('app.media.ic_delete'))
                  .width(18)
                  .height(18)
                  .fillColor('#333333')
                Text('Delete')
                  .fontSize(14)
                  .fontColor('#333333')
              } else {
                Image($r('app.media.ic_download'))
                  .width(18)
                  .height(18)
                  .fillColor('#333333')
                Text('Download')
                  .fontSize(14)
                  .fontColor('#333333')
              }
            }
            .height(44)
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (this.downloadProgress >= 0 && !this.isDownloaded) {
                DownloadManager.getInstance().cancelDownload(this.episodeId);
                this.downloadProgress = -1;
                return;
              }
              if (this.isDownloaded) {
                DownloadManager.getInstance().deleteDownload(this.episodeId).then(() => {
                  this.isDownloaded = false;
                  this.reloadEpisode();
                });
                return;
              }
              const downloadUrl = this.vm.downloadUrl;
              const mimeType = this.vm.mimeType;
              if (downloadUrl.length > 0) {
                this.downloadProgress = 0;
                DownloadManager.getInstance().downloadEpisode(this.episodeId, downloadUrl, mimeType);
              }
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 12 })

          Divider().color('#F0F0F0')

          // Scrollable area: description + chapters
          Scroll() {
            Column() {
              // Description with clickable links (Text + Span)
              if (this.descSegments.length > 0) {
                Text() {
                  ForEach(this.descSegments, (seg: RichTextSegment, index: number) => {
                    if (seg.href.length > 0) {
                      Span(seg.text)
                        .fontColor('#007DFF')
                        .decoration({ type: TextDecorationType.Underline, color: '#007DFF' })
                        .onClick(() => {
                          this.openUrl(seg.href);
                        })
                    } else {
                      Span(seg.text)
                    }
                  }, (_seg: RichTextSegment, index: number) => 'seg_' + index.toString())
                }
                .fontSize(14)
                .fontColor('#CC000000')
                .lineHeight(22)
                .padding({ left: 16, right: 16, top: 16, bottom: 16 })
                .width('100%')
              }

              // Chapters
              if (this.vm.chapters.length > 0) {
                Divider().color('#F0F0F0')

                Text('Chapters (' + this.vm.chapters.length.toString() + ')')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .padding({ left: 16, right: 16, top: 16, bottom: 8 })
                  .width('100%')

                ForEach(this.vm.chapters, (chapter: Chapter) => {
                  Row() {
                    Text(this.formatTime(chapter.start))
                      .fontSize(12)
                      .fontColor('#007DFF')
                      .width(60)
                    Text(chapter.title)
                      .fontSize(14)
                      .layoutWeight(1)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                }, (chapter: Chapter) => chapter.id.toString())
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
    .title(this.title)
    .menus([
      {
        value: '',
        icon: $r('app.media.ic_web'),
        action: () => {
          if (this.vm.episodeLink.length > 0) {
            this.openUrl(this.vm.episodeLink);
          } else {
            promptAction.showToast({ message: 'No website available' });
          }
        }
      },
      {
        value: '',
        icon: $r('sys.media.ohos_ic_public_more'),
        action: () => {
          this.showOverflowMenu();
        }
      }
    ])
    .onReady((ctx: NavDestinationContext) => {
      this.navContext = ctx;
      if (ctx.pathInfo.param instanceof EpisodeDetailParam) {
        const p: EpisodeDetailParam = ctx.pathInfo.param;
        this.episodeId = p.episodeId;
        this.feedId = p.feedId;
        this.loadData();
        this.setupEventSubscriptions();
      }
    })
  }

  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    return pad(minutes) + ':' + pad(seconds);
  }
}
