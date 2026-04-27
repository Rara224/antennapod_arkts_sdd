import { VideoPlayerParam } from '../../common/AppRouter';
import { VideoPlayerViewModel } from '../../viewmodels/VideoPlayerViewModel';
import { PLAYER_STATUS_PLAYING, PLAYER_STATUS_PAUSED, PLAYER_STATUS_STOPPED } from '../../common/Constants';

@Component
export struct VideoPlayerComponent {
  @Consume('navPathStack') navPathStack: NavPathStack;
  private vm: VideoPlayerViewModel = new VideoPlayerViewModel();
  @State episodeId: number = 0;
  @State episodeTitle: string = '';
  @State isPlaying: boolean = false;
  @State playPos: number = 0;
  @State playDuration: number = 0;
  @State showControls: boolean = true;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  private hideControlsTimerId: number = -1;
  private playPosTimerId: number = -1;
  private xComponentController: XComponentController = new XComponentController();

  aboutToDisappear(): void {
    this.clearTimers();
    this.vm.release();
  }

  private clearTimers(): void {
    if (this.hideControlsTimerId !== -1) {
      clearTimeout(this.hideControlsTimerId);
      this.hideControlsTimerId = -1;
    }
    if (this.playPosTimerId !== -1) {
      clearInterval(this.playPosTimerId);
      this.playPosTimerId = -1;
    }
  }

  private scheduleHideControls(): void {
    if (this.hideControlsTimerId !== -1) {
      clearTimeout(this.hideControlsTimerId);
    }
    this.hideControlsTimerId = setTimeout(() => {
      if (this.isPlaying) {
        this.showControls = false;
      }
    }, 3000);
  }

  private toggleControls(): void {
    this.showControls = !this.showControls;
    if (this.showControls) {
      this.scheduleHideControls();
    }
  }

  private startPositionSync(): void {
    if (this.playPosTimerId !== -1) {
      return;
    }
    this.playPosTimerId = setInterval(() => {
      this.playPos = this.vm.position;
      this.playDuration = this.vm.duration;
      const playing = this.vm.status === PLAYER_STATUS_PLAYING;
      if (playing !== this.isPlaying) {
        this.isPlaying = playing;
      }
    }, 500);
  }

  private formatTime(ms: number): string {
    if (ms <= 0) {
      return '00:00';
    }
    const totalSec = Math.floor(ms / 1000);
    const hours = Math.floor(totalSec / 3600);
    const minutes = Math.floor((totalSec % 3600) / 60);
    const seconds = totalSec % 60;
    const pad = (n: number): string => n < 10 ? '0' + n.toString() : n.toString();
    if (hours > 0) {
      return pad(hours) + ':' + pad(minutes) + ':' + pad(seconds);
    }
    return pad(minutes) + ':' + pad(seconds);
  }

  private async initPlayer(): Promise<void> {
    this.isLoading = true;
    const loaded = await this.vm.loadEpisode(this.episodeId);
    if (!loaded) {
      this.errorMessage = 'Failed to load episode';
      this.isLoading = false;
      return;
    }
    if (this.vm.item !== null) {
      this.episodeTitle = this.vm.item.title;
    }
    this.playDuration = this.vm.duration;
    this.playPos = this.vm.position;
    this.isLoading = false;
  }

  build() {
    NavDestination() {
      Stack() {
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(48).height(48)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.Black)
        } else if (this.errorMessage.length > 0) {
          Column() {
            Text(this.errorMessage)
              .fontSize(16)
              .fontColor(Color.White)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.Black)
        } else {
          // Video surface
          XComponent({
            id: 'videoSurface',
            type: XComponentType.SURFACE,
            controller: this.xComponentController
          })
            .width('100%')
            .height('100%')
            .onLoad(() => {
              const surfaceId = this.xComponentController.getXComponentSurfaceId();
              this.vm.createPlayer(surfaceId).then(() => {
                this.startPositionSync();
                this.scheduleHideControls();
              });
            })
            .onClick(() => {
              this.toggleControls();
            })

          // Controls overlay
          if (this.showControls) {
            Column() {
              // Top bar: back button + title
              Row() {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(24)
                  .fontColor([Color.White])
                  .onClick(() => {
                    this.navPathStack.pop();
                  })
                  .margin({ right: 12 })

                Text(this.episodeTitle)
                  .fontSize(16)
                  .fontColor(Color.White)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16 })

              Blank()

              // Center play/pause
              Row() {
                SymbolGlyph(this.isPlaying ? $r('sys.symbol.pause_circle_fill') : $r('sys.symbol.play_circle_fill'))
                  .fontSize(64)
                  .fontColor([Color.White])
                  .onClick(() => {
                    this.vm.playPause();
                    this.scheduleHideControls();
                  })
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')

              Blank()

              // Bottom bar: time + progress
              Column() {
                Slider({
                  value: this.playDuration > 0 ? this.playPos : 0,
                  min: 0,
                  max: this.playDuration > 0 ? this.playDuration : 100,
                  step: 1000
                })
                  .width('100%')
                  .trackColor('#66FFFFFF')
                  .selectedColor('#FF8C00')
                  .onChange((value: number, mode: SliderChangeMode) => {
                    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                      this.vm.seekTo(value);
                      this.scheduleHideControls();
                    }
                  })

                Row() {
                  Text(this.formatTime(this.playPos))
                    .fontSize(12)
                    .fontColor(Color.White)
                  Blank()
                  Text(this.formatTime(this.playDuration))
                    .fontSize(12)
                    .fontColor(Color.White)
                }
                .width('100%')
                .padding({ left: 16, right: 16 })
              }
              .padding({ bottom: 24 })
              .width('100%')
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#66000000')
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
    }
    .title('')
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      if (ctx.pathInfo.param instanceof VideoPlayerParam) {
        const p: VideoPlayerParam = ctx.pathInfo.param;
        this.episodeId = p.episodeId;
        this.initPlayer();
      }
    })
  }
}
