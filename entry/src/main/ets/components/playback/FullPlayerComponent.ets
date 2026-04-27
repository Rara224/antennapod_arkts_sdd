import { PlaybackController } from '../../playback/PlaybackController';
import { EpisodeDetailParam, FeedDetailParam, RouteName } from '../../common/AppRouter';
import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { FeedItemDao } from '../../database/FeedItemDao';
import { FavoritesDao } from '../../database/FavoritesDao';
import {
  EventBus,
  EVENT_FAVORITES_CHANGED
} from '../../common/EventBus';
import { FavoritesChangedData } from '../../common/EventData';
import { ChaptersDialog } from './ChaptersDialog';
import { SleepTimerDialog } from './SleepTimerDialog';
import { SpeedDialog } from './SpeedDialog';

@Component
export struct FullPlayerComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  @StorageLink('isPlaying') isPlaying: boolean = false;
  @StorageLink('isPreparing') isPreparing: boolean = false;
  @StorageLink('currentEpisodeTitle') currentEpisodeTitle: string = '';
  @StorageLink('currentFeedTitle') currentFeedTitle: string = '';
  @StorageLink('currentCoverUrl') currentCoverUrl: string = '';
  @StorageLink('playbackPosition') playbackPosition: number = 0;
  @StorageLink('playbackDuration') playbackDuration: number = 0;
  @StorageLink('playbackSpeed') playbackSpeed: number = 1.0;
  @StorageLink('rewindSecs') rewindSecs: number = 10;
  @StorageLink('fastForwardSecs') fastForwardSecs: number = 30;
  @StorageLink('showRemainTime') showRemainTime: boolean = false;
  @StorageLink('isFullPlayerVisible') isFullPlayerVisible: boolean = false;
  @StorageLink('currentEpisodePubDate') currentEpisodePubDate: string = '';
  @StorageLink('currentEpisodeId') currentEpisodeId: number = -1;
  @StorageLink('currentFeedId') currentFeedId: number = -1;
  @StorageLink('currentFeedLink') currentFeedLink: string = '';
  @StorageLink('skipSilence') skipSilence: boolean = false;
  @State isFavorite: boolean = false;
  private controller: PlaybackController = PlaybackController.getInstance();

  aboutToAppear(): void {
    this.isFullPlayerVisible = true;
    this.checkFavoriteStatus();
  }

  private async checkFavoriteStatus(): Promise<void> {
    if (this.currentEpisodeId > 0) {
      const dao = new FavoritesDao();
      this.isFavorite = await dao.isFavorite(this.currentEpisodeId);
    }
  }

  private async toggleFavorite(): Promise<void> {
    if (this.currentEpisodeId <= 0) {
      return;
    }
    const dao = new FavoritesDao();
    if (this.isFavorite) {
      await dao.removeFromFavorites(this.currentEpisodeId);
      this.isFavorite = false;
      promptAction.showToast({ message: 'Removed from favorites' });
    } else {
      await dao.addToFavorites(this.currentEpisodeId, this.currentFeedId);
      this.isFavorite = true;
      promptAction.showToast({ message: 'Added to favorites' });
    }
    EventBus.getInstance().publish(EVENT_FAVORITES_CHANGED,
      new FavoritesChangedData(this.currentEpisodeId, this.isFavorite));
  }

  aboutToDisappear(): void {
    this.isFullPlayerVisible = false;
  }

  // Always show HH:MM:SS format (matching Android)
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

  // Convert "2026-03-17" to "Mar 17" (matching Android)
  private formatDate(dateStr: string): string {
    if (dateStr.length === 0) {
      return '';
    }
    const months: string[] = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      const monthIndex = parseInt(parts[1]) - 1;
      const day = parseInt(parts[2]);
      if (monthIndex >= 0 && monthIndex < 12) {
        return months[monthIndex] + ' ' + day.toString();
      }
    }
    return dateStr;
  }

  private getFeedSubtitle(): string {
    let subtitle = this.currentFeedTitle;
    const formattedDate = this.formatDate(this.currentEpisodePubDate);
    if (formattedDate.length > 0) {
      if (subtitle.length > 0) {
        subtitle = subtitle + ' \u00B7 ' + formattedDate;
      } else {
        subtitle = formattedDate;
      }
    }
    return subtitle;
  }

  private onOpenPodcast(): void {
    if (this.currentFeedId > 0) {
      const param = new FeedDetailParam();
      param.feedId = this.currentFeedId;
      this.navPathStack.pushPathByName(RouteName.FEED_DETAIL, param);
    }
  }

  private showShareMenu(): void {
    promptAction.showActionMenu({
      title: 'Share',
      buttons: [
        { text: 'Share social message', color: '#333333' },
        { text: 'Share media address', color: '#333333' },
        { text: 'Share media file', color: '#333333' }
      ]
    }).then((result: promptAction.ActionMenuSuccessResponse) => {
      if (result.index === 0) {
        const msg = 'I\'m listening to "' + this.currentEpisodeTitle +
          '" from ' + this.currentFeedTitle +
          (this.currentFeedLink.length > 0 ? ' ' + this.currentFeedLink : '');
        const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, msg);
        pasteboard.getSystemPasteboard().setData(pasteData);
        promptAction.showToast({ message: 'Copied', duration: 2000 });
      } else if (result.index === 1) {
        const mediaUrl = AppStorage.get<string>('currentMediaUrl');
        if (mediaUrl !== undefined && mediaUrl.length > 0) {
          const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, mediaUrl);
          pasteboard.getSystemPasteboard().setData(pasteData);
          promptAction.showToast({ message: 'Media URL copied', duration: 2000 });
        } else {
          promptAction.showToast({ message: 'No media address available' });
        }
      } else if (result.index === 2) {
        if (this.currentEpisodeId > 0) {
          const dao = new FeedItemDao();
          dao.getFeedItem(this.currentEpisodeId).then((item) => {
            if (item !== null && item.media !== null && item.media.isDownloaded()) {
              promptAction.showToast({ message: 'File: ' + item.media.localFileUrl, duration: 3000 });
            } else {
              promptAction.showToast({ message: 'Episode not downloaded' });
            }
          });
        }
      }
    }).catch(() => {
      // Cancelled
    });
  }

  private showSpeedDialog(): void {
    let controllerRef: CustomDialogController | undefined = undefined;
    const dialogController = new CustomDialogController({
      builder: SpeedDialog({
        currentSpeed: this.playbackSpeed,
        skipSilence: this.skipSilence,
        onClose: (): void => {
          if (controllerRef !== undefined) {
            controllerRef.close();
          }
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    controllerRef = dialogController;
    dialogController.open();
  }

  private showSleepTimerDialog(): void {
    let controllerRef: CustomDialogController | undefined = undefined;
    const dialogController = new CustomDialogController({
      builder: SleepTimerDialog({
        onClose: (): void => {
          if (controllerRef !== undefined) {
            controllerRef.close();
          }
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    controllerRef = dialogController;
    dialogController.open();
  }

  private showChaptersDialog(): void {
    let controllerRef: CustomDialogController | undefined = undefined;
    const dialogController = new CustomDialogController({
      builder: ChaptersDialog({
        episodeId: this.currentEpisodeId,
        playbackPosition: this.playbackPosition,
        onClose: (): void => {
          if (controllerRef !== undefined) {
            controllerRef.close();
          }
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    controllerRef = dialogController;
    dialogController.open();
  }

  private onVisitWebsite(): void {
    if (this.currentFeedLink.length > 0) {
      try {
        const ctx = getContext(this) as common.UIAbilityContext;
        ctx.openLink(this.currentFeedLink);
      } catch (e) {
        promptAction.showToast({ message: 'Cannot open website' });
      }
    } else {
      promptAction.showToast({ message: 'No website available' });
    }
  }

  build() {
    NavDestination() {
      Stack() {
      Column() {
        // Top bar: down chevron + [star, sleep, share, more] — matching Android
        Row() {
          // Down arrow — close FullPlayer
          SymbolGlyph($r('sys.symbol.arrow_down'))
            .fontSize(22)
            .fontColor(['#333333'])
            .width(40)
            .height(40)
            .onClick(() => {
              this.navPathStack.pop();
            })

          Blank()

          // Favorite star
          if (this.isFavorite) {
            Text('\u2605')
              .fontSize(22)
              .fontColor('#F5A623')
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .margin({ right: 8 })
              .onClick(() => {
                this.toggleFavorite();
              })
          } else {
            Image($r('app.media.ic_star_border'))
              .width(24)
              .height(24)
              .margin({ right: 8 })
              .onClick(() => {
                this.toggleFavorite();
              })
          }

          // Sleep timer (Android ic_sleep — zzZ icon)
          Image($r('app.media.ic_sleep'))
            .width(24)
            .height(24)
            .margin({ right: 8 })
            .onClick(() => {
              this.showSleepTimerDialog();
            })

          // Share (Android ic_share)
          Image($r('app.media.ic_share'))
            .width(24)
            .height(24)
            .margin({ right: 8 })
            .onClick(() => {
              this.showShareMenu();
            })

          // More (vertical dots) — dropdown menu matching Android style
          Text('\u22EE')
            .fontSize(24)
            .fontColor('#333333')
            .width(40)
            .height(40)
            .textAlign(TextAlign.Center)
            .bindMenu([
              {
                value: 'Open podcast',
                action: () => {
                  this.onOpenPodcast();
                }
              },
              {
                value: 'Visit website',
                action: () => {
                  this.onVisitWebsite();
                }
              }
            ])
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8 })
        .alignItems(VerticalAlign.Center)

        // Large cover image
        Blank().layoutWeight(1)

        if (this.currentCoverUrl.length > 0) {
          Image(this.currentCoverUrl)
            .width('75%')
            .aspectRatio(1)
            .borderRadius(12)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text(this.currentFeedTitle.length > 0 ? this.currentFeedTitle.charAt(0).toUpperCase() : '?')
              .fontSize(64)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width('75%')
          .aspectRatio(1)
          .borderRadius(12)
          .backgroundColor('#9E9E9E')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        Blank().layoutWeight(1)

        // Feed title · Date (formatted as "Mar 17")
        Text(this.getFeedSubtitle())
          .fontSize(14)
          .fontColor('#99000000')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 })
          .padding({ left: 24, right: 24 })

        // Episode title
        Text(this.currentEpisodeTitle.length > 0 ? this.currentEpisodeTitle : 'No episode')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .padding({ left: 24, right: 24 })
          .margin({ bottom: 16 })

        // Shownotes + Chapters pill buttons — matching Android row
        Row() {
          // Shownotes
          Row() {
            Text('\u24D8')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ right: 6 })
            Text('Shownotes')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
          }
          .height(36)
          .borderRadius(18)
          .border({ width: 1, color: '#CCCCCC' })
          .backgroundColor(Color.Transparent)
          .padding({ left: 16, right: 20 })
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (this.currentEpisodeId > 0) {
              const param = new EpisodeDetailParam();
              param.episodeId = this.currentEpisodeId;
              this.navPathStack.pushPathByName(RouteName.EPISODE_DETAIL, param);
            }
          })

          // Chapters
          Row() {
            SymbolGlyph($r('sys.symbol.list_bullet'))
              .fontSize(16)
              .fontColor(['#666666'])
              .margin({ right: 6 })
            Text('Chapters')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
          }
          .height(36)
          .borderRadius(18)
          .border({ width: 1, color: '#CCCCCC' })
          .backgroundColor(Color.Transparent)
          .padding({ left: 16, right: 20 })
          .justifyContent(FlexAlign.Center)
          .margin({ left: 10 })
          .onClick(() => {
            this.showChaptersDialog();
          })
        }
        .margin({ bottom: 20 })

        // Progress slider — blue track (matching Android)
        Column() {
          Slider({
            value: this.playbackDuration > 0 ? this.playbackPosition / this.playbackDuration * 100 : 0,
            min: 0,
            max: 100,
            step: 0.1
          })
            .width('100%')
            .trackThickness(4)
            .selectedColor('#1565C0')
            .trackColor('#E0E0E0')
            .blockColor('#1565C0')
            .onChange((value: number) => {
              if (this.playbackDuration > 0) {
                const newPos = Math.round(value / 100 * this.playbackDuration);
                this.controller.seekTo(newPos);
              }
            })

          // Time labels — always HH:MM:SS
          Row() {
            Text(this.formatTime(this.playbackPosition))
              .fontSize(12)
              .fontColor('#99000000')
            Blank()
            if (this.showRemainTime && this.playbackDuration > 0) {
              Text('-' + this.formatTime(this.playbackDuration - this.playbackPosition))
                .fontSize(12)
                .fontColor('#99000000')
            } else {
              Text(this.formatTime(this.playbackDuration))
                .fontSize(12)
                .fontColor('#99000000')
            }
          }
          .width('100%')
        }
        .padding({ left: 24, right: 24 })
        .margin({ bottom: 8 })

        // Control buttons row — all icons from Android SVG resources
        Row() {
          // Speed button: Android ic_playback_speed + speed label
          Column() {
            Image($r('app.media.ic_playback_speed'))
              .width(32)
              .height(32)
            Text(this.playbackSpeed.toFixed(2))
              .fontSize(12)
              .fontColor('#333333')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.showSpeedDialog();
          })

          // Rewind: Android ic_fast_rewind + seconds label
          Column() {
            Image($r('app.media.ic_fast_rewind'))
              .width(32)
              .height(32)
            Text(this.rewindSecs.toString())
              .fontSize(12)
              .fontColor('#333333')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.controller.rewind();
          })

          // Play/Pause — circular outline button with loading indicator
          Column() {
            if (this.isPreparing) {
              LoadingProgress()
                .width(28)
                .height(28)
                .color('#333333')
            } else {
              SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
                .fontSize(28)
                .fontColor(['#333333'])
            }
          }
          .width(56)
          .height(56)
          .borderRadius(28)
          .border({ width: 2, color: '#333333' })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.controller.playPause();
          })

          // Fast forward: Android ic_fast_forward + seconds label
          Column() {
            Image($r('app.media.ic_fast_forward'))
              .width(32)
              .height(32)
            Text(this.fastForwardSecs.toString())
              .fontSize(12)
              .fontColor('#333333')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.controller.fastForward();
          })

          // Skip next: Android ic_skip_next
          Column() {
            Image($r('app.media.ic_skip_next'))
              .width(32)
              .height(32)
            Text(' ')
              .fontSize(12)
              .margin({ top: 2 })
              .visibility(Visibility.Hidden)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.controller.skipToNext();
          })
        }
        .width('100%')
        .height(72)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)

      }
    }
    .hideTitleBar(true)
  }
}
