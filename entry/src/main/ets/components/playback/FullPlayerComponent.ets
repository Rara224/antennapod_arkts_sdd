import { PlaybackController } from '../../playback/PlaybackController';
import { EpisodeDetailParam, FeedDetailParam, RouteName } from '../../common/AppRouter';
import { promptAction } from '@kit.ArkUI';
import { FeedItemDao } from '../../database/FeedItemDao';

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
  @State showSpeedDialog: boolean = false;
  private controller: PlaybackController = PlaybackController.getInstance();
  private validSpeeds: number[] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  aboutToAppear(): void {
    this.isFullPlayerVisible = true;
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
        promptAction.showToast({ message: msg, duration: 3000 });
      } else if (result.index === 1) {
        const mediaUrl = AppStorage.get<string>('currentMediaUrl');
        if (mediaUrl !== undefined && mediaUrl.length > 0) {
          promptAction.showToast({ message: mediaUrl, duration: 3000 });
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

  private showSpeedPicker(): void {
    this.showSpeedDialog = true;
  }

  private onVisitWebsite(): void {
    if (this.currentFeedLink.length > 0) {
      promptAction.showToast({ message: this.currentFeedLink, duration: 3000 });
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

          // Favorite star (Android ic_star_border)
          Image($r('app.media.ic_star_border'))
            .width(24)
            .height(24)
            .margin({ right: 8 })
            .onClick(() => {
              promptAction.showToast({ message: 'Added to favorites' });
            })

          // Sleep timer (Android ic_sleep — zzZ icon)
          Image($r('app.media.ic_sleep'))
            .width(24)
            .height(24)
            .margin({ right: 8 })
            .onClick(() => {
              promptAction.showToast({ message: 'Sleep timer' });
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

        // Shownotes pill button — outline style with info icon (matching Android)
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
        .margin({ bottom: 20 })
        .onClick(() => {
          if (this.currentEpisodeId > 0) {
            const param = new EpisodeDetailParam();
            param.episodeId = this.currentEpisodeId;
            this.navPathStack.pushPathByName(RouteName.EPISODE_DETAIL, param);
          }
        })

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
            this.showSpeedPicker();
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

      // Speed picker dialog overlay
      if (this.showSpeedDialog) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#40000000')
          .onClick(() => {
            this.showSpeedDialog = false;
          })

        Column() {
          Text('Playback speed')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 16 })
            .width('100%')

          // Speed buttons row
          Row() {
            ForEach(this.validSpeeds, (speed: number) => {
              Text(speed.toFixed(2) + 'x')
                .fontSize(14)
                .fontWeight(Math.abs(speed - this.playbackSpeed) < 0.01 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(Math.abs(speed - this.playbackSpeed) < 0.01 ? Color.White : '#333333')
                .backgroundColor(Math.abs(speed - this.playbackSpeed) < 0.01 ? '#1565C0' : '#F0F0F0')
                .borderRadius(16)
                .height(32)
                .padding({ left: 10, right: 10 })
                .textAlign(TextAlign.Center)
                .margin({ right: 6 })
                .onClick(() => {
                  this.controller.setSpeed(speed);
                })
            }, (speed: number) => speed.toString())
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 16 })

          // Skip silence toggle
          Row() {
            Text('Skip silence')
              .fontSize(16)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.skipSilence })
              .selectedColor('#1565C0')
              .onChange((isOn: boolean) => {
                this.skipSilence = isOn;
              })
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        }
        .width('90%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 8, color: '#33000000' })
      }
      }
    }
    .hideTitleBar(true)
  }
}
